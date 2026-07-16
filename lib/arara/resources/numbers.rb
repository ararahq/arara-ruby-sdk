require_relative "base_resource"

module Arara
  module Resources
    class Numbers < BaseResource
      BASE_PATH = "/v1/organizations/me/numbers".freeze

      # List numbers with plan slot info. GET /v1/organizations/me/numbers
      def list
        @http.get(BASE_PATH)
      end

      # Update a number. PATCH /v1/organizations/me/numbers/{id}
      def update(id, alias_name: nil, is_default: nil, name: nil, description: nil)
        payload = {
          "alias" => alias_name,
          "isDefault" => is_default,
          "name" => name,
          "description" => description
        }.reject { |_, value| value.nil? }
        @http.patch("#{BASE_PATH}/#{id}", body: payload)
      end

      # Deactivate a number. DELETE /v1/organizations/me/numbers/{id}
      def delete(id)
        @http.delete("#{BASE_PATH}/#{id}")
      end

      # Request a new dedicated number. POST /v1/organizations/me/numbers/request
      def request(reason: nil, expected_volume: nil, area_code: nil, display_name: nil, profile_picture_url: nil)
        payload = {
          "reason" => reason,
          "expectedVolume" => expected_volume,
          "areaCode" => area_code,
          "displayName" => display_name,
          "profilePictureUrl" => profile_picture_url
        }.reject { |_, value| value.nil? }
        @http.post("#{BASE_PATH}/request", body: payload)
      end

      # List number provisioning requests. GET /v1/organizations/me/numbers/requests
      def list_requests
        @http.get("#{BASE_PATH}/requests")
      end

      # Sync a number's health from the provider. POST /v1/organizations/me/numbers/{id}/sync
      def sync(id)
        @http.post("#{BASE_PATH}/#{id}/sync")
      end

      # Get warming recommendations for a number. GET /v1/organizations/me/numbers/{id}/warming
      def warming(id)
        @http.get("#{BASE_PATH}/#{id}/warming")
      end
    end
  end
end
