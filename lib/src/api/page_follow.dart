import 'package:flutter/foundation.dart';

/// The most follow-up requests one list call sends after its first request.
const int maxFollowedPages = 100;

/// Logs that a list stopped early.
///
/// The path and the two page numbers only. Never the query, a key, a user id or
/// a row.
void warnPageFollowStopped(String path, int requested, int? received) {
  debugPrint(
    'FeedbackKit: stopped following pages of $path: '
    'requested page $requested, received page ${received ?? 'missing'}',
  );
}
