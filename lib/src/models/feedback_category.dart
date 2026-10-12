import '../i18n/feedbackkit_localizations.dart';
import 'unknown_enum_value_exception.dart';

/// Category of a feedback item.
enum FeedbackCategory {
  featureRequest,
  bugReport,
  improvement,
  other;

  /// Creates a [FeedbackCategory] from a JSON string value.
  ///
  /// Throws [UnknownEnumValueException] for a token this SDK version does not
  /// know. Until 2026-08-15 the default arm instead coerced every unknown token
  /// to [other] — the same sentinel mapping as `FeedbackStatus` carried (finding
  /// F6, two enums wide). List decodes tolerate the throw per element and drop
  /// only that row (see `FeedbackApi.list`).
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
        throw UnknownEnumValueException('FeedbackCategory', value);
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

  /// Returns the localized display name for this category.
  String get displayName {
    switch (this) {
      case FeedbackCategory.featureRequest:
        return FeedbackKitLocalizations.t('category.featureRequest');
      case FeedbackCategory.bugReport:
        return FeedbackKitLocalizations.t('category.bugReport');
      case FeedbackCategory.improvement:
        return FeedbackKitLocalizations.t('category.improvement');
      case FeedbackCategory.other:
        return FeedbackKitLocalizations.t('category.other');
    }
  }
}
