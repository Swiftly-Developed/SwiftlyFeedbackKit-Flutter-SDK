import 'package:flutter/material.dart';

/// A centred icon, title, optional description and optional action, used for
/// the project-empty, filtered-empty, search-empty and error states.
class ShowcaseMessage extends StatelessWidget {
  /// Decorative icon above the title.
  final IconData icon;

  /// The headline.
  final String title;

  /// Supporting text under the title.
  final String? description;

  /// Label of the tonal action button.
  final String? actionLabel;

  /// Called by the action button.
  final VoidCallback? onAction;

  /// Colours the icon with the scheme's error colour.
  final bool isError;

  const ShowcaseMessage({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(
                icon,
                size: 48,
                applyTextScaling: true,
                color: isError ? scheme.error : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                ),
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
