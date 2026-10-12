import 'dart:convert';
import 'dart:io';

import 'package:feedbackkit_flutter/src/api/users_api.dart';
import 'package:feedbackkit_flutter/src/api/votes_api.dart';
import 'package:feedbackkit_flutter/src/client/feedbackkit_config.dart';
import 'package:feedbackkit_flutter/src/http/http_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Vote and register request bodies, checked against `request-wire-corpus.json`.
///
/// That fixture is generated from `CreateVoteDTO` and `RegisterSDKUserDTO` by
/// `SdkWireCorpusTests` through the server's snake_case encoder. The decoder
/// test on the server (`testVoteAndRegisterDecodersBindTheCorpusKeysAndDropTheSdkMisspellings`)
/// is what makes the key names load-bearing: `notify_on_status_change` does not
/// bind `notifyStatusChange`, and `{id, email, name}` does not decode as a user.
void main() {
  Map<String, dynamic> loadCanon() => jsonDecode(
        File('test/fixtures/request-wire-corpus.json').readAsStringSync(),
      ) as Map<String, dynamic>;

  group('vote and register wire keys', () {
    late Map<String, dynamic> voteCanon;
    late Map<String, dynamic> registerCanon;

    setUp(() {
      final canon = loadCanon();
      voteCanon = canon['create_vote']! as Map<String, dynamic>;
      registerCanon = canon['register_sdk_user']! as Map<String, dynamic>;
    });

    test('the corpus keys are the server spellings, not the SDK misspellings', () {
      expect(voteCanon.containsKey('notify_status_change'), isTrue);
      expect(voteCanon.containsKey('email'), isTrue);
      expect(voteCanon.containsKey('user_id'), isTrue);
      expect(voteCanon.containsKey('notify_on_status_change'), isFalse);
      expect(registerCanon.keys.toSet(), {'user_id', 'mrr'});
    });

    test('votes.vote sends notify_status_change, email, and user_id', () async {
      http.Request? captured;
      final api = VotesApi(
        FeedbackKitHttpClient(
          config: const FeedbackKitConfig(
            apiKey: 'fixture-key',
            userId: 'fixture-end-user',
          ),
          client: MockClient((request) async {
            captured = request;
            return http.Response(
              jsonEncode({
                'vote_count': 2,
                'has_voted': true,
                'feedback_id': 'fid',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      );

      await api.vote(
        'fid',
        email: 'fixture-user@example.invalid',
        // ignore: deprecated_member_use
        notifyOnStatusChange: true,
      );

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['notify_status_change'], isTrue);
      expect(body['email'], voteCanon['email']);
      expect(body.containsKey('notify_on_status_change'), isFalse);
      expect(body.containsKey('notifyStatusChange'), isFalse);
      expect(body['user_id'], voteCanon['user_id']);
      expect(
        body.keys.toSet().difference(voteCanon.keys.toSet()),
        isEmpty,
        reason: 'every emitted vote key must be one the server corpus names',
      );
    });

    test('notifyStatusChange wins over the deprecated alias', () async {
      http.Request? captured;
      final api = VotesApi(
        FeedbackKitHttpClient(
          config: const FeedbackKitConfig(
            apiKey: 'fixture-key',
            userId: 'fixture-end-user',
          ),
          client: MockClient((request) async {
            captured = request;
            return http.Response(
              jsonEncode({
                'vote_count': 1,
                'has_voted': true,
                'feedback_id': 'fid',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      );

      await api.vote(
        'fid',
        notifyStatusChange: false,
        // ignore: deprecated_member_use
        notifyOnStatusChange: true,
      );

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['notify_status_change'], isFalse);
      expect(body.containsKey('notify_on_status_change'), isFalse);
    });

    test('users.register sends user_id and not id, email, or name', () {
      final body = const RegisterUserRequest(
        // ignore: deprecated_member_use, deprecated_member_use_from_same_package
        id: 'fixture-end-user',
        // ignore: deprecated_member_use, deprecated_member_use_from_same_package
        email: 'fixture-user@example.invalid',
        // ignore: deprecated_member_use, deprecated_member_use_from_same_package
        name: 'Fixture',
      ).toJson();

      expect(body['user_id'], 'fixture-end-user');
      expect(body.containsKey('id'), isFalse);
      expect(body.containsKey('email'), isFalse);
      expect(body.containsKey('name'), isFalse);
      expect(body.containsKey('mrr'), isFalse);
      expect(
        body.keys.toSet().difference(registerCanon.keys.toSet()),
        isEmpty,
      );
    });

    test('users.register with userId and mrr matches the register canon', () {
      final body = const RegisterUserRequest(
        userId: 'fixture-end-user',
        mrr: 42.5,
        // ignore: deprecated_member_use, deprecated_member_use_from_same_package
        email: 'fixture-user@example.invalid',
        // ignore: deprecated_member_use, deprecated_member_use_from_same_package
        name: 'Fixture',
      ).toJson();

      expect(body.keys.toSet(), registerCanon.keys.toSet());
      expect(body['user_id'], registerCanon['user_id']);
      expect(body['mrr'], registerCanon['mrr']);
    });
  });
}
