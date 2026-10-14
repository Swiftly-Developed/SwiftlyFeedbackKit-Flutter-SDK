import 'dart:convert';
import 'dart:io';

import 'package:feedbackkit_flutter/feedbackkit_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// End-to-end against a server started by `FeedbackListLiveServerTests`.
/// Skips when that harness has not exported the live URL.
void main() {
  final base = Platform.environment['FEEDBACKKIT_LIVE_BASE_URL'];
  final apiKey = Platform.environment['FEEDBACKKIT_LIVE_API_KEY'];
  final visibleCount =
      int.tryParse(Platform.environment['FEEDBACKKIT_LIVE_FEEDBACK_COUNT'] ?? '') ??
          0;
  final commentId = Platform.environment['FEEDBACKKIT_LIVE_COMMENT_FEEDBACK_ID'];
  final commentCount =
      int.tryParse(Platform.environment['FEEDBACKKIT_LIVE_COMMENT_COUNT'] ?? '') ??
          0;

  test('Flutter client reads the envelope and a legacy array', () async {
    if (base == null || apiKey == null || commentId == null) return;

    final kit = FeedbackKit.configure(apiKey: apiKey, baseUrl: base, userId: 'reader');
    final all = await kit.feedback.list();
    expect(all, hasLength(visibleCount));

    final page = await kit.feedback.list(
      const ListFeedbackOptions(page: 1, perPage: 5),
    );
    expect(page, hasLength(5));
    expect(page.map((item) => item.id), all.take(5).map((item) => item.id));

    final legacy = await http.get(
      Uri.parse('$base/feedbacks?page=2&per_page=1'),
      headers: {'X-API-Key': apiKey},
    );
    expect(legacy.statusCode, 200);
    final rows = jsonDecode(legacy.body);
    expect(rows, isA<List<dynamic>>());
    expect((rows as List<dynamic>), hasLength(visibleCount));

    final comments = await kit.comments.list(commentId);
    expect(comments, hasLength(commentCount));
    final commentPage = await kit.comments.list(commentId, page: 2, perPage: 5);
    expect(commentPage, hasLength(5));
  });
}
