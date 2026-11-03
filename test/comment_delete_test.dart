import 'package:feedbackkit_flutter/src/api/comments_api.dart';
import 'package:feedbackkit_flutter/src/client/feedbackkit_config.dart';
import 'package:feedbackkit_flutter/src/errors/feedbackkit_error.dart';
import 'package:feedbackkit_flutter/src/http/http_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _feedbackId = '11111111-1111-4111-8111-111111111111';
const _commentId = '22222222-2222-4222-8222-222222222222';

/// `DELETE /feedbacks/:id/comments/:commentId` answers 204 with an empty body.
/// An API key with `X-User-Id` deletes that user's own non-admin comment.
void main() {
  CommentsApi api(MockClient client, String? userId) {
    return CommentsApi(
      FeedbackKitHttpClient(
        config: FeedbackKitConfig(apiKey: 'fixture-key', userId: userId),
        client: client,
      ),
    );
  }

  test('delete sends the route, the key and the user id', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response('', 204);
    });

    await api(client, 'owner-of-comment').delete(_feedbackId, _commentId);

    expect(captured.method, 'DELETE');
    expect(
      captured.url.path,
      endsWith('/feedbacks/$_feedbackId/comments/$_commentId'),
    );
    expect(captured.headers['x-api-key'], 'fixture-key');
    expect(captured.headers['x-user-id'], 'owner-of-comment');
  });

  test('with no user id it throws before any request', () async {
    var requests = 0;
    final client = MockClient((request) async {
      requests += 1;
      return http.Response('', 204);
    });

    await expectLater(
      api(client, null).delete(_feedbackId, _commentId),
      throwsA(isA<ValidationError>()),
    );
    expect(requests, 0);
  });

  test('a refusal reaches the caller with the server reason', () async {
    final client = MockClient((request) async {
      return http.Response(
        '{"error":true,"reason":"You can only delete your own comments"}',
        403,
        headers: {'content-type': 'application/json'},
      );
    });

    await expectLater(
      api(client, 'someone-else').delete(_feedbackId, _commentId),
      throwsA(
        isA<ForbiddenError>().having(
          (error) => error.message,
          'message',
          'You can only delete your own comments',
        ),
      ),
    );
  });
}
