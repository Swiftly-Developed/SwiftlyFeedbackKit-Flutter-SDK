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
  factory TrackedEvent.fromJson(Map<String, dynamic> json) {
    final timestampStr = json['timestamp'] as String?;
    return TrackedEvent(
      name: json['name'] as String,
      properties: json['properties'] as Map<String, dynamic>?,
      timestamp: timestampStr != null ? DateTime.parse(timestampStr) : null,
    );
  }

  /// Converts this event to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (properties != null) 'properties': properties,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    };
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
