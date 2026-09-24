require "test_helper"

class ResourcesTest < Minitest::Test
  include ClientTestHelpers

  PAGINATION = { "page" => 0, "size" => 50, "totalElements" => 120, "totalPages" => 3 }.freeze

  def test_should_not_override_object_send
    messages = Arara::Client.new(api_key: "k").messages
    assert_equal Kernel, messages.method(:send).owner
    refute_equal Arara::Resources::Messages, messages.method(:send).owner
  end

  def test_should_send_sender_and_camel_case_fields
    with_client([FakeResponse.new(202, { "id" => "m" })]) do |client, transport|
      client.messages.send_message(
        receiver: "whatsapp:+5511999998888", sender: "+5511888887777", template_name: "t",
        template_variables: ["Ana"], reply_to: "wamid.1", scheduled_at: "2026-10-01T10:00:00Z"
      )
      request = transport.requests.first

      assert_equal "POST", request.method
      assert_equal "/v1/messages", request.path
      assert_equal(
        {
          "receiver" => "whatsapp:+5511999998888", "sender" => "+5511888887777", "templateName" => "t",
          "templateVariables" => ["Ana"], "replyTo" => "wamid.1", "scheduled_at" => "2026-10-01T10:00:00Z"
        },
        json_body(request)
      )
    end
  end

  def test_should_reject_unknown_message_fields
    client = Arara::Client.new(api_key: "k")
    assert_raises(ArgumentError) { client.messages.send_message(receiver: "1", template: "x") }
  end

  def test_should_get_message_and_list_batch
    with_client([FakeResponse.new(200, { "id" => "m1" }), FakeResponse.new(200, [])]) do |client, transport|
      client.messages.get("m1")
      client.messages.list_by_batch("b1")

      assert_equal "/v1/messages/m1", transport.requests[0].path
      assert_equal "/v1/messages?batchId=b1", transport.requests[1].path
    end
  end

  def test_should_send_batch_with_idempotency_key
    with_client([FakeResponse.new(202, { "batchId" => "b" })]) do |client, transport|
      client.messages.send_batch(template_name: "t", messages: [{ "receiver" => "5511999998888" }])
      request = transport.requests.first

      assert_equal "/v1/messages/batch", request.path
      refute_nil request["Idempotency-Key"]
      assert_equal "t", json_body(request)["templateName"]
    end
  end

  def test_should_validate_batch_size
    client = Arara::Client.new(api_key: "k")
    assert_raises(ArgumentError) { client.messages.send_batch(template_name: "t", messages: []) }
    too_many = Array.new(1001) { { "receiver" => "1" } }
    assert_raises(ArgumentError) { client.messages.send_batch(template_name: "t", messages: too_many) }
  end

  def test_should_call_template_endpoints_by_id
    responses = Array.new(5) { FakeResponse.new(200, {}) }
    with_client(responses) do |client, transport|
      client.templates.get("tpl-uuid")
      client.templates.get_status("tpl-uuid")
      client.templates.delete("tpl-uuid")
      client.templates.analytics
      client.templates.template_analytics("tpl-uuid", period: "7d")

      paths = transport.requests.map { |request| "#{request.method} #{request.path}" }
      assert_equal [
        "GET /v1/templates/tpl-uuid",
        "GET /v1/templates/tpl-uuid/status",
        "DELETE /v1/templates/tpl-uuid",
        "GET /v1/templates/analytics?period=30d",
        "GET /v1/templates/tpl-uuid/analytics?period=7d"
      ], paths
    end
  end

  def test_should_create_template
    with_client([FakeResponse.new(201, { "id" => "t" })]) do |client, transport|
      client.templates.create({ "name" => "x", "category" => "UTILITY", "body" => "oi" })
      assert_equal "oi", json_body(transport.requests.first)["body"]
    end
  end

  def test_should_return_paginated_templates
    body = { "data" => [{ "id" => "1", "name" => "a" }], "pagination" => PAGINATION }
    with_client([FakeResponse.new(200, body)]) do |client, transport|
      page = client.templates.list(status: "APPROVED", page: 0, size: 50)

      assert_instance_of Arara::Page, page
      assert_equal [{ "id" => "1", "name" => "a" }], page.data
      assert_equal 120, page.pagination.total_elements
      assert_equal 3, page.pagination.total_pages
      assert page.next_page?
      assert_equal "/v1/templates?status=APPROVED&page=0&size=50", transport.requests.first.path
    end
  end

  def test_should_find_template_by_name_locally
    body = { "data" => [{ "id" => "1", "name" => "boas_vindas_2" }, { "id" => "2", "name" => "boas_vindas" }],
             "pagination" => PAGINATION }
    empty = { "data" => [], "pagination" => { "page" => 0, "size" => 50, "totalElements" => 0, "totalPages" => 0 } }
    with_client([FakeResponse.new(200, body), FakeResponse.new(200, empty)]) do |client, _transport|
      assert_equal "2", client.templates.find_by_name("boas_vindas")["id"]
      assert_nil client.templates.find_by_name("nada")
    end
  end

  def test_should_find_template_by_name_on_a_later_page
    first = { "data" => [{ "id" => "1", "name" => "promo_2" }],
              "pagination" => { "page" => 0, "size" => 50, "totalElements" => 51, "totalPages" => 2 } }
    second = { "data" => [{ "id" => "9", "name" => "promo" }],
               "pagination" => { "page" => 1, "size" => 50, "totalElements" => 51, "totalPages" => 2 } }
    with_client([FakeResponse.new(200, first), FakeResponse.new(200, second)]) do |client, transport|
      assert_equal "9", client.templates.find_by_name("promo")["id"]
      assert_equal "/v1/templates?name=promo&page=1&size=50", transport.requests.last.path
    end
  end

  def test_should_return_nil_after_last_page_without_match
    last = { "data" => [{ "id" => "1", "name" => "promo_2" }],
             "pagination" => { "page" => 0, "size" => 50, "totalElements" => 1, "totalPages" => 1 } }
    with_client([FakeResponse.new(200, last)]) do |client, transport|
      assert_nil client.templates.find_by_name("promo")
      assert_equal 1, transport.requests.size
    end
  end

  def test_should_return_paginated_smart_links
    body = { "data" => [{ "id" => "s" }], "pagination" => PAGINATION.merge("page" => 2) }
    with_client([FakeResponse.new(200, body)]) do |client, transport|
      page = client.smart_links.list(page: 2, size: 10)

      assert_equal ["s"], page.map { |link| link["id"] }
      refute page.next_page?
      assert_equal "/v1/smart-links/whatsapp?page=2&size=10", transport.requests.first.path
    end
  end

  def test_should_return_content_page_for_campaigns_and_wallet
    body = { "content" => [{ "id" => "c" }], "totalElements" => 1, "totalPages" => 1 }
    with_client([FakeResponse.new(200, body), FakeResponse.new(200, body)]) do |client, transport|
      pages = [client.campaigns.list(page: 0, size: 20), client.wallet.transactions(page: 0, size: 20)]
      paths = transport.requests.map { |request| "#{request.method} #{request.path}" }
      assert_equal ["GET /v1/campaigns?page=0&size=20", "GET /v1/wallet/transactions?page=0&size=20"], paths
      pages.each do |page|
        assert_equal [{ "id" => "c" }], page.data
        assert_equal 0, page.pagination.page
        assert_equal 20, page.pagination.size
        assert_equal 1, page.pagination.total_elements
        refute page.next_page?
      end
    end
  end

  def test_page_raises_on_unexpected_shape
    assert_raises(Arara::Error) { Arara::Page.from_data(nil) }
    assert_raises(Arara::Error) { Arara::Page.from_data({ "content" => [] }) }
    assert_raises(Arara::Error) { Arara::Page.from_content([], page: 0, size: 20) }
    assert_raises(Arara::Error) { Arara::Page.from_content({ "data" => [] }, page: 0, size: 20) }
  end

  def test_list_raises_when_api_returns_unexpected_shape
    with_client([FakeResponse.new(200, [])]) do |client, _transport|
      assert_raises(Arara::Error) { client.smart_links.list }
    end
  end

  def test_should_create_campaign_with_generated_key
    with_client([FakeResponse.new(201, { "id" => "c" })]) do |client, transport|
      client.campaigns.create({ "name" => "n", "templateName" => "t", "contacts" => [{ "to" => "5511" }] })
      refute_nil transport.requests.first["Idempotency-Key"]
    end
  end

  def test_should_call_auth_me_without_v1
    with_client([FakeResponse.new(200, { "email" => "a@b.c" })]) do |client, transport|
      assert_equal "a@b.c", client.auth.me["email"]
      assert_equal "/auth/me", transport.requests.first.path
    end
  end

  def test_should_call_opt_out_endpoints
    responses = Array.new(4) { FakeResponse.new(200, {}) }
    with_client(responses) do |client, transport|
      client.opt_outs.list
      client.opt_outs.create(phone: "5511999998888", reason: "pediu")
      client.opt_outs.get("+5511999998888")
      client.opt_outs.delete("5511999998888")

      paths = transport.requests.map { |request| "#{request.method} #{request.path}" }
      assert_equal [
        "GET /v1/opt-outs",
        "POST /v1/opt-outs",
        "GET /v1/opt-outs/%2B5511999998888",
        "DELETE /v1/opt-outs/5511999998888"
      ], paths
      assert_equal({ "phone" => "5511999998888", "reason" => "pediu" }, json_body(transport.requests[1]))
    end
  end

  def test_should_not_expose_removed_resources
    client = Arara::Client.new(api_key: "k")
    %i[users organizations api_keys].each { |name| refute_respond_to client, name }
  end
end
