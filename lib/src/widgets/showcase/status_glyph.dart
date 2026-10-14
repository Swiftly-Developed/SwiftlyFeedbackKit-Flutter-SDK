import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../models/feedback_status.dart';
import 'status_glyph_shape.dart';

/// A small ring that shows a status by shape as well as colour. Decorative:
/// the status name beside it carries the meaning for accessibility.
class StatusGlyph extends StatelessWidget {
  /// The status to draw.
  final FeedbackStatus status;

  /// The ring's colour.
  final Color color;

  /// Width and height in logical pixels.
  final double size;

  const StatusGlyph({
    super.key,
    required this.status,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _StatusGlyphPainter(StatusGlyphShape.of(status), color),
      ),
    );
  }
}

class _StatusGlyphPainter extends CustomPainter {
  final StatusGlyphShape shape;
  final Color color;

  _StatusGlyphPainter(this.shape, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final center = size.center(Offset.zero);
    final line = math.max(1.5, side * 0.12);
    final ringRadius = (side - line) / 2;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = line;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (shape) {
      case StatusGlyphShape.dashedRing:
        const dashes = 8;
        const sweep = 2 * math.pi / dashes;
        final rect = Rect.fromCircle(center: center, radius: ringRadius);
        for (var i = 0; i < dashes; i++) {
          canvas.drawArc(rect, -math.pi / 2 + i * sweep, sweep * 0.55, false,
              stroke..strokeCap = StrokeCap.butt,);
        }
      case StatusGlyphShape.ring:
        canvas.drawCircle(center, ringRadius, stroke);
      case StatusGlyphShape.halfRing:
      case StatusGlyphShape.threeQuarterRing:
        canvas.drawCircle(center, ringRadius, stroke);
        final pieRadius = ringRadius - line * 1.5;
        final fraction = shape == StatusGlyphShape.halfRing ? 0.5 : 0.75;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: pieRadius),
          -math.pi / 2,
          2 * math.pi * fraction,
          true,
          fill,
        );
      case StatusGlyphShape.check:
      case StatusGlyphShape.cross:
        canvas.drawCircle(center, side / 2, fill);
        final mark = Paint()
          ..color = _markColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.5, side * 0.14)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        final u = side * 0.23;
        if (shape == StatusGlyphShape.check) {
          final path = Path()
            ..moveTo(center.dx - u, center.dy + u * 0.05)
            ..lineTo(center.dx - u * 0.3, center.dy + u * 0.75)
            ..lineTo(center.dx + u * 1.05, center.dy - u * 0.7);
          canvas.drawPath(path, mark);
        } else {
          canvas.drawLine(center.translate(-u, -u), center.translate(u, u), mark);
          canvas.drawLine(center.translate(u, -u), center.translate(-u, u), mark);
        }
    }
  }

  /// White on a dark disc, near-black on a light one.
  Color get _markColor => color.computeLuminance() > 0.45
      ? const Color(0xFF1B1B1F)
      : const Color(0xFFFFFFFF);

  @override
  bool shouldRepaint(_StatusGlyphPainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.color != color;
}
