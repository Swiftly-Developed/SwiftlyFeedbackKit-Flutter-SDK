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

    test('returns RateLimitError for 429', () {
      // Added by METRICS03 phase 08: the metrics API-key surface is rate
      // limited at 60/60s, and before this 429 fell through to the unknown
      // fallback where no host app could recognise it.
      final error = createErrorFromResponse(429, 'Too many requests');
      expect(error, isA<RateLimitError>());
      expect(error.statusCode, 429);
      expect(error.code, 'RATE_LIMITED');
    });

    test(
        'a server wire code overrides the class default, and field rides '
        'along', () {
      // The detailed error envelope carries a machine-readable token. Without
      // it a host app cannot tell METRICS_CUSTOM_EVENTS_REQUIRE_PRO (402, an
      // upsell) from METRICS_MEASURE_REQUIRES_BEARER (403, a wrong-surface
      // call) — the two errors it most needs to act on differently.
      final upsell = createErrorFromResponse(
        402,
        'Breaking down metrics by event name requires the Pro plan.',
        code: 'METRICS_CUSTOM_EVENTS_REQUIRE_PRO',
        field: 'dimension',
      );
      expect(upsell, isA<PaymentRequiredError>());
      expect(upsell.code, 'METRICS_CUSTOM_EVENTS_REQUIRE_PRO');
      expect(upsell.field, 'dimension');

      final wrongSurface = createErrorFromResponse(
        403,
        "Measure 'mrr_sum' is not available on the API-key surface.",
        code: 'METRICS_MEASURE_REQUIRES_BEARER',
        field: 'measures',
      );
      expect(wrongSurface, isA<ForbiddenError>());
      expect(wrongSurface.code, 'METRICS_MEASURE_REQUIRES_BEARER');
      expect(upsell.code == wrongSurface.code, isFalse);
    });

    test('the boolean envelope invents no code, and leaves field null', () {
      // Shape B carries no machine-readable code at all. The class default
      // stands and nothing is fabricated.
      final error = createErrorFromResponse(401, 'Invalid API key');
      expect(error.code, 'UNAUTHORIZED');
      expect(error.field, isNull);
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
