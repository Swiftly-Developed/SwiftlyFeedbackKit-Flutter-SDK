/// Base exception class for all FeedbackKit errors.
class FeedbackKitError implements Exception {
  /// Human-readable error message.
  final String message;

  /// HTTP status code if applicable.
  final int? statusCode;

  /// Error code for programmatic handling.
  ///
  /// For an error the server sent through the detailed envelope this is the
  /// server's own wire token — e.g. `METRICS_CUSTOM_EVENTS_REQUIRE_PRO` — and
  /// not the class-level default. The shared middleware envelope carries no
  /// machine-readable code at all, and in that case the class default stands.
  final String code;

  /// The wire spelling of the parameter at fault, when the server named one.
  ///
  /// Only the detailed envelope carries this; it is null otherwise.
  final String? field;

  const FeedbackKitError({
    required this.message,
    this.statusCode,
    required this.code,
    this.field,
  });

  @override
  String toString() => 'FeedbackKitError: $message (code: $code)';
}

/// Error thrown when authentication fails (401).
class AuthenticationError extends FeedbackKitError {
  const AuthenticationError({
    super.message = 'Authentication required',
    String? code,
    super.field,
  }) : super(
          statusCode: 401,
          code: code ?? 'UNAUTHORIZED',
        );

  @override
  String toString() => 'AuthenticationError: $message';
}

/// Error thrown when payment is required (402).
class PaymentRequiredError extends FeedbackKitError {
  const PaymentRequiredError({
    super.message = 'Payment required to access this feature',
    String? code,
    super.field,
  }) : super(
          statusCode: 402,
          code: code ?? 'PAYMENT_REQUIRED',
        );

  @override
  String toString() => 'PaymentRequiredError: $message';
}

/// Error thrown when access is forbidden (403).
class ForbiddenError extends FeedbackKitError {
  const ForbiddenError({
    super.message = 'Access forbidden',
    String? code,
    super.field,
  }) : super(
          statusCode: 403,
          code: code ?? 'FORBIDDEN',
        );

  @override
  String toString() => 'ForbiddenError: $message';
}

/// Error thrown when a resource is not found (404).
class NotFoundError extends FeedbackKitError {
  const NotFoundError({
    super.message = 'Resource not found',
    String? code,
    super.field,
  }) : super(
          statusCode: 404,
          code: code ?? 'NOT_FOUND',
        );

  @override
  String toString() => 'NotFoundError: $message';
}

/// Error thrown when there's a conflict (409).
class ConflictError extends FeedbackKitError {
  const ConflictError({
    super.message = 'Resource conflict',
    String? code,
    super.field,
  }) : super(
          statusCode: 409,
          code: code ?? 'CONFLICT',
        );

  @override
  String toString() => 'ConflictError: $message';
}

/// Error thrown when validation fails (400).
class ValidationError extends FeedbackKitError {
  /// Validation errors by field.
  final Map<String, String>? fieldErrors;

  const ValidationError({
    super.message = 'Validation failed',
    this.fieldErrors,
    String? code,
    super.field,
  }) : super(
          statusCode: 400,
          code: code ?? 'VALIDATION_ERROR',
        );

  @override
  String toString() {
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      return 'ValidationError: $message - $fieldErrors';
    }
    return 'ValidationError: $message';
  }
}

/// Error thrown for network issues.
class NetworkError extends FeedbackKitError {
  /// Whether this was a timeout error.
  final bool isTimeout;

  const NetworkError({
    super.message = 'Network error',
    this.isTimeout = false,
  }) : super(
          statusCode: null,
          code: isTimeout ? 'TIMEOUT' : 'NETWORK_ERROR',
        );

  @override
  String toString() => 'NetworkError: $message';
}

/// Error thrown for unexpected server errors (5xx).
class ServerError extends FeedbackKitError {
  const ServerError({
    super.message = 'Server error',
    int? statusCode,
    String? code,
    super.field,
  }) : super(
          statusCode: statusCode ?? 500,
          code: code ?? 'SERVER_ERROR',
        );

  @override
  String toString() => 'ServerError: $message (status: $statusCode)';
}

/// Error thrown when the caller is rate limited (429).
///
/// The metrics API-key surface allows 60 requests per 60 seconds. This SDK does
/// not retry or back off on your behalf; [retryAfterSeconds] carries the
/// server's `Retry-After` header when it sent one in the integer-seconds form.
class RateLimitError extends FeedbackKitError {
  /// Seconds to wait before retrying, when the server said.
  final int? retryAfterSeconds;

  const RateLimitError({
    super.message = 'Too many requests',
    this.retryAfterSeconds,
    String? code,
    super.field,
  }) : super(
          statusCode: 429,
          code: code ?? 'RATE_LIMITED',
        );

  @override
  String toString() => 'RateLimitError: $message';
}

/// Creates the appropriate error from an HTTP status code and message.
/// [code] and [field] come from the server's detailed error envelope when it
/// sent one. They are optional and named, so every existing call site keeps
/// compiling; when [code] is null each class supplies its own default.
FeedbackKitError createErrorFromResponse(
  int statusCode,
  String message, {
  String? code,
  String? field,
  int? retryAfterSeconds,
}) {
  switch (statusCode) {
    case 400:
      return ValidationError(message: message, code: code, field: field);
    case 401:
      return AuthenticationError(message: message, code: code, field: field);
    case 402:
      return PaymentRequiredError(message: message, code: code, field: field);
    case 403:
      return ForbiddenError(message: message, code: code, field: field);
    case 404:
      return NotFoundError(message: message, code: code, field: field);
    case 409:
      return ConflictError(message: message, code: code, field: field);
    case 429:
      return RateLimitError(
        message: message,
        retryAfterSeconds: retryAfterSeconds,
        code: code,
        field: field,
      );
    default:
      if (statusCode >= 500) {
        return ServerError(
          message: message,
          statusCode: statusCode,
          code: code,
          field: field,
        );
      }
      return FeedbackKitError(
        message: message,
        statusCode: statusCode,
        code: code ?? 'UNKNOWN_ERROR',
        field: field,
      );
  }
}
