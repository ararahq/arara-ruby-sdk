require "net/http"
require "uri"
require "json"
require "time"
require_relative "errors"

module Arara
  class HttpClient
    DEFAULT_MAX_RETRIES = 3
    BASE_RETRY_DELAY = 0.5
    MAX_RETRY_DELAY = 30.0
    RATE_LIMIT_STATUS = 429
    SERVER_ERROR_THRESHOLD = 500
    IDEMPOTENT_METHODS = %i[get put delete].freeze

    def initialize(api_key:, base_url:, timeout: 10, max_retries: DEFAULT_MAX_RETRIES)
      @api_key = api_key
      @base_uri = URI.parse(base_url.to_s.sub(%r{/+\z}, ""))
      @timeout = timeout
      @max_retries = max_retries
    end

    def get(path, params: nil)
      request(:get, path, params: params)
    end

    def post(path, body: nil, params: nil, idempotency_key: nil)
      request(:post, path, body: body, params: params, idempotency_key: idempotency_key)
    end

    def patch(path, body: nil, params: nil)
      request(:patch, path, body: body, params: params)
    end

    def put(path, body: nil, params: nil)
      request(:put, path, body: body, params: params)
    end

    def delete(path, params: nil)
      request(:delete, path, params: params)
    end

    private

    def request(method, path, body: nil, params: nil, idempotency_key: nil)
      idempotency_key = normalize_idempotency_key(idempotency_key)
      attempt = 0
      loop do
        response = perform(method, path, body, params, idempotency_key)
        status = response.code.to_i
        return handle_success(response) if status < 400

        if retry_allowed?(method, idempotency_key) && retryable?(status) && attempt < @max_retries
          sleep(retry_delay(attempt, response))
          attempt += 1
          next
        end
        raise error_from_response(status, response)
      rescue Timeout::Error, IOError, SystemCallError, Net::OpenTimeout, Net::ReadTimeout => e
        raise NetworkError.new(e.message) if attempt >= @max_retries || !retry_allowed?(method, idempotency_key)

        sleep(retry_delay(attempt, nil))
        attempt += 1
      end
    end

    def perform(method, path, body, params, idempotency_key)
      uri = build_uri(path, params)
      request = build_request(method, uri, body, idempotency_key)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = @timeout
      http.read_timeout = @timeout
      http.request(request)
    end

    def build_uri(path, params)
      uri = @base_uri.dup
      uri.path = "#{@base_uri.path}#{path}"
      unless params.nil? || params.empty?
        cleaned = params.reject { |_, value| value.nil? }
        uri.query = URI.encode_www_form(cleaned) unless cleaned.empty?
      end
      uri
    end

    def build_request(method, uri, body, idempotency_key)
      klass = {
        get: Net::HTTP::Get,
        post: Net::HTTP::Post,
        patch: Net::HTTP::Patch,
        put: Net::HTTP::Put,
        delete: Net::HTTP::Delete
      }.fetch(method)
      request = klass.new(uri)
      request["Authorization"] = "Bearer #{@api_key}"
      request["Accept"] = "application/json"
      request["Idempotency-Key"] = idempotency_key if idempotency_key
      unless body.nil?
        request["Content-Type"] = "application/json"
        request.body = JSON.generate(body)
      end
      request
    end

    def handle_success(response)
      return nil if response.code.to_i == 204

      raw = response.body
      return nil if raw.nil? || raw.strip.empty?

      JSON.parse(raw)
    rescue JSON::ParserError
      raise Error.new("Failed to parse Arara API response as JSON")
    end

    def normalize_idempotency_key(key)
      normalized = key.to_s.strip
      normalized.empty? ? nil : normalized
    end

    def retry_allowed?(method, idempotency_key)
      IDEMPOTENT_METHODS.include?(method) || !idempotency_key.nil?
    end

    def retryable?(status)
      status == RATE_LIMIT_STATUS || status >= SERVER_ERROR_THRESHOLD
    end

    def retry_delay(attempt, response)
      after = response && parse_retry_after(response["Retry-After"])
      return [after, MAX_RETRY_DELAY].min if after

      [BASE_RETRY_DELAY * (2**attempt), MAX_RETRY_DELAY].min
    end

    def parse_retry_after(header)
      return nil if header.nil? || header.strip.empty?

      seconds = Float(header, exception: false)
      return seconds if seconds && seconds >= 0

      begin
        [(Time.httpdate(header) - Time.now).ceil, 0].max
      rescue ArgumentError, TypeError
        nil
      end
    end

    def error_from_response(status, response)
      envelope = parse_error_envelope(response.body)
      message = envelope[:message] || "Arara API request failed with status #{status}"
      Arara.error_for_status(
        status,
        message,
        code: envelope[:code],
        details: envelope[:details],
        retry_after: parse_retry_after(response["Retry-After"])
      )
    end

    def parse_error_envelope(raw)
      return {} if raw.nil? || raw.strip.empty?

      parsed = JSON.parse(raw)
      return {} unless parsed.is_a?(Hash)

      inner = parsed["error"]
      return spring_error(parsed) if inner.is_a?(String)
      return {} unless inner.is_a?(Hash)

      {
        code: inner["code"],
        message: inner["message"],
        details: inner["details"].is_a?(Hash) ? inner["details"] : nil
      }
    rescue JSON::ParserError
      {}
    end

    def spring_error(parsed)
      message = parsed["message"]
      { message: message.is_a?(String) && !message.strip.empty? ? message : nil }
    end
  end
end
