require "securerandom"
require_relative "base_resource"

module Arara
  module Resources
    class Messages < BaseResource
      BASE_PATH = "/v1/messages".freeze
      MAX_BATCH_SIZE = 1000

      PAYLOAD_FIELDS = {
        receiver: "receiver",
        sender: "sender",
        type: "type",
        template_name: "templateName",
        template_variables: "templateVariables",
        body: "body",
        interactive: "interactive",
        charge: "charge",
        location: "location",
        reaction: "reaction",
        reply_to: "replyTo",
        smart_link_param: "smartLinkParam",
        smart_link_url: "smartLinkUrl",
        scheduled_at: "scheduled_at",
        mode: "mode",
        media_url: "media_url"
      }.freeze

      # Send a WhatsApp message. POST /v1/messages
      # An Idempotency-Key is generated when omitted and reused on every retry.
      def send_message(receiver:, idempotency_key: nil, **fields)
        unknown = fields.keys - PAYLOAD_FIELDS.keys
        raise ArgumentError, "unknown message fields: #{unknown.join(', ')}" unless unknown.empty?

        payload = build_payload(fields.merge(receiver: receiver))
        @http.post(BASE_PATH, body: payload, idempotency_key: idempotency_key || SecureRandom.uuid)
      end

      alias deliver send_message

      # Send the same template to up to 1000 receivers. POST /v1/messages/batch
      def send_batch(template_name:, messages:, idempotency_key: nil)
        raise ArgumentError, "messages must not be empty" if messages.nil? || messages.empty?
        raise ArgumentError, "messages must have at most #{MAX_BATCH_SIZE} items" if messages.size > MAX_BATCH_SIZE

        payload = { "templateName" => template_name, "messages" => messages }
        @http.post("#{BASE_PATH}/batch", body: payload, idempotency_key: idempotency_key || SecureRandom.uuid)
      end

      # Get a message by id. GET /v1/messages/{id}
      def get(id)
        @http.get("#{BASE_PATH}/#{id}")
      end

      # List the messages of a batch. GET /v1/messages?batchId=
      def list_by_batch(batch_id)
        @http.get(BASE_PATH, params: { "batchId" => batch_id })
      end

      private

      def build_payload(fields)
        fields.each_with_object({}) do |(key, value), payload|
          payload[PAYLOAD_FIELDS.fetch(key)] = value unless value.nil?
        end
      end
    end
  end
end
