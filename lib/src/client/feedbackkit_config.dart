/// Configuration for the FeedbackKit SDK.
class FeedbackKitConfig {
  /// The API key for authentication.
  final String apiKey;

  /// Base URL for the API.
  final String baseUrl;

  /// Initial user ID for the session.
  final String? userId;

  /// Request timeout in milliseconds.
  final int timeout;

  /// Default production base URL.
  static const String defaultBaseUrl =
      'https://api.prod.getfeedbackkit.com/api/v1';

  /// Default request timeout in milliseconds (30 seconds).
  static const int defaultTimeout = 30000;

  /// Rejects a base URL that would send the API key in cleartext.
  ///
  /// HTTPS is required. HTTP is accepted only for a loopback host so a local
  /// server can be used during development.
  static void assertSecureBaseUrl(String baseUrl) {
    final uri = Uri.tryParse(baseUrl);
    final host = uri?.host.toLowerCase();
    final loopback =
        host == 'localhost' || host == '127.0.0.1' || host == '::1';
    if (uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'https' || (uri.scheme == 'http' && loopback))) {
      return;
    }
    throw ArgumentError(
      'FeedbackKit only sends the API key over HTTPS. '
      '$baseUrl is not allowed. Loopback HTTP is allowed for local development.',
    );
  }

  const FeedbackKitConfig({
    required this.apiKey,
    this.baseUrl = defaultBaseUrl,
    this.userId,
    this.timeout = defaultTimeout,
  });

  /// Creates a copy of this config with the given fields replaced.
  FeedbackKitConfig copyWith({
    String? apiKey,
    String? baseUrl,
    String? userId,
    int? timeout,
  }) {
    return FeedbackKitConfig(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      userId: userId ?? this.userId,
      timeout: timeout ?? this.timeout,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeedbackKitConfig &&
        other.apiKey == apiKey &&
        other.baseUrl == baseUrl &&
        other.userId == userId &&
        other.timeout == timeout;
  }

  @override
  int get hashCode => Object.hash(apiKey, baseUrl, userId, timeout);
}
