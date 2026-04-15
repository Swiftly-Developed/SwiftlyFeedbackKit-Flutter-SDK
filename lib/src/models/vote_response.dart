/// Response from a vote or unvote operation.
class VoteResponse {
  /// Whether the vote/unvote operation was successful.
  final bool success;

  /// Updated vote count for the feedback.
  final int voteCount;

  /// Whether the current user has voted after this operation.
  final bool hasVoted;

  const VoteResponse({
    required this.success,
    required this.voteCount,
    required this.hasVoted,
  });

  /// Creates a [VoteResponse] from a JSON map.
  factory VoteResponse.fromJson(Map<String, dynamic> json) {
    return VoteResponse(
      success: json['success'] as bool? ?? true,
      voteCount: json['vote_count'] as int? ?? json['voteCount'] as int? ?? 0,
      hasVoted:
          json['has_voted'] as bool? ?? json['hasVoted'] as bool? ?? false,
    );
  }

  /// Converts this response to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'vote_count': voteCount,
      'has_voted': hasVoted,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VoteResponse &&
        other.success == success &&
        other.voteCount == voteCount &&
        other.hasVoted == hasVoted;
  }

  @override
  int get hashCode => Object.hash(success, voteCount, hasVoted);

  @override
  String toString() {
    return 'VoteResponse(success: $success, voteCount: $voteCount, hasVoted: $hasVoted)';
  }
}
