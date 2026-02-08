import 'package:flutter/widgets.dart';

import '../models/feedback_category.dart';
import '../models/feedback_status.dart';

/// Colors for each feedback status.
class StatusColors {
  final Color pending;
  final Color approved;
  final Color inProgress;
  final Color testflight;
  final Color completed;
  final Color rejected;

  const StatusColors({
    this.pending = const Color(0xFF6B7280),
    this.approved = const Color(0xFF3B82F6),
    this.inProgress = const Color(0xFFF97316),
    this.testflight = const Color(0xFF06B6D4),
    this.completed = const Color(0xFF22C55E),
    this.rejected = const Color(0xFFEF4444),
  });

  /// Gets the color for a status.
  Color forStatus(FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.pending:
        return pending;
      case FeedbackStatus.approved:
        return approved;
      case FeedbackStatus.inProgress:
        return inProgress;
      case FeedbackStatus.testflight:
        return testflight;
      case FeedbackStatus.completed:
        return completed;
      case FeedbackStatus.rejected:
        return rejected;
    }
  }

  /// Creates a copy with the given colors replaced.
  StatusColors copyWith({
    Color? pending,
    Color? approved,
    Color? inProgress,
    Color? testflight,
    Color? completed,
    Color? rejected,
  }) {
    return StatusColors(
      pending: pending ?? this.pending,
      approved: approved ?? this.approved,
      inProgress: inProgress ?? this.inProgress,
      testflight: testflight ?? this.testflight,
      completed: completed ?? this.completed,
      rejected: rejected ?? this.rejected,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StatusColors &&
        other.pending == pending &&
        other.approved == approved &&
        other.inProgress == inProgress &&
        other.testflight == testflight &&
        other.completed == completed &&
        other.rejected == rejected;
  }

  @override
  int get hashCode {
    return Object.hash(
      pending,
      approved,
      inProgress,
      testflight,
      completed,
      rejected,
    );
  }
}

/// Colors for each feedback category.
class CategoryColors {
  final Color featureRequest;
  final Color bugReport;
  final Color improvement;
  final Color other;

  const CategoryColors({
    this.featureRequest = const Color(0xFF8B5CF6),
    this.bugReport = const Color(0xFFEF4444),
    this.improvement = const Color(0xFF3B82F6),
    this.other = const Color(0xFF6B7280),
  });

  /// Gets the color for a category.
  Color forCategory(FeedbackCategory category) {
    switch (category) {
      case FeedbackCategory.featureRequest:
        return featureRequest;
      case FeedbackCategory.bugReport:
        return bugReport;
      case FeedbackCategory.improvement:
        return improvement;
      case FeedbackCategory.other:
        return other;
    }
  }

  /// Creates a copy with the given colors replaced.
  CategoryColors copyWith({
    Color? featureRequest,
    Color? bugReport,
    Color? improvement,
    Color? other,
  }) {
    return CategoryColors(
      featureRequest: featureRequest ?? this.featureRequest,
      bugReport: bugReport ?? this.bugReport,
      improvement: improvement ?? this.improvement,
      other: other ?? this.other,
    );
  }

  @override
  bool operator ==(Object other_) {
    if (identical(this, other_)) return true;
    return other_ is CategoryColors &&
        other_.featureRequest == featureRequest &&
        other_.bugReport == bugReport &&
        other_.improvement == improvement &&
        other_.other == other;
  }

  @override
  int get hashCode {
    return Object.hash(featureRequest, bugReport, improvement, other);
  }
}

/// Theme configuration for FeedbackKit widgets.
class FeedbackKitTheme {
  /// Primary brand color.
  final Color primaryColor;

  /// Background color for screens.
  final Color backgroundColor;

  /// Background color for cards.
  final Color cardBackgroundColor;

  /// Primary text color.
  final Color textColor;

  /// Secondary text color.
  final Color secondaryTextColor;

  /// Border color for inputs and dividers.
  final Color borderColor;

  /// Color for error states.
  final Color errorColor;

