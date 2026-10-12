/// A comment on a feedback item.
class Comment {
  /// Unique identifier for this comment.
  final String id;

  /// ID of the feedback this comment belongs to.
  ///
  /// Nullable: the server's comment payload does not carry a `feedback_id` key at
  /// all (comments are fetched per feedback, so the association is the request's).
  /// Until 2026-08-15 this was non-nullable and silently resolved to `''` on every
  /// decode (QA-UNIT04-COMMENTS -13, fixed by QA-UNIT10-SDK-PARITY).
  final String? feedbackId;

  /// Content of the comment.
  final String content;

  /// ID of the user who created this comment.
  final String? userId;

  /// Display name of the comment author.
  final String? authorName;

  /// Whether this comment is from a team member.
  final bool isTeamMember;

  /// When this comment was created.
  final DateTime createdAt;

  const Comment({
    required this.id,
    this.feedbackId,
    required this.content,
    this.userId,
    this.authorName,
    this.isTeamMember = false,
    required this.createdAt,
  });

  /// Creates a [Comment] from a JSON map.
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      feedbackId:
          json['feedback_id'] as String? ?? json['feedbackId'] as String?,
      content: json['content'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String?,
      authorName:
          json['author_name'] as String? ?? json['authorName'] as String?,
      // The server's wire key is is_admin (CommentResponseDTO.isAdmin under the global
      // .convertToSnakeCase strategy). This read is_team_member until 2026-08-15, so the
      // admin badge silently never rendered (QA-UNIT04-COMMENTS -13).
      isTeamMember: json['is_admin'] as bool? ??
          json['is_team_member'] as bool? ??
          json['isTeamMember'] as bool? ??
          false,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? json['createdAt'] as String,
      ),
    );
  }

  /// Converts this comment to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (feedbackId != null) 'feedback_id': feedbackId,
      'content': content,
      if (userId != null) 'user_id': userId,
      if (authorName != null) 'author_name': authorName,
      'is_team_member': isTeamMember,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy of this comment with the given fields replaced.
  Comment copyWith({
    String? id,
    String? feedbackId,
    String? content,
    String? userId,
    String? authorName,
    bool? isTeamMember,
    DateTime? createdAt,
  }) {
    return Comment(
      id: id ?? this.id,
      feedbackId: feedbackId ?? this.feedbackId,
      content: content ?? this.content,
      userId: userId ?? this.userId,
      authorName: authorName ?? this.authorName,
      isTeamMember: isTeamMember ?? this.isTeamMember,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Comment &&
        other.id == id &&
        other.feedbackId == feedbackId &&
        other.content == content &&
        other.userId == userId &&
        other.authorName == authorName &&
        other.isTeamMember == isTeamMember;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      feedbackId,
      content,
      userId,
      authorName,
      isTeamMember,
    );
  }

  @override
  String toString() {
    return 'Comment(id: $id, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content})';
  }
}
