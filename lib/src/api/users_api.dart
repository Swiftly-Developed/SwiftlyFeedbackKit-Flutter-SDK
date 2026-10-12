import '../http/http_client.dart';
import '../models/sdk_user.dart';

/// Request object for registering an SDK user.
///
/// `POST /users/register` decodes [userId] (`user_id` on the wire) and an
/// optional [mrr]. [email] and [name] are accepted so 1.0.1 call sites still
/// compile; the server ignores them, and this type does not send them.
class RegisterUserRequest {
  final String? _userId;
  final String? _legacyId;

  /// SDK user identifier. Sent as `user_id`.
  ///
  /// Resolves the `userId` argument, or the deprecated `id` alias when that is
  /// the one the caller passed.
  String get userId {
    final resolved = _userId ?? _legacyId;
    if (resolved == null) {
      throw ArgumentError('RegisterUserRequest requires userId.');
    }
    return resolved;
  }

  /// Monthly recurring revenue. Omitted from the body when null.
  final double? mrr;

  /// Ignored by the server. `POST /users/register` accepts `userId` and an optional `mrr` only.
  final String? email;

  /// Ignored by the server. `POST /users/register` accepts `userId` and an optional `mrr` only.
  final String? name;

  /// [id] is a deprecated alias for [userId]. A null-check in the initializer
  /// list is not a constant expression, so the alias is stored and resolved
  /// by [userId] / [toJson] instead of folded in the const constructor.
  const RegisterUserRequest({
    String? userId,
    @Deprecated(
      'Pass userId. The value is sent as user_id; the server does not read id.',
    )
    String? id,
    this.mrr,
    @Deprecated(
      'Ignored by the server. POST /users/register accepts userId and an optional mrr only.',
    )
    this.email,
    @Deprecated(
      'Ignored by the server. POST /users/register accepts userId and an optional mrr only.',
    )
    this.name,
  }) : assert(
          userId != null || id != null,
          'RegisterUserRequest requires userId.',
        ),
        _userId = userId,
        _legacyId = id;

  /// Wire body. Keys match `request-wire-corpus.json` → `register_sdk_user`.
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      if (mrr != null) 'mrr': mrr,
    };
  }
}

/// API client for user operations.
class UsersApi {
  final FeedbackKitHttpClient _http;

  UsersApi(this._http);

  /// Registers a new user or updates an existing one.
  Future<SDKUser> register(RegisterUserRequest request) async {
    return _http.post<SDKUser>(
      '/users/register',
      body: request.toJson(),
      decoder: (data) => SDKUser.fromJson(data as Map<String, dynamic>),
    );
  }
}
