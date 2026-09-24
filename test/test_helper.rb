require "minitest/autorun"
require "json"
require "arara"

class FakeResponse
  attr_reader :code, :body

  def initialize(status, body = nil, headers = {})
    @code = status.to_s
    @body = body.nil? || body.is_a?(String) ? body : JSON.generate(body)
    @headers = headers
  end

  def [](name)
    @headers[name]
  end
end

class FakeTransport
  attr_reader :requests
  attr_writer :use_ssl, :open_timeout, :read_timeout

  def initialize(responses)
    @responses = responses
    @requests = []
  end

  def request(request)
    @requests << request
    outcome = @responses.shift || raise("unexpected request #{request.method} #{request.path}")
    raise outcome if outcome.is_a?(Exception)

    outcome
  end
end

module ClientTestHelpers
  API_KEY = "ara_live_test".freeze

  def with_client(responses, max_retries: 3)
    transport = FakeTransport.new(responses)
    client = Arara::Client.new(api_key: API_KEY, base_url: "https://api.test", max_retries: max_retries)
    Net::HTTP.stub(:new, transport) do
      Kernel.stub(:sleep, nil) do
        http = client.instance_variable_get(:@auth).instance_variable_get(:@http)
        http.stub(:sleep, nil) { yield client, transport }
      end
    end
  end

  def json_body(request)
    JSON.parse(request.body)
  end
end
