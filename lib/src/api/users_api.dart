import '../http/http_client.dart';
import '../models/sdk_user.dart';

/// Request object for registering a user.
class RegisterUserRequest {
  /// Unique identifier for the user.
  final String id;

  /// Email address of the user.
  final String? email;

  /// Display name of the user.
  final String? name;

  const RegisterUserRequest({
    required this.id,
    this.email,
    this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
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
