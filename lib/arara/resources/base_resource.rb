require "securerandom"

module Arara
  module Resources
    class BaseResource
      def initialize(http)
        @http = http
      end

      private

      def idempotency_key_or_generate(key)
        normalized = key.to_s.strip
        normalized.empty? ? SecureRandom.uuid : normalized
      end
    end
  end
end
