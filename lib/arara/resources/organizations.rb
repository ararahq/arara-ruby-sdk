require_relative "base_resource"

module Arara
  module Resources
    class Organizations < BaseResource
      # Get organization webhook configuration. GET /organizations/me/webhook
      def get_webhook
        @http.get("/organizations/me/webhook")
      end

      # Update organization webhook configuration. PATCH /organizations/me/webhook
      def update_webhook(url: nil, secret: nil)
        payload = {
          "url" => url,
          "secret" => secret
        }.reject { |_, value| value.nil? }
        @http.patch("/organizations/me/webhook", body: payload)
      end
    end
  end
end
