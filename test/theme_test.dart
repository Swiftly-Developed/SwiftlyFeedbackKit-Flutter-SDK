import 'package:feedbackkit_flutter/feedbackkit_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeedbackKitTheme', () {
    test('default theme has expected values', () {
      const theme = FeedbackKitTheme();

      expect(theme.primaryColor, const Color(0xFF3B82F6));
      expect(theme.backgroundColor, const Color(0xFFF9FAFB));
      expect(theme.borderRadius, 12.0);
      expect(theme.spacing, 8.0);
    });

    test('dark theme has expected values', () {
      const theme = FeedbackKitTheme.dark;

      expect(theme.primaryColor, const Color(0xFF60A5FA));
      expect(theme.backgroundColor, const Color(0xFF111827));
      expect(theme.textColor, const Color(0xFFF9FAFB));
    });

    test('copyWith creates modified copy', () {
      const theme = FeedbackKitTheme();
      final modified = theme.copyWith(
        primaryColor: const Color(0xFF6366F1),
        borderRadius: 16.0,
      );

      expect(modified.primaryColor, const Color(0xFF6366F1));
      expect(modified.borderRadius, 16.0);
      expect(modified.backgroundColor, theme.backgroundColor);
    });
  });

  group('StatusColors', () {
    test('forStatus returns correct colors', () {
      const colors = StatusColors();

      expect(colors.forStatus(FeedbackStatus.pending), colors.pending);
      expect(colors.forStatus(FeedbackStatus.approved), colors.approved);
      expect(colors.forStatus(FeedbackStatus.inProgress), colors.inProgress);
      expect(colors.forStatus(FeedbackStatus.testflight), colors.testflight);
      expect(colors.forStatus(FeedbackStatus.completed), colors.completed);
      expect(colors.forStatus(FeedbackStatus.rejected), colors.rejected);
    });

    test('default colors match spec', () {
      const colors = StatusColors();

      expect(colors.pending, const Color(0xFF6B7280)); // Gray
      expect(colors.approved, const Color(0xFF3B82F6)); // Blue
      expect(colors.inProgress, const Color(0xFFF97316)); // Orange
      expect(colors.testflight, const Color(0xFF06B6D4)); // Cyan
      expect(colors.completed, const Color(0xFF22C55E)); // Green
      expect(colors.rejected, const Color(0xFFEF4444)); // Red
    });
  });

  group('CategoryColors', () {
    test('forCategory returns correct colors', () {
      const colors = CategoryColors();

      expect(colors.forCategory(FeedbackCategory.featureRequest),
          colors.featureRequest);
      expect(
          colors.forCategory(FeedbackCategory.bugReport), colors.bugReport);
      expect(colors.forCategory(FeedbackCategory.improvement),
          colors.improvement);
      expect(colors.forCategory(FeedbackCategory.other), colors.other);
    });

    test('default colors match spec', () {
      const colors = CategoryColors();

      expect(colors.featureRequest, const Color(0xFF8B5CF6)); // Purple
      expect(colors.bugReport, const Color(0xFFEF4444)); // Red
      expect(colors.improvement, const Color(0xFF3B82F6)); // Blue
      expect(colors.other, const Color(0xFF6B7280)); // Gray
    });
  });
}
