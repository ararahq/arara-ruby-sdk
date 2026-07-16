require_relative "http_client"
require_relative "resources/messages"
require_relative "resources/templates"
require_relative "resources/users"
require_relative "resources/organizations"
require_relative "resources/api_keys"
require_relative "resources/contacts"
require_relative "resources/conversations"
require_relative "resources/wallet"
require_relative "resources/numbers"
require_relative "resources/smart_links"
require_relative "resources/campaigns"

module Arara
  class Client
    DEFAULT_BASE_URL = "https://api.ararahq.com".freeze

    attr_reader :messages, :templates, :users, :organizations, :api_keys, :contacts,
                :conversations, :wallet, :numbers, :smart_links, :campaigns

    def initialize(api_key:, base_url: DEFAULT_BASE_URL, timeout: 10, max_retries: 3)
      raise ArgumentError, "api_key is required" if api_key.nil? || api_key.to_s.strip.empty?

      http = HttpClient.new(api_key: api_key, base_url: base_url, timeout: timeout, max_retries: max_retries)
      @messages = Resources::Messages.new(http)
      @templates = Resources::Templates.new(http)
      @users = Resources::Users.new(http)
      @organizations = Resources::Organizations.new(http)
      @api_keys = Resources::ApiKeys.new(http)
      @contacts = Resources::Contacts.new(http)
      @conversations = Resources::Conversations.new(http)
      @wallet = Resources::Wallet.new(http)
      @numbers = Resources::Numbers.new(http)
      @smart_links = Resources::SmartLinks.new(http)
      @campaigns = Resources::Campaigns.new(http)
    end
  end
end
