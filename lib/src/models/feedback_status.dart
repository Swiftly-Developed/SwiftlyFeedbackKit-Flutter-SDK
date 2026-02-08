/// Status of a feedback item.
enum FeedbackStatus {
  pending,
  approved,
  inProgress,
  testflight,
  completed,
  rejected;

  /// Creates a [FeedbackStatus] from a JSON string value.
  static FeedbackStatus fromJson(String value) {
    switch (value) {
      case 'pending':
        return FeedbackStatus.pending;
      case 'approved':
        return FeedbackStatus.approved;
      case 'in_progress':
        return FeedbackStatus.inProgress;
      case 'testflight':
        return FeedbackStatus.testflight;
      case 'completed':
        return FeedbackStatus.completed;
      case 'rejected':
        return FeedbackStatus.rejected;
      default:
        return FeedbackStatus.pending;
    }
  }

  /// Converts this status to its JSON string representation.
  String toJson() {
    switch (this) {
      case FeedbackStatus.pending:
        return 'pending';
      case FeedbackStatus.approved:
        return 'approved';
      case FeedbackStatus.inProgress:
        return 'in_progress';
      case FeedbackStatus.testflight:
        return 'testflight';
      case FeedbackStatus.completed:
        return 'completed';
      case FeedbackStatus.rejected:
        return 'rejected';
    }
  }

  /// Returns the display name for this status.
  String get displayName {
    switch (this) {
      case FeedbackStatus.pending:
        return 'Pending';
      case FeedbackStatus.approved:
        return 'Approved';
      case FeedbackStatus.inProgress:
        return 'In Progress';
      case FeedbackStatus.testflight:
        return 'TestFlight';
      case FeedbackStatus.completed:
        return 'Completed';
      case FeedbackStatus.rejected:
        return 'Rejected';
    }
  }

  /// Returns whether voting is allowed for this status.
  bool get canVote {
    return this != FeedbackStatus.completed && this != FeedbackStatus.rejected;
  }
}
