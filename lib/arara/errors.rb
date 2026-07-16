module Arara
  class Error < StandardError
    attr_reader :status_code, :code, :details, :retry_after

    def initialize(message, code: nil, status_code: nil, details: nil, retry_after: nil)
      super(message)
      @code = code
      @status_code = status_code
      @details = details
      @retry_after = retry_after
    end
  end

  class BadRequestError < Error; end

  class AuthenticationError < Error; end

  class PermissionError < Error; end

  class NotFoundError < Error; end

  class ConflictError < Error; end

  class RateLimitError < Error; end

  class ServerError < Error; end

  class NetworkError < Error; end

  module_function

  def error_for_status(status_code, message, code: nil, details: nil, retry_after: nil)
    klass = case status_code
            when 400 then BadRequestError
            when 401 then AuthenticationError
            when 403 then PermissionError
            when 404 then NotFoundError
            when 409 then ConflictError
            when 429 then RateLimitError
            else
              status_code && status_code >= 500 ? ServerError : Error
            end
    klass.new(message, code: code, status_code: status_code, details: details, retry_after: retry_after)
  end
end
