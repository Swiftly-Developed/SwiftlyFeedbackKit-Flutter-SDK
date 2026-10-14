import 'package:flutter/material.dart';

import '../../models/feedback_category.dart';

/// The Material icon for [category] on the Showcase list and in the Sort &
/// Filter sheet.
///
/// Improvement is "tune": adjusting something that exists. It matches the
/// Swift SDK's `slider.horizontal.3` (FEEDBACK01 Q4) and contains no arrow,
/// so it never reads as the upward vote arrow beside it.
IconData showcaseCategoryIcon(FeedbackCategory category) {
  switch (category) {
    case FeedbackCategory.featureRequest:
      return Icons.lightbulb_outline;
    case FeedbackCategory.bugReport:
      return Icons.bug_report_outlined;
    case FeedbackCategory.improvement:
      return Icons.tune;
    case FeedbackCategory.other:
      return Icons.more_horiz;
  }
}
