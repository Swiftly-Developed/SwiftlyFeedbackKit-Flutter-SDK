import 'package:flutter/painting.dart';

/// Keeps host-chosen status colours legible on the card.
///
/// A host may pick a light status colour, such as mint for every status. The
/// glyph shape still carries the status, and this nudges the colour toward
/// black on a light card or white on a dark one until it reaches the WCAG
/// ratio. A colour that already passes is returned unchanged.
abstract final class ShowcaseContrast {
  /// WCAG minimum for body text.
  static const double text = 4.5;

  /// WCAG minimum for graphics such as the status glyph.
  static const double graphic = 3.0;

  /// The WCAG contrast ratio of [a] against [b], from 1 to 21.
  static double ratio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final lighter = la > lb ? la : lb;
    final darker = la > lb ? lb : la;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// [color] adjusted to reach [minimum] against the opaque [background].
  static Color ensure(Color color, Color background, double minimum) {
    if (ratio(color, background) >= minimum) return color;
    final target = background.computeLuminance() > 0.5
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
    for (var step = 1; step <= 20; step++) {
      final candidate = Color.lerp(color, target, step / 20)!;
      if (ratio(candidate, background) >= minimum) return candidate;
    }
    return target;
  }
}
