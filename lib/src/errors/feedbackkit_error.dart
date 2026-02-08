/// Base exception class for all FeedbackKit errors.
class FeedbackKitError implements Exception {
  /// Human-readable error message.
  final String message;

  /// HTTP status code if applicable.
  final int? statusCode;

  /// Error code for programmatic handling.
  final String code;

  const FeedbackKitError({
    required this.message,
    this.statusCode,
    required this.code,
  });

  @override
  String toString() => 'FeedbackKitError: $message (code: $code)';
}

/// Error thrown when authentication fails (401).
class AuthenticationError extends FeedbackKitError {
  const AuthenticationError({String message = 'Authentication required'})
      : super(
          message: message,
          statusCode: 401,
          code: 'UNAUTHORIZED',
        );

  @override
  String toString() => 'AuthenticationError: $message';
}

/// Error thrown when payment is required (402).
class PaymentRequiredError extends FeedbackKitError {
  const PaymentRequiredError({
    String message = 'Payment required to access this feature',
  }) : super(
          message: message,
          statusCode: 402,
          code: 'PAYMENT_REQUIRED',
        );

  @override
  String toString() => 'PaymentRequiredError: $message';
}

/// Error thrown when access is forbidden (403).
class ForbiddenError extends FeedbackKitError {
  const ForbiddenError({String message = 'Access forbidden'})
      : super(
          message: message,
          statusCode: 403,
          code: 'FORBIDDEN',
        );

  @override
  String toString() => 'ForbiddenError: $message';
}

/// Error thrown when a resource is not found (404).
class NotFoundError extends FeedbackKitError {
  const NotFoundError({String message = 'Resource not found'})
      : super(
          message: message,
          statusCode: 404,
          code: 'NOT_FOUND',
        );

  @override
  String toString() => 'NotFoundError: $message';
}

/// Error thrown when there's a conflict (409).
class ConflictError extends FeedbackKitError {
  const ConflictError({String message = 'Resource conflict'})
      : super(
          message: message,
          statusCode: 409,
          code: 'CONFLICT',
        );

  @override
  String toString() => 'ConflictError: $message';
}

/// Error thrown when validation fails (400).
class ValidationError extends FeedbackKitError {
  /// Validation errors by field.
  final Map<String, String>? fieldErrors;

  const ValidationError({
    String message = 'Validation failed',
    this.fieldErrors,
  }) : super(
          message: message,
          statusCode: 400,
          code: 'VALIDATION_ERROR',
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
    String message = 'Network error',
    this.isTimeout = false,
  }) : super(
          message: message,
          statusCode: null,
          code: isTimeout ? 'TIMEOUT' : 'NETWORK_ERROR',
        );

  @override
  String toString() => 'NetworkError: $message';
}

/// Error thrown for unexpected server errors (5xx).
class ServerError extends FeedbackKitError {
  const ServerError({
    String message = 'Server error',
    int? statusCode,
  }) : super(
          message: message,
          statusCode: statusCode ?? 500,
          code: 'SERVER_ERROR',
        );

  @override
  String toString() => 'ServerError: $message (status: $statusCode)';
}

/// Creates the appropriate error from an HTTP status code and message.
FeedbackKitError createErrorFromResponse(int statusCode, String message) {
  switch (statusCode) {
    case 400:
      return ValidationError(message: message);
    case 401:
      return AuthenticationError(message: message);
    case 402:
      return PaymentRequiredError(message: message);
    case 403:
      return ForbiddenError(message: message);
    case 404:
      return NotFoundError(message: message);
    case 409:
      return ConflictError(message: message);
    default:
      if (statusCode >= 500) {
        return ServerError(message: message, statusCode: statusCode);
      }
      return FeedbackKitError(
        message: message,
        statusCode: statusCode,
        code: 'UNKNOWN_ERROR',
      );
  }
}
