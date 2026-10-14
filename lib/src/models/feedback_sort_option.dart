import '../i18n/feedbackkit_localizations.dart';
import 'feedback.dart' show FeedbackItem;

/// Sort orders offered by the feedback list's Sort & Filter sheet.
///
/// The four cases match the Swift SDK's `FeedbackSortOption` and the JS SDK's
/// `FeedbackSort`, so the six SDKs offer the same choices.
enum FeedbackSortOption {
  /// Most votes first. The default.
  votes,

  /// Most recently created first.
  newest,

  /// Least recently created first.
  oldest,

  /// Most comments first.
  comments;

  /// Localized name shown in the Sort & Filter sheet.
  String get displayName {
    switch (this) {
      case FeedbackSortOption.votes:
        return FeedbackKitLocalizations.t('sort.votes');
      case FeedbackSortOption.newest:
        return FeedbackKitLocalizations.t('sort.newest');
      case FeedbackSortOption.oldest:
        return FeedbackKitLocalizations.t('sort.oldest');
      case FeedbackSortOption.comments:
        return FeedbackKitLocalizations.t('sort.comments');
    }
  }

  /// Orders [a] against [b]. Ties fall back to newest first, then to id, so
  /// the order is stable across reloads.
  int compare(FeedbackItem a, FeedbackItem b) {
    final int primary;
    switch (this) {
      case FeedbackSortOption.votes:
        primary = b.voteCount.compareTo(a.voteCount);
      case FeedbackSortOption.newest:
        primary = b.createdAt.compareTo(a.createdAt);
      case FeedbackSortOption.oldest:
        primary = a.createdAt.compareTo(b.createdAt);
      case FeedbackSortOption.comments:
        primary = b.commentCount.compareTo(a.commentCount);
    }
    if (primary != 0) return primary;
    final byDate = b.createdAt.compareTo(a.createdAt);
    if (byDate != 0) return byDate;
    return a.id.compareTo(b.id);
  }

  /// Parses a value written by [name]. Returns null for anything else.
  static FeedbackSortOption? fromName(String? value) {
    for (final option in FeedbackSortOption.values) {
      if (option.name == value) return option;
    }
    return null;
  }
}
