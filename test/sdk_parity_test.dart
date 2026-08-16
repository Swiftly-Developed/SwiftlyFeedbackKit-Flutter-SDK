import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:feedbackkit_flutter/src/api/feedback_api.dart';
import 'package:feedbackkit_flutter/src/client/feedbackkit_config.dart';
import 'package:feedbackkit_flutter/src/errors/feedbackkit_error.dart';
import 'package:feedbackkit_flutter/src/models/feedback_category.dart';
import 'package:feedbackkit_flutter/src/models/feedback_status.dart';
import 'package:feedbackkit_flutter/src/models/sdk_user.dart';
import 'package:feedbackkit_flutter/src/models/tracked_event.dart';
import 'package:feedbackkit_flutter/src/models/vote_response.dart';

/// `QA-UNIT10-SDK-PARITY`, Flutter lane — `-06`, a `-11` gap arm (422), `-15`/`-16`/`-17`,
/// and the Part F census arms `-21`/`-22`.
///
/// Every decode fixture below is a committed copy of the server-generated corpus
/// (`SdkWireCorpusTests` in the server target regenerates and byte-diffs them; §4.5's
/// rule: a parity fixture originates at the server's own encoder, never at a client's
/// assumption). Where a case pins a shipped defect it is marked ⚠️ RECORDED AS SHIPPED:
/// the assertion is verbatim what ships, so the eventual product fix is a deliberate,
/// visible red here rather than a silent behaviour change.
void main() {
  List<dynamic> loadCorpus(String name) =>
      jsonDecode(File('test/fixtures/$name').readAsStringSync()) as List<dynamic>;

  group('QA-UNIT10 -06 · tolerant element-drop over the tolerance corpus', () {
    late List<dynamic> corpus;

    setUp(() => corpus = loadCorpus('feedback-tolerance-corpus.json'));

    test('the corpus carries its adversarial rows — non-vacuity for the group', () {
      expect(corpus.length, 4);
      expect(
        corpus.map((r) => (r as Map<String, dynamic>)['status']).toList(),
        ['pending', 'testflight', 'quantum_launch', 'completed'],
      );
      // The extra-unknown-key row is the last one, distinct from the unknown-status row.
      expect((corpus[3] as Map<String, dynamic>)['unknown_future_key'],
          'from-a-newer-server');
      expect((corpus[2] as Map<String, dynamic>).containsKey('unknown_future_key'),
          isFalse);
    });

    test('one unknown-status row is dropped and the other three survive in order', () {
      // The headline of AGENTS.md line 82, green for the first time in any of the six
      // SDKs: until 2026-08-15 Flutter coerced the unknown token to `pending` (F6) and
      // Swift/Kotlin threw the whole array away. Fixed in this SDK by QA-UNIT10.
      final items = decodeFeedbackListTolerantly(corpus);

      expect(items.length, 3);
      expect(items.map((i) => i.title).toList(),
          ['Tolerance row one', 'Tolerance row two', 'Tolerance row four']);
      expect(items.map((i) => i.status).toList(), [
        FeedbackStatus.pending,
        FeedbackStatus.testflight,
        FeedbackStatus.completed,
      ]);
    });

    test('an unknown extra KEY is tolerated without dropping the row', () {
      // Row four carries `unknown_future_key`; only unknown enum VALUES drop a row.
      final items = decodeFeedbackListTolerantly(corpus);
      expect(items.any((i) => i.title == 'Tolerance row four'), isTrue);
    });

    test('a genuinely malformed row still throws — tolerance is not error-swallowing', () {
      // The other half of the contract: a wrapper that swallows every failure turns a
      // missing-key regression into a short list nobody notices. Constructed by runtime
      // surgery on a corpus row, never by a hand-written literal.
      final malformed = List<dynamic>.from(corpus);
      malformed[0] = Map<String, dynamic>.from(corpus[0] as Map<String, dynamic>)
        ..remove('title');

      expect(
        () => decodeFeedbackListTolerantly(malformed),
        throwsA(isA<TypeError>()),
      );
    });

    test('the API list decoder routes through the same single wrapper definition', () {
      // C5: the wrapper must not exist twice. The list closure in FeedbackApi.list calls
      // decodeFeedbackListTolerantly; this source assertion keeps it true.
      final source =
          File('lib/src/api/feedback_api.dart').readAsStringSync();
      expect(source.contains('return decodeFeedbackListTolerantly(data);'), isTrue);
      expect(
        RegExp('on UnknownEnumValueException').allMatches(source).length,
        1,
        reason: 'exactly one catch site — the wrapper is a single definition',
      );
    });
  });

  group('QA-UNIT10 -11 gap · the unmapped 422', () {
    test('422 maps to the base error with UNKNOWN_ERROR — RECORDED AS SHIPPED', () {
      // ⚠️ RECORDED AS SHIPPED. No SDK of the six maps 422, so the server's validation
      // envelope reaches a Flutter integrator as an "unknown error". errors_test.dart
      // covers the other nine statuses; this is the gap arm, pinned so a deliberate
      // future mapping is a visible red.
      final error = createErrorFromResponse(422, 'Validation failed');
      expect(error, isA<FeedbackKitError>());
      expect(error, isNot(isA<ValidationError>()));
      expect(error, isNot(isA<ServerError>()));
      expect(error.code, 'UNKNOWN_ERROR');
      expect(error.statusCode, 422);
    });

    test('429 shares the unknown fallback — the paired sibling', () {
      final error = createErrorFromResponse(429, 'Too many requests');
      expect(error.code, 'UNKNOWN_ERROR');
      expect(error.statusCode, 429);
    });
  });

  group('QA-UNIT10 -15/-16/-17 · configuration parity, Flutter arm', () {
    test('the default base URL is production and INCLUDES /api/v1', () {
      // -15: Flutter agrees with the five-SDK production default (the Swift SDK is the
      // odd one out — its configure(with:) defaults to localhost).
      // -16: the stored value INCLUDES the /api/v1 segment. Kotlin and Vapor store the
      // origin only and append /api/v1 at use; the effective URLs coincide, so only this
      // stored-value assertion can see the semantic split — an integrator lifting a
      // Flutter-style override into Kotlin gets /api/v1/api/v1.
      expect(FeedbackKitConfig.defaultBaseUrl,
          'https://api.prod.getfeedbackkit.com/api/v1');
      const config = FeedbackKitConfig(apiKey: 'fixture-key');
      expect(config.baseUrl, endsWith('/api/v1'));
    });

    test('an empty API key is accepted silently — RECORDED AS SHIPPED', () {
      // ⚠️ RECORDED AS SHIPPED (-17). Required-ness is compile-time only; there is no
      // runtime validation. JS is the only SDK that throws, and it throws a bare Error.
      const config = FeedbackKitConfig(apiKey: '');
      expect(config.apiKey, '');
    });

    test('the default timeout is 30000 ms and there is no environment concept', () {
      // -18's Flutter row: Flutter declares no environment enumeration at all (Swift has
      // four, Vapor five, Kotlin four different ones). Asserted as a source fact.
      expect(FeedbackKitConfig.defaultTimeout, 30000);
      final source =
          File('lib/src/client/feedbackkit_config.dart').readAsStringSync();
      expect(source.contains('enum Environment'), isFalse);
    });
  });

  group('QA-UNIT10 -21 · required-field census, Flutter arms', () {
    test('VoteResponse fabricates success — RECORDED AS SHIPPED', () {
      // ⚠️ RECORDED AS SHIPPED. The server's vote payload is exactly
      // {feedback_id, vote_count, has_voted} — it has never sent `success` — and
      // VoteResponse.fromJson defaults it `?? true`, so the SDK reports success
      // unconditionally. (Kotlin's twin defect is fatal instead: its `success` is
      // required and every vote throws.) The corpus row's key set is asserted first so
      // the fabrication claim is non-vacuous.
      final corpus = loadCorpus('vote-wire-corpus.json');
      final row = corpus[0] as Map<String, dynamic>;
      expect(row.keys.toSet(), {'feedback_id', 'vote_count', 'has_voted'});

      final vote = VoteResponse.fromJson(row);
      expect(vote.success, isTrue,
          reason: 'fabricated: the wire carries no success key at all');
      expect(vote.voteCount, 8);
      expect(vote.hasVoted, isTrue);

      // The unvote row: hasVoted false, and success is STILL true — the pin that shows
      // the value is unconditional rather than read.
      final unvote = VoteResponse.fromJson(corpus[1] as Map<String, dynamic>);
      expect(unvote.hasVoted, isFalse);
      expect(unvote.success, isTrue);
      // feedback_id is never read: the model has no field for it.
    });

    test('SDKUser reads three phantom keys of four — RECORDED AS SHIPPED', () {
      // ⚠️ RECORDED AS SHIPPED (F3). The server sends {id, user_id, mrr, first_seen_at,
      // last_seen_at}; the model reads {id, email, name, created_at}. Only `id` binds.
      final corpus = loadCorpus('sdk-user-wire-corpus.json');
      final row = corpus[0] as Map<String, dynamic>;
      expect(row.keys.toSet(),
          {'id', 'user_id', 'mrr', 'first_seen_at', 'last_seen_at'});

      final user = SDKUser.fromJson(row);
      expect(user.id, isNotEmpty); // the one field that binds
      expect(user.email, isNull, reason: 'phantom: the server never sends email');
      expect(user.name, isNull, reason: 'phantom: the server never sends name');
      expect(user.createdAt, isNull,
          reason: 'phantom: the server sends first_seen_at, not created_at');
    });

    test('TrackedEvent cannot decode the server payload at all — RECORDED AS SHIPPED', () {
      // ⚠️ RECORDED AS SHIPPED (F4, fatal). The model reads `name` where the server
      // sends `event_name`, with a hard cast — so decoding what the server actually
      // returns throws TypeError. The alternative discovery path is a crash in a
      // shipped app.
      final corpus = loadCorpus('event-wire-corpus.json');
      final row = corpus[0] as Map<String, dynamic>;
      expect(row.containsKey('event_name'), isTrue);
      expect(row.containsKey('name'), isFalse);

      expect(
        () => TrackedEvent.fromJson(row),
        throwsA(isA<TypeError>()),
        reason: "json['name'] as String throws on the payload the server sends",
      );
    });
  });

  group('QA-UNIT10 -22 · encode-direction key contract, Flutter arm', () {
    test('CreateFeedbackRequest emits keys the server cannot decode — RECORDED AS SHIPPED', () {
      // ⚠️ RECORDED AS SHIPPED. The canon is the server's own CreateFeedbackDTO key
      // set, loaded from the generated request corpus — never retyped here. Flutter
      // emits `subscribeToMailingList` / `mailingListEmailTypes` in camelCase against
      // the server's snake_case decoder, and `email` where the server reads
      // `user_email`. All three are silently dropped: the create returns 200 and the
      // mailing-list opt-in simply never happens. No response assertion can see this,
      // which is why the encode direction has its own arm.
      final canon = (jsonDecode(
        File('test/fixtures/request-wire-corpus.json').readAsStringSync(),
      ) as Map<String, dynamic>)['create_feedback'] as Map<String, dynamic>;
      final canonKeys = canon.keys.toSet();
      expect(canonKeys, {
        'title', 'description', 'category', 'user_id', 'user_email',
        'subscribe_to_mailing_list', 'mailing_list_email_types',
      });

      const request = CreateFeedbackRequest(
        title: 'Add a dark theme',
        description: 'The list is hard to read at night.',
        category: FeedbackCategory.featureRequest,
        email: 'fixture-user@example.invalid',
        subscribeToMailingList: true,
        mailingListEmailTypes: ['status_change'],
      );
      final emitted = request.toJson().keys.toSet();

      // The three offenders, individually named.
      expect(emitted.contains('subscribeToMailingList'), isTrue);
      expect(emitted.contains('mailingListEmailTypes'), isTrue);
      expect(emitted.contains('email'), isTrue);
      expect(canonKeys.contains('subscribeToMailingList'), isFalse);
      expect(canonKeys.contains('mailingListEmailTypes'), isFalse);
      expect(canonKeys.contains('email'), isFalse);

      // The dropped set, as a set claim: everything the client emits beyond the canon
      // is silently discarded by the server's decoder.
      expect(emitted.difference(canonKeys),
          {'subscribeToMailingList', 'mailingListEmailTypes', 'email'});
    });
  });
}
