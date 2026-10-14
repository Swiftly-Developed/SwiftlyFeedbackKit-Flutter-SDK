import 'package:flutter/foundation.dart';

import '../../i18n/feedbackkit_localizations.dart';

/// The two ways a platform's screen reader takes a tap hint.
///
/// VoiceOver reads [hint] whole ("Double tap to vote"). TalkBack builds its
/// own "Double tap to …" phrase from [onTapHint], so giving it the full hint
/// as well would speak the instruction twice. A control with no tap action
/// gets the full sentence as [hint] on every platform.
typedef SemanticsHints = ({String? hint, String? onTapHint});

/// Resolves catalog keys into the hint pair for the current platform.
SemanticsHints resolveSemanticsHints({
  required String? hintKey,
  String? tapHintKey,
}) {
  if (hintKey == null) return (hint: null, onTapHint: null);
  final apple = defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
  if (apple || tapHintKey == null) {
    return (hint: FeedbackKitLocalizations.t(hintKey), onTapHint: null);
  }
  return (hint: null, onTapHint: FeedbackKitLocalizations.t(tapHintKey));
}
