# AraraHQ Ruby SDK

Official Ruby client for the [AraraHQ](https://ararahq.com) WhatsApp API. Zero runtime dependencies — pure Ruby stdlib (`net/http`, `json`, `uri`).

## Install

```ruby
gem "ararahq"
```

```bash
gem install ararahq
```

## Usage

```ruby
require "arara"

client = Arara::Client.new(api_key: "ara_live_...")

# Send a template message
result = client.messages.send(
  receiver: "5511999998888",
  template_name: "boas_vindas",
  template_variables: ["Micael"],
  idempotency_key: "order-1234"
)
puts result["id"]

# List contacts
client.contacts.list(page: 0, size: 20, lifecycle: "ENGAGED")

# Create a campaign (idempotency key is auto-generated when omitted)
client.campaigns.create(
  {
    "name" => "Reativação Julho",
    "templateName" => "reativacao",
    "contacts" => [{ "to" => "5511999998888", "variables" => ["Micael"] }]
  }
)
```

Responses are parsed from JSON into plain Ruby `Hash` objects with string keys, exactly as the API returns them.

## Configuration

```ruby
Arara::Client.new(
  api_key: "ara_live_...",
  base_url: "https://api.ararahq.com", # default
  timeout: 10,                          # seconds, default
  max_retries: 3                        # default
)
```

Requests to `429` and `5xx` are retried with exponential backoff, honoring the `Retry-After` header.

## Resources

`messages`, `templates`, `users`, `organizations`, `api_keys`, `contacts`, `conversations`, `wallet`, `numbers`, `smart_links`, `campaigns`.

## API key scopes

`READ` keys perform `GET` only. `SEND` keys add `POST` on `/messages` and `/campaigns`. Everything else requires an `ADMIN` key. Scope is enforced at runtime by the API.

## Errors

Every failed request raises an `Arara::Error` (or a subclass): `Arara::AuthenticationError` (401/403), `Arara::RateLimitError` (429), `Arara::NotFoundError` (404), `Arara::BadRequestError` (400), `Arara::ConflictError` (409), `Arara::ServerError` (5xx), `Arara::NetworkError`.

```ruby
begin
  client.messages.send(receiver: "5511999998888", template_name: "x")
rescue Arara::RateLimitError => e
  puts "retry after #{e.retry_after}s"
rescue Arara::Error => e
  puts "#{e.code}: #{e.message}"
end
```
