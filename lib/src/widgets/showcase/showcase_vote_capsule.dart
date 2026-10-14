import 'package:flutter/material.dart';

import '../../i18n/feedbackkit_localizations.dart';
import 'semantics_hints.dart';
import 'vote_presentation.dart';

/// The vote control at the trailing end of a Showcase card's footer.
///
/// Tonal when the reader has not voted, filled when they have, and plain
/// text on a completed or rejected request. The touch target is at least
/// 48 by 48 at every text size.
class ShowcaseVoteCapsule extends StatelessWidget {
  /// Which of the six renderings to draw.
  final VotePresentation presentation;

  /// The count shown and spoken.
  final int voteCount;

  /// Called on tap when [presentation] is interactive.
  final VoidCallback? onPressed;

  const ShowcaseVoteCapsule({
    super.key,
    required this.presentation,
    required this.voteCount,
    this.onPressed,
  });

  // Fixed rather than Material's text-scaled padding, which shrinks the
  // sides and leaves no room above and below the count at large sizes. At
  // the default size the 40dp minimum height still decides.
  static const _padding = EdgeInsetsDirectional.fromSTEB(16, 8, 20, 8);

  @override
  Widget build(BuildContext context) {
    if (presentation == VotePresentation.hidden) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final countStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final count = Text(FeedbackKitLocalizations.formatCount(voteCount));
    const icon = Icon(Icons.arrow_upward, size: 18, applyTextScaling: true);
    final label =
        FeedbackKitLocalizations.plural('accessibility.vote.count', voteCount);
    final valueKey = presentation.semanticsValueKey;
    final value = valueKey == null ? null : FeedbackKitLocalizations.t(valueKey);

    switch (presentation) {
      case VotePresentation.hidden:
        return const SizedBox.shrink();

      case VotePresentation.skeleton:
        return ExcludeSemantics(
          child: IgnorePointer(
            child: FilledButton.tonalIcon(
              onPressed: null,
              style: FilledButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.padded,
                textStyle: countStyle,
                padding: _padding,
                disabledBackgroundColor: scheme.surfaceContainerHighest,
                disabledForegroundColor: Colors.transparent,
                disabledIconColor: Colors.transparent,
              ),
              icon: icon,
              label: const Text('000'),
            ),
          ),
        );

      case VotePresentation.closed:
        return Semantics(
          container: true,
          label: label,
          value: value,
          child: ExcludeSemantics(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: IconTheme.merge(
                  data: IconThemeData(color: scheme.onSurfaceVariant),
                  child: DefaultTextStyle.merge(
                    style: countStyle?.copyWith(color: scheme.onSurfaceVariant),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [icon, const SizedBox(width: 6), count],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

      case VotePresentation.votable:
      case VotePresentation.voted:
      case VotePresentation.votedLocked:
        final interactive = presentation.isInteractive;
        final tap = interactive ? onPressed : null;
        final Widget button;
        if (presentation.isFilled) {
          button = FilledButton.icon(
            onPressed: tap,
            style: FilledButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.padded,
              textStyle: countStyle,
              padding: _padding,
              // Locked still reads as voted, not as unavailable.
              disabledBackgroundColor: scheme.primary,
              disabledForegroundColor: scheme.onPrimary,
              disabledIconColor: scheme.onPrimary,
            ),
            icon: icon,
            label: count,
          );
        } else {
          button = FilledButton.tonalIcon(
            onPressed: tap,
            style: FilledButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.padded,
              textStyle: countStyle,
              padding: _padding,
            ),
            icon: icon,
            label: count,
          );
        }
        final hints = resolveSemanticsHints(
          hintKey: presentation.hintKey,
          tapHintKey: presentation.tapHintKey,
        );
        return Semantics(
          container: true,
          button: true,
          enabled: interactive,
          label: label,
          value: value,
          hint: hints.hint,
          onTapHint: hints.onTapHint,
          onTap: tap,
          child: ExcludeSemantics(child: button),
        );
    }
  }
}
