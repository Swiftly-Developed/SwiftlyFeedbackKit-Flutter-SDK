import 'dart:convert';

import 'package:feedbackkit_flutter/src/api/comments_api.dart';
import 'package:feedbackkit_flutter/src/client/feedbackkit_config.dart';
import 'package:feedbackkit_flutter/src/http/http_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// The comment-create body the server accepts.
///
/// Flutter 1.2.0 encoded only `content`. The configured user id went out as
/// `X-User-Id` and the API answered 400 because `userId` was missing from the
/// JSON body.
void main() {
  test('create sends the configured userId in the body', () async {
    final captured = await _capture(
      userId: 'flutter-user-120',
      request: const CreateCommentRequest(content: 'Please add dark mode.'),
    );

    expect(captured.headers['x-api-key'], 'fixture-key');
    expect(captured.headers['x-user-id'], 'flutter-user-120');
    expect(
      jsonDecode(captured.body),
      {
        'content': 'Please add dark mode.',
        'userId': 'flutter-user-120',
      },
    );
  });

  test('an explicit request userId is the one written to the body', () async {
    final captured = await _capture(
      userId: 'configured-user',
      request: const CreateCommentRequest(
        content: 'Please add dark mode.',
        userId: 'explicit-user',
      ),
    );

    expect(
      jsonDecode(captured.body),
      {
        'content': 'Please add dark mode.',
        'userId': 'explicit-user',
      },
    );
  });

  test('create without a user id still sends content only', () async {
    final captured = await _capture(
      userId: null,
      request: const CreateCommentRequest(content: 'Please add dark mode.'),
    );

    expect(jsonDecode(captured.body), {'content': 'Please add dark mode.'});
    expect(captured.headers.containsKey('x-user-id'), isFalse);
  });
}

Future<http.Request> _capture({
  required String? userId,
  required CreateCommentRequest request,
}) async {
  http.Request? captured;
  final client = MockClient((outgoing) async {
    captured = outgoing;
    return http.Response(
      jsonEncode(created),
      200,
      headers: const {'content-type': 'application/json'},
    );
  });
  final api = CommentsApi(
    FeedbackKitHttpClient(
      config: FeedbackKitConfig(apiKey: 'fixture-key', userId: userId),
      client: client,
    ),
  );

  final comment = await api.create('feedback-id', request);
  expect(comment.userId, 'flutter-user-120');
  expect(captured, isNotNull);
  return captured!;
}

const created = {
  'id': '11111111-1111-4111-8111-111111111111',
  'content': 'Please add dark mode.',
  'user_id': 'flutter-user-120',
  'is_admin': false,
  'created_at': '2023-11-14T22:13:20Z',
};
