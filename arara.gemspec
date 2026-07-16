require_relative "lib/arara/version"

Gem::Specification.new do |spec|
  spec.name = "ararahq"
  spec.version = Arara::VERSION
  spec.authors = ["AraraHQ"]
  spec.email = ["dev@ararahq.com"]

  spec.summary = "Official Ruby SDK for the AraraHQ WhatsApp API."
  spec.description = "Ruby client for the AraraHQ API: messages, templates, contacts, " \
                     "conversations, campaigns, wallet, numbers and smart links. Zero runtime dependencies."
  spec.homepage = "https://ararahq.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ararahq/arara-ruby-sdk"

  spec.files = Dir["lib/**/*.rb"] + ["README.md", "arara.gemspec"]
  spec.require_paths = ["lib"]
end
