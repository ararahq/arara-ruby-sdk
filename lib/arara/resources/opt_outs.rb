require "uri"
require_relative "base_resource"

module Arara
  module Resources
    class OptOuts < BaseResource
      BASE_PATH = "/v1/opt-outs".freeze

      # List opt-outs. GET /v1/opt-outs (requires an ADMIN key)
      def list
        @http.get(BASE_PATH)
      end

      # Opt a phone out. POST /v1/opt-outs (requires an ADMIN key)
      def create(phone:, reason: nil)
        payload = { "phone" => phone, "reason" => reason }.reject { |_, value| value.nil? }
        @http.post(BASE_PATH, body: payload)
      end

      # Get the opt-out of a phone. GET /v1/opt-outs/{phone}
      def get(phone)
        @http.get("#{BASE_PATH}/#{URI.encode_www_form_component(phone)}")
      end

      # Remove the opt-out of a phone. DELETE /v1/opt-outs/{phone}
      def delete(phone)
        @http.delete("#{BASE_PATH}/#{URI.encode_www_form_component(phone)}")
      end
    end
  end
end
