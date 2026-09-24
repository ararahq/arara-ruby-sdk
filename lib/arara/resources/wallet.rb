require_relative "base_resource"
require_relative "../page"

module Arara
  module Resources
    class Wallet < BaseResource
      DEFAULT_PAGE_SIZE = 20

      # List wallet transactions. GET /v1/wallet/transactions. Returns an Arara::Page.
      def transactions(page: 0, size: DEFAULT_PAGE_SIZE)
        response = @http.get("/v1/wallet/transactions", params: { "page" => page, "size" => size })
        Arara::Page.from_content(response, page: page, size: size)
      end

      # Get auto-recharge settings. GET /v1/wallet/auto-recharge
      def get_auto_recharge
        @http.get("/v1/wallet/auto-recharge")
      end

      # Update auto-recharge settings. PATCH /v1/wallet/auto-recharge
      def update_auto_recharge(enabled: nil, threshold: nil, amount: nil)
        payload = {
          "enabled" => enabled,
          "threshold" => threshold,
          "amount" => amount
        }.reject { |_, value| value.nil? }
        @http.patch("/v1/wallet/auto-recharge", body: payload)
      end
    end
  end
end
