/// Category of a feedback item.
enum FeedbackCategory {
  featureRequest,
  bugReport,
  improvement,
  other;

  /// Creates a [FeedbackCategory] from a JSON string value.
  static FeedbackCategory fromJson(String value) {
    switch (value) {
      case 'feature_request':
        return FeedbackCategory.featureRequest;
      case 'bug_report':
        return FeedbackCategory.bugReport;
      case 'improvement':
        return FeedbackCategory.improvement;
      case 'other':
        return FeedbackCategory.other;
      default:
        return FeedbackCategory.other;
    }
  }

  /// Converts this category to its JSON string representation.
  String toJson() {
    switch (this) {
      case FeedbackCategory.featureRequest:
        return 'feature_request';
      case FeedbackCategory.bugReport:
        return 'bug_report';
      case FeedbackCategory.improvement:
        return 'improvement';
      case FeedbackCategory.other:
        return 'other';
    }
  }

  /// Returns the display name for this category.
  String get displayName {
    switch (this) {
      case FeedbackCategory.featureRequest:
        return 'Feature Request';
      case FeedbackCategory.bugReport:
        return 'Bug Report';
      case FeedbackCategory.improvement:
        return 'Improvement';
      case FeedbackCategory.other:
        return 'Other';
    }
  }
}
