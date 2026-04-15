import '../api/comments_api.dart';
import '../api/events_api.dart';
import '../api/feedback_api.dart';
import '../api/users_api.dart';
import '../api/votes_api.dart';
import '../http/http_client.dart';
import '../storage/feedbackkit_storage.dart';
import 'feedbackkit_config.dart';

/// Main FeedbackKit client that provides access to all API modules.
class FeedbackKit {
  final FeedbackKitConfig _config;
  final FeedbackKitHttpClient _http;
  final FeedbackKitStorage _storage;

  /// API for feedback operations.
  late final FeedbackApi feedback;

  /// API for vote operations.
  late final VotesApi votes;

  /// API for comment operations.
  late final CommentsApi comments;

  /// API for user operations.
  late final UsersApi users;

  /// API for event tracking.
  late final EventsApi events;

  /// Creates a new FeedbackKit client.
  FeedbackKit({
    required FeedbackKitConfig config,
    FeedbackKitStorage? storage,
  })  : _config = config,
        _http = FeedbackKitHttpClient(config: config),
        _storage = storage ?? FeedbackKitStorage() {
    feedback = FeedbackApi(_http);
    votes = VotesApi(_http);
    comments = CommentsApi(_http);
    users = UsersApi(_http);
    events = EventsApi(_http);
  }

  /// Creates a FeedbackKit client with the given API key.
  factory FeedbackKit.configure({
    required String apiKey,
    String? baseUrl,
    String? userId,
    int? timeout,
  }) {
    return FeedbackKit(
      config: FeedbackKitConfig(
        apiKey: apiKey,
        baseUrl: baseUrl ?? FeedbackKitConfig.defaultBaseUrl,
        userId: userId,
        timeout: timeout ?? FeedbackKitConfig.defaultTimeout,
      ),
    );
  }

  /// Gets the current configuration.
  FeedbackKitConfig get config => _config;

  /// Gets the base URL.
  String get baseUrl => _config.baseUrl;

  /// Gets the current user ID.
  String? get userId => _http.userId;

  /// Sets the current user ID.
  ///
  /// This also persists the user ID to storage.
  Future<void> setUserId(String? userId) async {
    _http.userId = userId;
    await _storage.setUserId(userId);
  }

  /// Loads the persisted user ID from storage.
  Future<String?> loadUserId() async {
    final storedUserId = await _storage.getUserId();
    if (storedUserId != null) {
      _http.userId = storedUserId;
    }
    return storedUserId;
  }

  /// Clears all stored data and resets the user ID.
  Future<void> clearStorage() async {
    _http.userId = null;
    await _storage.clear();
  }

  /// Closes the client and releases resources.
  void close() {
    _http.close();
  }
}
