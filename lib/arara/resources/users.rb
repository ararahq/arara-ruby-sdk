require_relative "base_resource"

module Arara
  module Resources
    class Users < BaseResource
      # Get the authenticated user. GET /users/me
      def get_me
        @http.get("/users/me")
      end

      # Update the authenticated user. PATCH /users/me
      def update(name: nil, phone_number: nil)
        payload = {
          "name" => name,
          "phoneNumber" => phone_number
        }.reject { |_, value| value.nil? }
        @http.patch("/users/me", body: payload)
      end
    end
  end
end