  /// Color for success states.
  final Color successColor;

  /// Colors for each feedback status.
  final StatusColors statusColors;

  /// Colors for each feedback category.
  final CategoryColors categoryColors;

  /// Border radius for cards and buttons.
  final double borderRadius;

  /// Base spacing unit.
  final double spacing;

  const FeedbackKitTheme({
    this.primaryColor = const Color(0xFF3B82F6),
    this.backgroundColor = const Color(0xFFF9FAFB),
    this.cardBackgroundColor = const Color(0xFFFFFFFF),
    this.textColor = const Color(0xFF111827),
    this.secondaryTextColor = const Color(0xFF6B7280),
    this.borderColor = const Color(0xFFE5E7EB),
    this.errorColor = const Color(0xFFEF4444),
    this.successColor = const Color(0xFF22C55E),
    this.statusColors = const StatusColors(),
    this.categoryColors = const CategoryColors(),
    this.borderRadius = 12.0,
    this.spacing = 8.0,
  });

  /// Dark theme preset.
  static const FeedbackKitTheme dark = FeedbackKitTheme(
    primaryColor: Color(0xFF60A5FA),
    backgroundColor: Color(0xFF111827),
    cardBackgroundColor: Color(0xFF1F2937),
    textColor: Color(0xFFF9FAFB),
    secondaryTextColor: Color(0xFF9CA3AF),
    borderColor: Color(0xFF374151),
    errorColor: Color(0xFFF87171),
    successColor: Color(0xFF4ADE80),
  );

  /// Creates a copy with the given properties replaced.
  FeedbackKitTheme copyWith({
    Color? primaryColor,
    Color? backgroundColor,
    Color? cardBackgroundColor,
    Color? textColor,
    Color? secondaryTextColor,
    Color? borderColor,
    Color? errorColor,
    Color? successColor,
    StatusColors? statusColors,
    CategoryColors? categoryColors,
    double? borderRadius,
    double? spacing,
  }) {
    return FeedbackKitTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      cardBackgroundColor: cardBackgroundColor ?? this.cardBackgroundColor,
      textColor: textColor ?? this.textColor,
      secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
      borderColor: borderColor ?? this.borderColor,
      errorColor: errorColor ?? this.errorColor,
      successColor: successColor ?? this.successColor,
      statusColors: statusColors ?? this.statusColors,
      categoryColors: categoryColors ?? this.categoryColors,
      borderRadius: borderRadius ?? this.borderRadius,
      spacing: spacing ?? this.spacing,
    );
  }

  /// Merges this theme with overrides.
  FeedbackKitTheme merge(FeedbackKitTheme? other) {
    if (other == null) return this;
    return copyWith(
      primaryColor: other.primaryColor,
      backgroundColor: other.backgroundColor,
      cardBackgroundColor: other.cardBackgroundColor,
      textColor: other.textColor,
      secondaryTextColor: other.secondaryTextColor,
      borderColor: other.borderColor,
      errorColor: other.errorColor,
      successColor: other.successColor,
      statusColors: other.statusColors,
      categoryColors: other.categoryColors,
      borderRadius: other.borderRadius,
      spacing: other.spacing,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeedbackKitTheme &&
        other.primaryColor == primaryColor &&
        other.backgroundColor == backgroundColor &&
        other.cardBackgroundColor == cardBackgroundColor &&
        other.textColor == textColor &&
        other.secondaryTextColor == secondaryTextColor &&
        other.borderColor == borderColor &&
        other.errorColor == errorColor &&
        other.successColor == successColor &&
        other.statusColors == statusColors &&
        other.categoryColors == categoryColors &&
        other.borderRadius == borderRadius &&
        other.spacing == spacing;
  }

  @override
  int get hashCode {
    return Object.hash(
      primaryColor,
      backgroundColor,
      cardBackgroundColor,
      textColor,
      secondaryTextColor,
      borderColor,
      errorColor,
      successColor,
      statusColors,
      categoryColors,
      borderRadius,
      spacing,
    );
  }
}
