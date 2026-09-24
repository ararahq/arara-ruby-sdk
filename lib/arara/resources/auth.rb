require_relative "base_resource"

module Arara
  module Resources
    class Auth < BaseResource
      # Get the user that owns the API key. GET /auth/me (requires an ADMIN key)
      def me
        @http.get("/auth/me")
      end
    end
  end
end
