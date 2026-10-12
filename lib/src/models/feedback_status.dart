import '../i18n/feedbackkit_localizations.dart';
import 'unknown_enum_value_exception.dart';

/// Status of a feedback item.
enum FeedbackStatus {
  pending,
  approved,
  inProgress,
  testflight,
  completed,
  rejected;

  /// Creates a [FeedbackStatus] from a JSON string value.
  ///
  /// Throws [UnknownEnumValueException] for a token this SDK version does not
  /// know. Until 2026-08-15 the default arm instead coerced every unknown token
  /// to [pending] — the sentinel mapping `AGENTS.md` forbids (finding F6): a
  /// seventh server status rendered as "Pending" and stayed votable against a
  /// status the server refuses. List decodes tolerate the throw per element and
  /// drop only that row (see `FeedbackApi.list`).
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
        throw UnknownEnumValueException('FeedbackStatus', value);
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

  /// Returns the localized display name for this status.
  String get displayName {
    switch (this) {
      case FeedbackStatus.pending:
        return FeedbackKitLocalizations.t('status.pending');
      case FeedbackStatus.approved:
        return FeedbackKitLocalizations.t('status.approved');
      case FeedbackStatus.inProgress:
        return FeedbackKitLocalizations.t('status.inProgress');
      case FeedbackStatus.testflight:
        return FeedbackKitLocalizations.t('status.testflight');
      case FeedbackStatus.completed:
        return FeedbackKitLocalizations.t('status.completed');
      case FeedbackStatus.rejected:
        return FeedbackKitLocalizations.t('status.rejected');
    }
  }

  /// Returns whether voting is allowed for this status.
  bool get canVote {
    return this != FeedbackStatus.completed && this != FeedbackStatus.rejected;
  }
}
