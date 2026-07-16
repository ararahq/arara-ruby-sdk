require "securerandom"
require_relative "base_resource"

module Arara
  module Resources
    class Campaigns < BaseResource
      # Create a campaign. POST /v1/campaigns
      def create(payload, idempotency_key: nil)
        key = idempotency_key || SecureRandom.uuid
        @http.post("/v1/campaigns", body: payload, idempotency_key: key)
      end

      # List campaigns. GET /v1/campaigns
      def list(page: 0, size: 20, status: nil)
        @http.get("/v1/campaigns", params: { "page" => page, "size" => size, "status" => status })
      end

      # Estimate campaign cost. GET /v1/campaigns/estimate
      def estimate(template_name:, count:)
        @http.get("/v1/campaigns/estimate", params: { "templateName" => template_name, "count" => count })
      end

      # Get a campaign by id. GET /v1/campaigns/{id}
      def get(id)
        @http.get("/v1/campaigns/#{id}")
      end

      # Cancel a campaign. POST /v1/campaigns/{id}/cancel
      def cancel(id)
        @http.post("/v1/campaigns/#{id}/cancel")
      end
    end
  end
end
