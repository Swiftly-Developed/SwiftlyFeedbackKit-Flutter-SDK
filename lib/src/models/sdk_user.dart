// ignore_for_file: deprecated_member_use_from_same_package

/// A user registered with the SDK, as `POST /users/register` returns it.
class SDKUser {
  /// Server row identifier for this user.
  final String id;

  /// The identifier the host registered. Null only on a response from a server
  /// older than this field.
  final String? userId;

  /// Monthly recurring revenue the server stored, when one was sent.
  final double? mrr;

  /// When the server first saw this user.
  final DateTime? firstSeenAt;

  /// When the server last saw this user.
  final DateTime? lastSeenAt;

  /// Email address of the user.
  @Deprecated('The server does not return an email. This is null on every response.')
  final String? email;

  /// Display name of the user.
  @Deprecated('The server does not return a name. This is null on every response.')
  final String? name;

  /// When this user was created.
  @Deprecated('The server does not return created_at. Read firstSeenAt.')
  final DateTime? createdAt;

  const SDKUser({
    required this.id,
    this.userId,
    this.mrr,
    this.firstSeenAt,
    this.lastSeenAt,
    @Deprecated('The server does not return an email.') this.email,
    @Deprecated('The server does not return a name.') this.name,
    @Deprecated('The server does not return created_at. Pass firstSeenAt.') this.createdAt,
  });

  /// Creates an [SDKUser] from a JSON map.
  factory SDKUser.fromJson(Map<String, dynamic> json) {
    final createdAtStr =
        json['created_at'] as String? ?? json['createdAt'] as String?;
    return SDKUser(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String?,
      mrr: (json['mrr'] as num?)?.toDouble(),
      firstSeenAt: _date(json['first_seen_at'] ?? json['firstSeenAt']),
      lastSeenAt: _date(json['last_seen_at'] ?? json['lastSeenAt']),
      email: json['email'] as String?,
      name: json['name'] as String?,
      createdAt: createdAtStr != null ? DateTime.parse(createdAtStr) : null,
    );
  }

  static DateTime? _date(Object? value) {
    return value is String ? DateTime.parse(value) : null;
  }

  /// Converts this user to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      if (mrr != null) 'mrr': mrr,
      if (firstSeenAt != null) 'first_seen_at': firstSeenAt!.toIso8601String(),
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt!.toIso8601String(),
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  /// Creates a copy of this user with the given fields replaced.
  SDKUser copyWith({
    String? id,
    String? userId,
    double? mrr,
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
    String? email,
    String? name,
    DateTime? createdAt,
  }) {
    return SDKUser(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mrr: mrr ?? this.mrr,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SDKUser &&
        other.id == id &&
        other.userId == userId &&
        other.mrr == mrr &&
        other.firstSeenAt == firstSeenAt &&
        other.lastSeenAt == lastSeenAt &&
        other.email == email &&
        other.name == name;
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, mrr, firstSeenAt, lastSeenAt, email, name);

  @override
  String toString() {
    return 'SDKUser(id: $id, userId: $userId, mrr: $mrr)';
  }
}
