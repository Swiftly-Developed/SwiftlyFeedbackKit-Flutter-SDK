import 'feedback_category.dart';
import 'feedback_status.dart';

/// A feedback item submitted by a user.
class FeedbackItem {
  /// Unique identifier for this feedback.
  final String id;

  /// Title of the feedback.
  final String title;

  /// Detailed description of the feedback.
  final String description;

  /// Current status of the feedback.
  final FeedbackStatus status;

  /// Category of the feedback.
  final FeedbackCategory category;

  /// Number of votes this feedback has received.
  final int voteCount;

  /// Whether the current user has voted for this feedback.
  final bool hasVoted;

  /// Number of comments on this feedback.
  final int commentCount;

  /// ID of the user who submitted this feedback.
  final String? userId;

  /// When this feedback was created.
  final DateTime createdAt;

  /// When this feedback was last updated.
  final DateTime updatedAt;

  const FeedbackItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.category,
    required this.voteCount,
    required this.hasVoted,
    required this.commentCount,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [FeedbackItem] from a JSON map.
  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    return FeedbackItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: FeedbackStatus.fromJson(json['status'] as String),
      category: FeedbackCategory.fromJson(json['category'] as String),
      voteCount: json['vote_count'] as int? ?? json['voteCount'] as int? ?? 0,
      hasVoted: json['has_voted'] as bool? ?? json['hasVoted'] as bool? ?? false,
      commentCount:
          json['comment_count'] as int? ?? json['commentCount'] as int? ?? 0,
      userId: json['user_id'] as String? ?? json['userId'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String? ?? json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String? ?? json['updatedAt'] as String),
    );
  }

  /// Converts this feedback to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.toJson(),
      'category': category.toJson(),
      'vote_count': voteCount,
      'has_voted': hasVoted,
      'comment_count': commentCount,
      if (userId != null) 'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Creates a copy of this feedback with the given fields replaced.
  FeedbackItem copyWith({
    String? id,
    String? title,
    String? description,
    FeedbackStatus? status,
    FeedbackCategory? category,
    int? voteCount,
    bool? hasVoted,
    int? commentCount,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FeedbackItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      category: category ?? this.category,
      voteCount: voteCount ?? this.voteCount,
      hasVoted: hasVoted ?? this.hasVoted,
      commentCount: commentCount ?? this.commentCount,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeedbackItem &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.status == status &&
        other.category == category &&
        other.voteCount == voteCount &&
        other.hasVoted == hasVoted &&
        other.commentCount == commentCount &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      status,
      category,
      voteCount,
      hasVoted,
      commentCount,
      userId,
    );
  }

  @override
  String toString() {
    return 'FeedbackItem(id: $id, title: $title, status: $status, category: $category)';
  }
}
