require "test_helper"

class HttpClientTest < Minitest::Test
  include ClientTestHelpers

  def test_should_reuse_generated_idempotency_key_when_send_is_retried_after_5xx
    responses = [FakeResponse.new(503), FakeResponse.new(202, { "id" => "msg_1" })]
    with_client(responses) do |client, transport|
      result = client.messages.send_message(receiver: "5511999998888", template_name: "boas_vindas")

      assert_equal "msg_1", result["id"]
      keys = transport.requests.map { |request| request["Idempotency-Key"] }
      assert_equal 2, keys.size
      refute_nil keys.first
      assert_match(/\A\h{8}-\h{4}-4\h{3}-[89ab]\h{3}-\h{12}\z/, keys.first)
      assert_equal keys.first, keys.last
    end
  end

  def test_should_use_caller_idempotency_key_when_given
    with_client([FakeResponse.new(202, { "id" => "msg_1" })]) do |client, transport|
      client.messages.deliver(receiver: "5511999998888", body: "oi", idempotency_key: "order-1234")

      assert_equal "order-1234", transport.requests.first["Idempotency-Key"]
    end
  end

  def test_should_generate_distinct_keys_per_call
    responses = [FakeResponse.new(202, {}), FakeResponse.new(202, {})]
    with_client(responses) do |client, transport|
      2.times { client.messages.send_message(receiver: "5511999998888", body: "oi") }

      refute_equal transport.requests[0]["Idempotency-Key"], transport.requests[1]["Idempotency-Key"]
    end
  end

  def test_should_not_retry_post_without_idempotency_key
    with_client([FakeResponse.new(503), FakeResponse.new(200, {})]) do |client, transport|
      assert_raises(Arara::ServerError) { client.campaigns.cancel("c1") }
      assert_equal 1, transport.requests.size
    end
  end

  def test_should_not_retry_post_without_idempotency_key_on_network_error
    with_client([Errno::ECONNRESET.new, FakeResponse.new(200, {})]) do |client, transport|
      assert_raises(Arara::NetworkError) { client.opt_outs.create(phone: "5511999998888") }
      assert_equal 1, transport.requests.size
    end
  end

  def test_should_retry_get_on_5xx
    with_client([FakeResponse.new(500), FakeResponse.new(200, { "ok" => true })]) do |client, transport|
      assert_equal({ "ok" => true }, client.auth.me)
      assert_equal 2, transport.requests.size
    end
  end

  def test_should_retry_get_on_network_error_until_max_retries
    errors = Array.new(3) { Net::ReadTimeout.new }
    with_client(errors, max_retries: 2) do |client, transport|
      assert_raises(Arara::NetworkError) { client.auth.me }
      assert_equal 3, transport.requests.size
    end
  end

  def test_should_parse_http_date_retry_after_without_crashing
    future = (Time.now + 5).httpdate
    responses = [FakeResponse.new(429, nil, "Retry-After" => future)]
    with_client(responses, max_retries: 0) do |client, _transport|
      error = assert_raises(Arara::RateLimitError) { client.auth.me }
      assert_operator error.retry_after, :>=, 0
      assert_operator error.retry_after, :<=, 6
    end
  end

  def test_should_parse_numeric_retry_after
    with_client([FakeResponse.new(429, nil, "Retry-After" => "7")], max_retries: 0) do |client, _transport|
      error = assert_raises(Arara::RateLimitError) { client.auth.me }
      assert_equal 7.0, error.retry_after
    end
  end

  def test_should_ignore_invalid_retry_after
    with_client([FakeResponse.new(429, nil, "Retry-After" => "soon")], max_retries: 0) do |client, _transport|
      error = assert_raises(Arara::RateLimitError) { client.auth.me }
      assert_nil error.retry_after
    end
  end

  def test_should_send_bearer_and_accept_headers
    with_client([FakeResponse.new(200, {})]) do |client, transport|
      client.auth.me
      request = transport.requests.first

      assert_equal "Bearer #{ClientTestHelpers::API_KEY}", request["Authorization"]
      assert_equal "application/json", request["Accept"]
      assert_equal "/auth/me", request.path
    end
  end

  def test_should_return_nil_for_no_content
    with_client([FakeResponse.new(204)]) do |client, _transport|
      assert_nil client.templates.delete("tpl-uuid")
    end
  end

  def test_should_raise_when_success_body_is_not_json
    with_client([FakeResponse.new(200, "<html>")]) do |client, _transport|
      assert_raises(Arara::Error) { client.auth.me }
    end
  end

  def test_should_generate_key_and_retry_when_caller_key_is_blank
    ["", "   "].each do |blank|
      responses = [FakeResponse.new(503), FakeResponse.new(202, {})]
      with_client(responses) do |client, transport|
        client.messages.send_message(receiver: "5511999998888", body: "oi", idempotency_key: blank)
        keys = transport.requests.map { |request| request["Idempotency-Key"] }

        assert_equal 2, keys.size
        assert_match(/\A\h{8}-/, keys.first)
        assert_equal keys.first, keys.last
      end
    end
  end

  def test_should_generate_campaign_key_when_blank
    with_client([FakeResponse.new(201, {})]) do |client, transport|
      client.campaigns.create({ "name" => "n" }, idempotency_key: " ")
      assert_match(/\A\h{8}-/, transport.requests.first["Idempotency-Key"])
    end
  end

  def test_should_strip_caller_key
    with_client([FakeResponse.new(202, {})]) do |client, transport|
      client.messages.send_message(receiver: "5511999998888", body: "oi", idempotency_key: " order-1 ")
      assert_equal "order-1", transport.requests.first["Idempotency-Key"]
    end
  end

  def test_should_not_retry_post_with_blank_key_at_http_layer
    http = Arara::HttpClient.new(api_key: "k", base_url: "https://api.test")
    transport = FakeTransport.new([FakeResponse.new(503), FakeResponse.new(200, {})])
    Net::HTTP.stub(:new, transport) do
      http.stub(:sleep, nil) do
        assert_raises(Arara::ServerError) { http.post("/v1/x", body: {}, idempotency_key: "  ") }
      end
    end
    assert_equal 1, transport.requests.size
    assert_nil transport.requests.first["Idempotency-Key"]
  end

  def test_should_not_double_slash_when_base_url_has_trailing_slash
    transport = FakeTransport.new([FakeResponse.new(200, {})])
    client = Arara::Client.new(api_key: "k", base_url: "https://api.test/")
    Net::HTTP.stub(:new, transport) { client.auth.me }
    assert_equal "/auth/me", transport.requests.first.path
  end

  def test_should_require_api_key
    assert_raises(ArgumentError) { Arara::Client.new(api_key: " ") }
  end
end
