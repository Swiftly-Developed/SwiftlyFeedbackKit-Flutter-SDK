import 'package:flutter/material.dart';

import 'showcase_options.dart';
import 'showcase_vote_capsule.dart';
import 'vote_presentation.dart';

/// A loading placeholder with the Showcase card's paddings and line heights,
/// so nothing shifts when the real cards arrive.
class ShowcaseSkeletonCard extends StatelessWidget {
  /// Which parts the real cards will show.
  final ShowcaseOptions options;

  /// Varies the title width so a column of placeholders does not look
  /// stamped.
  final int index;

  const ShowcaseSkeletonCard({
    super.key,
    required this.options,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final scaler = MediaQuery.textScalerOf(context);
    final fill = theme.colorScheme.surfaceContainerHighest;

    Widget bar(TextStyle? style, double widthFactor) {
      final size = style?.fontSize ?? 14;
      final lineHeight = scaler.scale(size) * (style?.height ?? 1.2);
      return SizedBox(
        height: lineHeight,
        child: FractionallySizedBox(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: widthFactor,
          heightFactor: 0.7,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      );
    }

    final titleWidth = const [0.8, 0.6, 0.7][index % 3];
    return ExcludeSemantics(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (options.showStatusBadge) ...[
                bar(text.labelLarge, 0.28),
                const SizedBox(height: 8),
              ],
              bar(text.titleLarge, titleWidth),
              const SizedBox(height: 4),
              bar(text.bodyMedium, 1),
              bar(text.bodyMedium, 0.55),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: bar(text.bodyMedium, 0.45)),
                  ShowcaseVoteCapsule(
                    presentation: VotePresentation.resolve(
                      showVoteCount: options.showVoteCount,
                      isSkeleton: true,
                      canVote: true,
                      hasVoted: false,
                      allowUndoVote: true,
                    ),
                    voteCount: 0,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
