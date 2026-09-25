module Arara
  class Error < StandardError
    attr_reader :status_code, :code, :details, :retry_after

    def initialize(message, code: nil, status_code: nil, details: nil, retry_after: nil)
      super(message)
      @code = code
      @status_code = status_code
      @details = details
      @retry_after = retry_after
    end
  end

  class BadRequestError < Error; end

  class AuthenticationError < Error; end

  class PaymentRequiredError < Error; end

  class PermissionError < Error; end

  class PlanFeatureLockedError < PermissionError
    def feature
      detail("feature")
    end

    def current_plan
      detail("currentPlan")
    end

    def upgrade_to
      detail("upgradeTo")
    end

    private

    def detail(key)
      details.is_a?(Hash) ? details[key] : nil
    end
  end

  class NotFoundError < Error; end

  class ConflictError < Error; end

  class UnprocessableEntityError < Error; end

  class RateLimitError < Error; end

  class ServerError < Error; end

  class NetworkError < Error; end

  PLAN_FEATURE_LOCKED = "PLAN_FEATURE_LOCKED".freeze
  SERVER_ERROR_THRESHOLD = 500

  STATUS_ERRORS = {
    400 => BadRequestError,
    401 => AuthenticationError,
    402 => PaymentRequiredError,
    404 => NotFoundError,
    409 => ConflictError,
    422 => UnprocessableEntityError,
    429 => RateLimitError
  }.freeze

  module_function

  def error_for_status(status_code, message, code: nil, details: nil, retry_after: nil)
    klass = error_class_for(status_code, code)
    klass.new(message, code: code, status_code: status_code, details: details, retry_after: retry_after)
  end

  def error_class_for(status_code, code)
    return forbidden_error_class(code) if status_code == 403
    return STATUS_ERRORS[status_code] if STATUS_ERRORS.key?(status_code)

    status_code && status_code >= SERVER_ERROR_THRESHOLD ? ServerError : Error
  end

  def forbidden_error_class(code)
    return AuthenticationError if code.nil? || code.to_s.empty?
    return PlanFeatureLockedError if code == PLAN_FEATURE_LOCKED

    PermissionError
  end
end
