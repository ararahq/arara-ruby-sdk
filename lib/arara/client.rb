require_relative "http_client"
require_relative "resources/auth"
require_relative "resources/messages"
require_relative "resources/templates"
require_relative "resources/contacts"
require_relative "resources/conversations"
require_relative "resources/wallet"
require_relative "resources/numbers"
require_relative "resources/smart_links"
require_relative "resources/campaigns"
require_relative "resources/opt_outs"

module Arara
  class Client
    DEFAULT_BASE_URL = "https://api.ararahq.com".freeze
    DEFAULT_TIMEOUT = 10

    attr_reader :auth, :messages, :templates, :contacts, :conversations, :wallet,
                :numbers, :smart_links, :campaigns, :opt_outs

    def initialize(api_key:, base_url: DEFAULT_BASE_URL, timeout: DEFAULT_TIMEOUT,
                   max_retries: HttpClient::DEFAULT_MAX_RETRIES)
      raise ArgumentError, "api_key is required" if api_key.nil? || api_key.to_s.strip.empty?

      http = HttpClient.new(api_key: api_key, base_url: base_url, timeout: timeout, max_retries: max_retries)
      @auth = Resources::Auth.new(http)
      @messages = Resources::Messages.new(http)
      @templates = Resources::Templates.new(http)
      @contacts = Resources::Contacts.new(http)
      @conversations = Resources::Conversations.new(http)
      @wallet = Resources::Wallet.new(http)
      @numbers = Resources::Numbers.new(http)
      @smart_links = Resources::SmartLinks.new(http)
      @campaigns = Resources::Campaigns.new(http)
      @opt_outs = Resources::OptOuts.new(http)
    end
  end
end
