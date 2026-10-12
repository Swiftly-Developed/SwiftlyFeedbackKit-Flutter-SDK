import 'dart:math';

import '../api/comments_api.dart';
import '../api/events_api.dart';
import '../api/feedback_api.dart';
import '../api/metrics_api.dart';
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

  /// API for metrics reads.
  late final MetricsApi metrics;

  final String Function() _createAnonymousUserId;
  Future<String>? _resolvedUserId;

  /// Creates a new FeedbackKit client.
  ///
  /// [createAnonymousUserId] supplies the id used when neither the config nor
  /// storage has one. Tests pass a fixed value; production generates
  /// `local_<uuid>`.
  FeedbackKit({
    required FeedbackKitConfig config,
    FeedbackKitStorage? storage,
    String Function()? createAnonymousUserId,
  })  : _config = config,
        _http = FeedbackKitHttpClient(config: config),
        _storage = storage ?? FeedbackKitStorage(),
        _createAnonymousUserId = createAnonymousUserId ?? _generateLocalUserId {
    feedback = FeedbackApi(_http);
    votes = VotesApi(_http);
    comments = CommentsApi(_http);
    users = UsersApi(_http);
    events = EventsApi(_http);
    metrics = MetricsApi(_http);
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
  /// This also persists the user ID to storage. An explicit id wins over any
  /// id already stored.
  Future<void> setUserId(String? userId) async {
    final trimmed = userId?.trim();
    final stored = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    _http.userId = stored;
    await _storage.setUserId(stored);
    _resolvedUserId = stored == null ? null : Future<String>.value(stored);
  }

  /// Resolves the user id for this session.
  ///
  /// An id passed in the config wins and is written to storage, so a later
  /// launch that omits one still has it. Otherwise the stored id is used.
  /// When neither exists, a `local_` id is generated and stored. Concurrent
  /// callers share one resolution.
  Future<String> resolveUserId() {
    return _resolvedUserId ??= _resolveUserId();
  }

  Future<String> _resolveUserId() async {
    final explicit = _http.userId?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      await _storage.setUserId(explicit);
      return explicit;
    }

    final stored = (await _storage.getUserId())?.trim();
    final current = _http.userId?.trim();
    if (current != null && current.isNotEmpty) {
      await _storage.setUserId(current);
      return current;
    }
    if (stored != null && stored.isNotEmpty) {
      _http.userId = stored;
      return stored;
    }

    final generated = _createAnonymousUserId();
    _http.userId = generated;
    await _storage.setUserId(generated);
    return generated;
  }

  /// Loads the persisted user ID from storage.
  ///
  /// This resolves the session id: an explicit config id is kept, and a
  /// missing id is filled in. It does not replace an explicit id with a
  /// previously stored one.
  Future<String?> loadUserId() => resolveUserId();

  /// Clears all stored data and resets the user ID.
  Future<void> clearStorage() async {
    _http.userId = null;
    _resolvedUserId = null;
    await _storage.clear();
  }

  /// Closes the client and releases resources.
  void close() {
    _http.close();
  }
}

String _generateLocalUserId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex =
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  return 'local_${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
