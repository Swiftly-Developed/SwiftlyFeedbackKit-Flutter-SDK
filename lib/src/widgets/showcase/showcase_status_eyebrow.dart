import 'package:flutter/material.dart';

import '../../models/feedback_status.dart';
import 'status_glyph.dart';

/// The status line at the top of a Showcase card: a glyph and the status
/// name. The glyph scales with the text and sits on its centre line.
class ShowcaseStatusEyebrow extends StatelessWidget {
  /// The status shown.
  final FeedbackStatus status;

  /// Colour of the glyph.
  final Color glyphColor;

  /// Colour of the status name.
  final Color textColor;

  const ShowcaseStatusEyebrow({
    super.key,
    required this.status,
    required this.glyphColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        );
    final fontSize = style?.fontSize ?? 14;
    final glyphSize = MediaQuery.textScalerOf(context).scale(fontSize) * 0.9;
    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: StatusGlyph(
              status: status,
              color: glyphColor,
              size: glyphSize,
            ),
          ),
          const TextSpan(text: '\u2002'),
          TextSpan(text: status.displayName),
        ],
      ),
      style: style,
    );
  }
}
