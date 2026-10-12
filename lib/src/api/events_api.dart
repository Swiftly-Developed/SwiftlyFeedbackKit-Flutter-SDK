import '../errors/feedbackkit_error.dart';
import '../http/http_client.dart';
import '../models/tracked_event.dart';

/// API client for event tracking operations.
class EventsApi {
  final FeedbackKitHttpClient _http;

  EventsApi(this._http);

  /// Tracks an event.
  ///
  /// The body is `event_name`, `user_id`, and string `properties`. The server
  /// rejects a payload that uses `name` or omits `user_id`.
  ///
  /// Throws a [ValidationError] when no user id is configured, the event name
  /// is empty, or a property is not a string, number, or boolean.
  Future<void> track(TrackedEvent event) async {
    final userId = _http.userId?.trim();
    if (userId == null || userId.isEmpty) {
      throw const ValidationError(
        message:
            'A user ID is required before tracking an event. Call setUserId first.',
      );
    }
    if (event.name.trim().isEmpty) {
      throw const ValidationError(message: 'Event name cannot be empty.');
    }

    final Map<String, dynamic> body;
    try {
      body = event.toJson();
    } on FormatException catch (error) {
      throw ValidationError(message: error.message);
    }
    body['user_id'] = userId;

    await _http.post<dynamic>(
      '/events/track',
      body: body,
    );
  }

  /// Tracks an event by name with optional properties.
  Future<void> trackEvent(
    String name, {
    Map<String, dynamic>? properties,
  }) async {
    await track(
      TrackedEvent(
        name: name,
        properties: properties,
        timestamp: DateTime.now(),
      ),
    );
  }
}
