/// An event tracked by the SDK for analytics.
class TrackedEvent {
  /// Name of the event.
  final String name;

  /// Additional properties associated with the event.
  final Map<String, dynamic>? properties;

  /// When this event occurred.
  final DateTime? timestamp;

  const TrackedEvent({
    required this.name,
    this.properties,
    this.timestamp,
  });

  /// Creates a [TrackedEvent] from a JSON map.
  ///
  /// The server sends `event_name` and `created_at`. `name` and `timestamp`
  /// are accepted so a map this SDK used to build still decodes.
  factory TrackedEvent.fromJson(Map<String, dynamic> json) {
    final name = json['event_name'] as String? ?? json['name'] as String?;
    if (name == null) {
      throw const FormatException('TrackedEvent requires event_name.');
    }
    final timestampStr = json['created_at'] as String? ??
        json['createdAt'] as String? ??
        json['timestamp'] as String?;
    return TrackedEvent(
      name: name,
      properties: _readProperties(json['properties']),
      timestamp: timestampStr != null ? DateTime.parse(timestampStr) : null,
    );
  }

  /// Converts this event to the JSON the track route accepts.
  ///
  /// Keys are `event_name` and `properties`. `user_id` is added by the events
  /// API because it comes from the client, not the event.
  /// Numeric and boolean property values are written as strings: the server
  /// stores properties as a string map.
  Map<String, dynamic> toJson() {
    return {
      'event_name': name,
      if (properties != null) 'properties': _stringProperties(properties!),
    };
  }

  static Map<String, dynamic>? _readProperties(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map) {
      throw const FormatException('TrackedEvent properties must be an object.');
    }
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }

  static Map<String, String> _stringProperties(
    Map<String, dynamic> properties,
  ) {
    final encoded = <String, String>{};
    for (final entry in properties.entries) {
      final value = entry.value;
      if (value is String) {
        encoded[entry.key] = value;
      } else if (value is num || value is bool) {
        encoded[entry.key] = '$value';
      } else {
        throw FormatException(
          'Event property "${entry.key}" must be a string, number, or boolean.',
        );
      }
    }
    return encoded;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrackedEvent &&
        other.name == name &&
        _mapEquals(other.properties, properties);
  }

  static bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(name, properties);

  @override
  String toString() {
    return 'TrackedEvent(name: $name, properties: $properties)';
  }
}
