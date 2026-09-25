# AraraHQ Ruby SDK

Official Ruby client for the [AraraHQ](https://ararahq.com) WhatsApp API. Zero runtime dependencies: pure Ruby stdlib (`net/http`, `json`, `uri`, `time`, `securerandom`). Ruby >= 3.0.

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

# Send a template message. `deliver` is an alias of `send_message`.
result = client.messages.send_message(
  receiver: "5511999998888",          # also accepts "+55..." and "whatsapp:+55..."
  sender: "+5511888887777",           # optional: which of your numbers sends it
  template_name: "boas_vindas",
  template_variables: ["Micael"],
  idempotency_key: "order-1234"       # optional: generated when omitted
)
puts result["id"]

client.messages.get(result["id"])

# Up to 1000 receivers of the same template
client.messages.send_batch(
  template_name: "boas_vindas",
  messages: [{ "receiver" => "5511999998888", "variables" => ["Ana"] }]
)

# Paginated lists return Arara::Page (Enumerable over `data`)
page = client.templates.list(status: "APPROVED", page: 0, size: 50)
page.each { |template| puts template["id"] }
page.pagination.total_pages
page.next_page?

# Templates are addressed by id (UUID)
client.templates.get_status(page.data.first["id"])
client.templates.find_by_name("boas_vindas") # local filter over list

# Campaigns (idempotency key is auto-generated when omitted)
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

`GET`, `PUT` and `DELETE`, and any request carrying an `Idempotency-Key`, are retried on `429`, `5xx` and network errors with exponential backoff, honoring `Retry-After`. A `POST`/`PATCH` without `Idempotency-Key` is never retried. `messages.send_message`, `messages.send_batch` and `campaigns.create` always send one (a UUID v4 when you do not pass yours), reused across retries, so a retry never duplicates a send.

## Resources

`auth`, `messages`, `templates`, `contacts`, `conversations`, `wallet`, `numbers`, `smart_links`, `campaigns`, `opt_outs`.

## API key permissions

`READ` keys can `GET` messages, campaigns, templates and numbers. Sending needs `MESSAGES_SEND` (messages) or `CAMPAIGNS_SEND` (campaigns); creating templates needs `TEMPLATES_WRITE`; `contacts` writes need `CONTACTS_WRITE`.

These require an `ADMIN` key: `auth.me`, `contacts` (reads), `conversations`, `wallet` and `opt_outs`. Permissions are enforced by the API.

## Errors

Every failed request raises an `Arara::Error` (or a subclass) with `status_code`, `code`, `message`, `details` and `retry_after`.

| Status | Class |
|---|---|
| 400 | `Arara::BadRequestError` |
| 401, 403 without `code` (invalid key or missing permission) | `Arara::AuthenticationError` |
| 402 | `Arara::PaymentRequiredError` |
| 403 `PLAN_FEATURE_LOCKED` | `Arara::PlanFeatureLockedError` (`feature`, `current_plan`, `upgrade_to`) |
| 403 with another `code` | `Arara::PermissionError` |
| 404 | `Arara::NotFoundError` |
| 409 | `Arara::ConflictError` |
| 422 | `Arara::UnprocessableEntityError` (e.g. `INVALID_RECIPIENT`, `TEMPLATE_PAUSED`) |
| 429 | `Arara::RateLimitError` |
| 5xx | `Arara::ServerError` |
| network | `Arara::NetworkError` |

```ruby
begin
  client.messages.send_message(receiver: "5511999998888", template_name: "x")
rescue Arara::PlanFeatureLockedError => e
  puts "upgrade to #{e.upgrade_to}"
rescue Arara::RateLimitError => e
  puts "retry after #{e.retry_after}s"
rescue Arara::Error => e
  puts "#{e.code}: #{e.message}"
end
```

## Development

```bash
bundle install
bundle exec rake test
```

## License

MIT. See [LICENSE](LICENSE).
