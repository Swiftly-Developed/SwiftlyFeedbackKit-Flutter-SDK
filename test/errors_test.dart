import 'package:feedbackkit_flutter/feedbackkit_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('createErrorFromResponse', () {
    test('returns AuthenticationError for 401', () {
      final error = createErrorFromResponse(401, 'Invalid API key');
      expect(error, isA<AuthenticationError>());
      expect(error.statusCode, 401);
      expect(error.code, 'UNAUTHORIZED');
    });

    test('returns PaymentRequiredError for 402', () {
      final error = createErrorFromResponse(402, 'Upgrade required');
      expect(error, isA<PaymentRequiredError>());
      expect(error.statusCode, 402);
      expect(error.code, 'PAYMENT_REQUIRED');
    });

    test('returns ForbiddenError for 403', () {
      final error = createErrorFromResponse(403, 'Access denied');
      expect(error, isA<ForbiddenError>());
      expect(error.statusCode, 403);
      expect(error.code, 'FORBIDDEN');
    });

    test('returns NotFoundError for 404', () {
      final error = createErrorFromResponse(404, 'Not found');
      expect(error, isA<NotFoundError>());
      expect(error.statusCode, 404);
      expect(error.code, 'NOT_FOUND');
    });

    test('returns ConflictError for 409', () {
      final error = createErrorFromResponse(409, 'Already exists');
      expect(error, isA<ConflictError>());
      expect(error.statusCode, 409);
      expect(error.code, 'CONFLICT');
    });

    test('returns ValidationError for 400', () {
      final error = createErrorFromResponse(400, 'Invalid input');
      expect(error, isA<ValidationError>());
      expect(error.statusCode, 400);
      expect(error.code, 'VALIDATION_ERROR');
    });

    test('returns ServerError for 5xx', () {
      final error500 = createErrorFromResponse(500, 'Internal server error');
      expect(error500, isA<ServerError>());
      expect(error500.statusCode, 500);

      final error503 = createErrorFromResponse(503, 'Service unavailable');
      expect(error503, isA<ServerError>());
      expect(error503.statusCode, 503);
    });

    test('returns FeedbackKitError for unknown status codes', () {
      final error = createErrorFromResponse(418, "I'm a teapot");
      expect(error, isA<FeedbackKitError>());
      expect(error.statusCode, 418);
      expect(error.code, 'UNKNOWN_ERROR');
    });
  });

  group('NetworkError', () {
    test('has isTimeout flag', () {
      final timeoutError = NetworkError(
        message: 'Request timed out',
        isTimeout: true,
      );
      expect(timeoutError.isTimeout, true);
      expect(timeoutError.code, 'TIMEOUT');

      final networkError = NetworkError(message: 'Connection failed');
      expect(networkError.isTimeout, false);
      expect(networkError.code, 'NETWORK_ERROR');
    });
  });
}
