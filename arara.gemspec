require_relative "lib/arara/version"

Gem::Specification.new do |spec|
  spec.name = "ararahq"
  spec.version = Arara::VERSION
  spec.authors = ["AraraHQ"]
  spec.email = ["dev@ararahq.com"]

  spec.summary = "Ruby SDK for the AraraHQ API."
  spec.description = "Ruby client for the AraraHQ API: messages, templates, contacts, " \
                     "conversations, campaigns, wallet, numbers, smart links and opt-outs. Zero runtime dependencies. " \
                     "AraraHQ: WhatsApp for Brazilian companies. Team inbox with AI, campaigns and systems connected through the API."
  spec.homepage = "https://ararahq.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ararahq/arara-ruby-sdk"
  spec.metadata["changelog_uri"] = "https://github.com/ararahq/arara-ruby-sdk/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb"] + ["README.md", "CHANGELOG.md", "LICENSE", "arara.gemspec"]
  spec.require_paths = ["lib"]
end
