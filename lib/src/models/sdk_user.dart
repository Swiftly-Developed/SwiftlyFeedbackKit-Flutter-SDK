/// A user registered with the SDK.
class SDKUser {
  /// Unique identifier for this user.
  final String id;

  /// Email address of the user.
  final String? email;

  /// Display name of the user.
  final String? name;

  /// When this user was created.
  final DateTime? createdAt;

  const SDKUser({
    required this.id,
    this.email,
    this.name,
    this.createdAt,
  });

  /// Creates an [SDKUser] from a JSON map.
  factory SDKUser.fromJson(Map<String, dynamic> json) {
    final createdAtStr =
        json['created_at'] as String? ?? json['createdAt'] as String?;
    return SDKUser(
      id: json['id'] as String,
      email: json['email'] as String?,
      name: json['name'] as String?,
      createdAt: createdAtStr != null ? DateTime.parse(createdAtStr) : null,
    );
  }

  /// Converts this user to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  /// Creates a copy of this user with the given fields replaced.
  SDKUser copyWith({
    String? id,
    String? email,
    String? name,
    DateTime? createdAt,
  }) {
    return SDKUser(
      id: id ?? this.id,
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
        other.email == email &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, email, name);

  @override
  String toString() {
    return 'SDKUser(id: $id, email: $email, name: $name)';
  }
}
