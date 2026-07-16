require_relative "base_resource"

module Arara
  module Resources
    class Messages < BaseResource
      # Send a WhatsApp template message. POST /v1/messages
      def send(receiver:, template_name: nil, template_variables: nil, body: nil,
               media_url: nil, scheduled_at: nil, idempotency_key: nil)
        payload = {
          "receiver" => receiver,
          "templateName" => template_name,
          "templateVariables" => template_variables,
          "body" => body,
          "media_url" => media_url,
          "scheduled_at" => scheduled_at
        }.reject { |_, value| value.nil? }
        @http.post("/v1/messages", body: payload, idempotency_key: idempotency_key)
      end
    end
  end
end
