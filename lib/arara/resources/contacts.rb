require_relative "base_resource"

module Arara
  module Resources
    class Contacts < BaseResource
      # List contacts. GET /v1/contacts
      def list(page: 0, size: 20, q: nil, lifecycle: nil)
        @http.get("/v1/contacts", params: { "page" => page, "size" => size, "q" => q, "lifecycle" => lifecycle })
      end

      # Import a batch of contacts. POST /v1/contacts/batch
      def import_batch(contacts)
        @http.post("/v1/contacts/batch", body: contacts)
      end

      # Get contact lifecycle stats. GET /v1/contacts/stats
      def stats
        @http.get("/v1/contacts/stats")
      end

      # List reactivation candidates. GET /v1/contacts/reactivation
      def reactivation_candidates(limit: 100)
        @http.get("/v1/contacts/reactivation", params: { "limit" => limit })
      end

      # List distinct contact tags. GET /v1/contacts/tags
      def list_tags
        @http.get("/v1/contacts/tags")
      end

      # Get a contact by phone. GET /v1/contacts/{phone}
      def get(phone)
        @http.get("/v1/contacts/#{phone}")
      end

      # Update a contact by phone. PATCH /v1/contacts/{phone}
      def update(phone, name: nil, email: nil, tags: nil)
        payload = {
          "name" => name,
          "email" => email,
          "tags" => tags
        }.reject { |_, value| value.nil? }
        @http.patch("/v1/contacts/#{phone}", body: payload)
      end

      # List a contact's recent messages. GET /v1/contacts/{phone}/messages
      def messages(phone, limit: 30)
        @http.get("/v1/contacts/#{phone}/messages", params: { "limit" => limit })
      end
    end
  end
end
