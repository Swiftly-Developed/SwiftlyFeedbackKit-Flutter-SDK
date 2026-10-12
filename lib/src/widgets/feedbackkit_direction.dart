import 'package:flutter/widgets.dart';

import '../i18n/feedbackkit_localizations.dart';

/// Applies the FeedbackKit locale's layout direction to [child].
class FeedbackKitDirection extends StatelessWidget {
  /// The subtree that should follow the FeedbackKit locale.
  final Widget child;

  const FeedbackKitDirection({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: FeedbackKitLocalizations.textDirection,
      child: child,
    );
  }
}
