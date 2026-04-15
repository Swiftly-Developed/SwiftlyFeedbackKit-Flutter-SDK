import '../http/http_client.dart';
import '../models/tracked_event.dart';

/// API client for event tracking operations.
class EventsApi {
  final FeedbackKitHttpClient _http;

  EventsApi(this._http);

  /// Tracks an event.
  Future<void> track(TrackedEvent event) async {
    await _http.post<dynamic>(
      '/events/track',
      body: event.toJson(),
    );
  }

  /// Tracks an event by name with optional properties.
  Future<void> trackEvent(
    String name, {
    Map<String, dynamic>? properties,
  }) async {
    await track(TrackedEvent(
      name: name,
      properties: properties,
      timestamp: DateTime.now(),
    ));
  }
}
