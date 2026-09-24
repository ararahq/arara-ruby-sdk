require_relative "base_resource"
require_relative "../page"

module Arara
  module Resources
    class Templates < BaseResource
      BASE_PATH = "/v1/templates".freeze
      DEFAULT_PAGE_SIZE = 50
      DEFAULT_PERIOD = "30d".freeze

      # List templates. GET /v1/templates. Returns an Arara::Page.
      def list(name: nil, status: nil, page: 0, size: DEFAULT_PAGE_SIZE)
        response = @http.get(BASE_PATH, params: { "name" => name, "status" => status, "page" => page, "size" => size })
        Arara::Page.from_data(response)
      end

      # Find a template by exact name, filtering the list locally. Returns nil when absent.
      def find_by_name(name)
        list(name: name).find { |template| template["name"] == name }
      end

      # Create a template for Meta approval. POST /v1/templates
      def create(payload)
        @http.post(BASE_PATH, body: payload)
      end

      # Get a template by id (UUID). GET /v1/templates/{id}
      def get(id)
        @http.get("#{BASE_PATH}/#{id}")
      end

      # Get template status from provider. GET /v1/templates/{id}/status
      def get_status(id)
        @http.get("#{BASE_PATH}/#{id}/status")
      end

      # Delete a template by id (UUID). DELETE /v1/templates/{id}
      def delete(id)
        @http.delete("#{BASE_PATH}/#{id}")
      end

      # Analytics of all templates. GET /v1/templates/analytics
      def analytics(period: DEFAULT_PERIOD)
        @http.get("#{BASE_PATH}/analytics", params: { "period" => period })
      end

      # Analytics of one template. GET /v1/templates/{id}/analytics
      def template_analytics(id, period: DEFAULT_PERIOD)
        @http.get("#{BASE_PATH}/#{id}/analytics", params: { "period" => period })
      end
    end
  end
end
