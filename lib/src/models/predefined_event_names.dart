/// FeedbackKit's own three predefined event names.
///
/// These are the events every plan can read. A Free-tier metrics read is scoped
/// to exactly these three — the response comes back `200` with
/// `meta.eventScope == MetricEventScope.predefinedOnly` — while a customer's own
/// event names are still ingested and retained, and become readable on upgrade
/// with no re-tracking.
///
/// The spellings are **exact and case-sensitive**: `FeedbackList` or
/// `feedback-list` is a *custom* event and lands on the paid side of that scope.
/// Spell them from here rather than by hand.
abstract final class PredefinedEventNames {
  /// The event the feedback list view tracks.
  static const String feedbackList = 'feedback_list';

  /// The event the feedback detail view tracks.
  static const String feedbackDetail = 'feedback_detail';

  /// The event the submit-feedback view tracks.
  static const String submitFeedback = 'submit_feedback';

  /// All three, in the order the contract lists them.
  static const List<String> all = [
    feedbackList,
    feedbackDetail,
    submitFeedback,
  ];
}
