require_relative "base_resource"

module Arara
  module Resources
    class SmartLinks < BaseResource
      BASE_PATH = "/v1/smart-links/whatsapp".freeze

      # Create a WhatsApp smart link. POST /v1/smart-links/whatsapp
      def create(name:, phone_number:, default_text: nil, qr_code_color: nil)
        payload = {
          "name" => name,
          "phoneNumber" => phone_number,
          "defaultText" => default_text,
          "qrCodeColor" => qr_code_color
        }.reject { |_, value| value.nil? }
        @http.post(BASE_PATH, body: payload)
      end

      # Update a WhatsApp smart link. PUT /v1/smart-links/whatsapp/{id}
      def update(id, name: nil, default_text: nil, qr_code_color: nil)
        payload = {
          "name" => name,
          "defaultText" => default_text,
          "qrCodeColor" => qr_code_color
        }.reject { |_, value| value.nil? }
        @http.put("#{BASE_PATH}/#{id}", body: payload)
      end

      # List WhatsApp smart links. GET /v1/smart-links/whatsapp
      def list
        @http.get(BASE_PATH)
      end

      # Get smart link click stats. GET /v1/smart-links/whatsapp/{id}/stats
      def stats(id)
        @http.get("#{BASE_PATH}/#{id}/stats")
      end
    end
  end
end
