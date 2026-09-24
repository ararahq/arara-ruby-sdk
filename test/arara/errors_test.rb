require "test_helper"

class ErrorsTest < Minitest::Test
  include ClientTestHelpers

  def envelope(code, message = "falhou", details = nil)
    { "error" => { "code" => code, "message" => message, "details" => details } }
  end

  def raise_for(status, body)
    with_client([FakeResponse.new(status, body)], max_retries: 0) do |client, _transport|
      return assert_raises(Arara::Error) { client.auth.me }
    end
  end

  def test_should_raise_plan_feature_locked_error_with_details
    details = { "feature" => "brain", "currentPlan" => "DECOLAGEM", "upgradeTo" => "VOO" }
    error = raise_for(403, envelope("PLAN_FEATURE_LOCKED", "Disponivel no Voo", details))

    assert_instance_of Arara::PlanFeatureLockedError, error
    assert_kind_of Arara::PermissionError, error
    assert_equal 403, error.status_code
    assert_equal "PLAN_FEATURE_LOCKED", error.code
    assert_equal "Disponivel no Voo", error.message
    assert_equal "brain", error.feature
    assert_equal "DECOLAGEM", error.current_plan
    assert_equal "VOO", error.upgrade_to
  end

  def test_plan_feature_locked_without_details_returns_nil_fields
    error = raise_for(403, envelope("PLAN_FEATURE_LOCKED"))
    assert_nil error.feature
  end

  def test_should_raise_authentication_error_for_403_without_code
    error = raise_for(403, { "status" => 403, "error" => "Forbidden", "message" => "API Key permission insufficient" })
    assert_instance_of Arara::AuthenticationError, error
    assert_nil error.code
  end

  def test_should_raise_authentication_error_for_403_with_empty_body
    assert_instance_of Arara::AuthenticationError, raise_for(403, nil)
  end

  def test_should_raise_permission_error_for_403_with_business_code
    assert_instance_of Arara::PermissionError, raise_for(403, envelope("RESOURCE_FORBIDDEN"))
  end

  def test_should_raise_authentication_error_for_401
    assert_instance_of Arara::AuthenticationError, raise_for(401, nil)
  end

  def test_should_map_402_to_payment_required
    error = raise_for(402, envelope("INSUFFICIENT_FUNDS"))
    assert_instance_of Arara::PaymentRequiredError, error
    assert_equal "INSUFFICIENT_FUNDS", error.code
  end

  def test_should_map_422_to_unprocessable_entity
    error = raise_for(422, envelope("INVALID_RECIPIENT", "numero invalido", { "receiver" => "x" }))
    assert_instance_of Arara::UnprocessableEntityError, error
    assert_equal({ "receiver" => "x" }, error.details)
  end

  def test_should_map_remaining_statuses
    {
      400 => Arara::BadRequestError,
      404 => Arara::NotFoundError,
      409 => Arara::ConflictError,
      418 => Arara::Error,
      500 => Arara::ServerError
    }.each do |status, klass|
      assert_instance_of klass, raise_for(status, envelope("X")), "status #{status}"
    end
  end

  def test_should_use_default_message_when_body_is_not_json
    error = raise_for(404, "not json")
    assert_equal "Arara API request failed with status 404", error.message
  end
end
