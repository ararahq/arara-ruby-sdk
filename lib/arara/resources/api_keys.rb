require_relative "base_resource"

module Arara
  module Resources
    class ApiKeys < BaseResource
      # List all API keys. GET /v1/api-keys
      def list
        @http.get("/v1/api-keys")
      end

      # Create a new API key. POST /v1/api-keys
      def create(mode: "LIVE")
        @http.post("/v1/api-keys", params: { "mode" => mode })
      end
    end
  end
end
