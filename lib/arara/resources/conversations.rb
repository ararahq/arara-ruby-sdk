require_relative "base_resource"

module Arara
  module Resources
    class Conversations < BaseResource
      # List conversations. GET /v1/conversations
      def list(status: nil, lead_status: nil, page: 0, size: 20)
        @http.get("/v1/conversations", params: {
          "status" => status, "leadStatus" => lead_status, "page" => page, "size" => size
        })
      end

      # Get lead status stats. GET /v1/conversations/lead-stats
      def lead_stats
        @http.get("/v1/conversations/lead-stats")
      end

      # List messages in a conversation. GET /v1/conversations/{conversationId}/messages
      def messages(conversation_id, page: 0, size: 50)
        @http.get("/v1/conversations/#{conversation_id}/messages", params: { "page" => page, "size" => size })
      end

      # Reply within an open conversation window. POST /v1/conversations/reply
      def reply(conversation_id:, body:)
        @http.post("/v1/conversations/reply", body: { "conversationId" => conversation_id, "body" => body })
      end

      # Update a conversation status. PATCH /v1/conversations/{conversationId}/status
      def update_status(conversation_id, status)
        @http.patch("/v1/conversations/#{conversation_id}/status", body: { "status" => status })
      end

      # Check the 24h window status for phones. POST /v1/conversations/window-status
      def window_status(phones)
        @http.post("/v1/conversations/window-status", body: { "phones" => phones })
      end
    end
  end
end
