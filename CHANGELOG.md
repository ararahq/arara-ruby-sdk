# Changelog

## 1.0.0 - 2026-09-24

Primeira versão publicada no RubyGems. Alinha o SDK ao contrato da API por chave.

### Breaking
- `messages.send` foi removido (sobrescrevia `Object#send`). Use `messages.send_message` ou `messages.deliver`.
- `templates.get`, `get_status` e `delete` recebem o `id` (UUID) do template, não o nome. Para buscar por nome, `templates.find_by_name` (filtro local sobre `list`).
- `templates.list`, `smart_links.list`, `campaigns.list` e `wallet.transactions` devolvem `Arara::Page` (`data` + `pagination`).
- Removidos `users`, `organizations` (webhook) e `api_keys`: não são alcançáveis por chave. Use `auth.me` (`GET /auth/me`).
- 403 sem `code` agora levanta `Arara::AuthenticationError`.

### Added
- `Idempotency-Key` automático (UUID v4) em `messages.send_message`, `messages.send_batch` e `campaigns.create`, reaproveitado em todas as retentativas.
- `sender`, `type`, `interactive`, `charge`, `location`, `reaction`, `reply_to`, `smart_link_param`, `smart_link_url` e `mode` no envio.
- `messages.get`, `messages.send_batch` (até 1000), `messages.list_by_batch`.
- `templates.analytics`, `templates.template_analytics`, filtros e paginação em `templates.list`; paginação em `smart_links.list`.
- `opt_outs` (`list`, `create`, `get`, `delete`).
- Erros `PlanFeatureLockedError` (`feature`, `current_plan`, `upgrade_to`), `PaymentRequiredError` (402) e `UnprocessableEntityError` (422).
- LICENSE MIT e suíte de testes (minitest).

### Fixed
- `Retry-After` em formato de data não derruba mais a chamada (`require "time"`).
- POST/PATCH sem `Idempotency-Key` não é mais repetido em 5xx, 429 ou erro de rede.
