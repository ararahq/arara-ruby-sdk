require_relative "base_resource"

module Arara
  module Resources
    class Templates < BaseResource
      # List all templates. GET /v1/templates
      def list
        @http.get("/v1/templates")
      end

      # Create a template for Meta approval. POST /v1/templates
      def create(payload)
        @http.post("/v1/templates", body: payload)
      end

      # Get a template by name. GET /v1/templates/{name}
      def get(name)
        @http.get("/v1/templates/#{name}")
      end

      # Get template status from provider. GET /v1/templates/{name}/status
      def get_status(name)
        @http.get("/v1/templates/#{name}/status")
      end

      # Delete a template by name. DELETE /v1/templates/{name}
      def delete(name)
        @http.delete("/v1/templates/#{name}")
      end
    end
  end
end
