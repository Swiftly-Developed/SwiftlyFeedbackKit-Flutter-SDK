import '../../models/feedback_status.dart';

/// The shape that marks a status in the Showcase eyebrow, so status never
/// depends on colour alone.
enum StatusGlyphShape {
  /// A dashed ring: pending.
  dashedRing,

  /// An empty ring: approved.
  ring,

  /// A ring half filled: in progress.
  halfRing,

  /// A ring three-quarters filled: TestFlight.
  threeQuarterRing,

  /// A filled disc with a check: completed.
  check,

  /// A filled disc with a cross: rejected.
  cross;

  /// The shape for [status]. Six statuses, six shapes.
  static StatusGlyphShape of(FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.pending:
        return StatusGlyphShape.dashedRing;
      case FeedbackStatus.approved:
        return StatusGlyphShape.ring;
      case FeedbackStatus.inProgress:
        return StatusGlyphShape.halfRing;
      case FeedbackStatus.testflight:
        return StatusGlyphShape.threeQuarterRing;
      case FeedbackStatus.completed:
        return StatusGlyphShape.check;
      case FeedbackStatus.rejected:
        return StatusGlyphShape.cross;
    }
  }
}
