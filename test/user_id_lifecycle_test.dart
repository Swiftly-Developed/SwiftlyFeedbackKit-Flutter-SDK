import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:feedbackkit_flutter/feedbackkit_flutter.dart';
import 'package:feedbackkit_flutter/src/http/http_client.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FeedbackKitLocalizations.setLocale('en');
  });

  group('user id', () {
    test('an explicit id wins over the stored id and is persisted', () async {
      SharedPreferences.setMockInitialValues({
        'feedbackkit_user_id': 'stored-user',
      });
      final kit = FeedbackKit(
        config: const FeedbackKitConfig(apiKey: 'k', userId: 'explicit-user'),
        createAnonymousUserId: () => throw StateError('should not generate'),
      );

      expect(await kit.resolveUserId(), 'explicit-user');
      expect(kit.userId, 'explicit-user');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('feedbackkit_user_id'), 'explicit-user');
      kit.close();
    });

    test('a missing id becomes one persisted local identifier', () async {
      var calls = 0;
      final kit = FeedbackKit(
        config: const FeedbackKitConfig(apiKey: 'k'),
        createAnonymousUserId: () {
          calls += 1;
          return 'local_fixed';
        },
      );

      final first = kit.resolveUserId();
      final second = kit.resolveUserId();
      expect(await first, 'local_fixed');
      expect(await second, 'local_fixed');
      expect(calls, 1);

      final again = FeedbackKit(
        config: const FeedbackKitConfig(apiKey: 'k'),
        createAnonymousUserId: () {
          calls += 1;
          return 'local_other';
        },
      );
      expect(await again.resolveUserId(), 'local_fixed');
      expect(calls, 1);
      kit.close();
      again.close();
    });

    test('the generated id matches the local_ uuid shape', () async {
      final kit = FeedbackKit(config: const FeedbackKitConfig(apiKey: 'k'));
      final id = await kit.resolveUserId();
      expect(
        id,
        matches(
          RegExp(
            r'^local_[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      kit.close();
    });
  });

  group('transport', () {
    test('the API key is not sent to a cleartext host', () {
      expect(
        () => FeedbackKitHttpClient(
          config: const FeedbackKitConfig(
            apiKey: 'secret',
            baseUrl: 'http://example.com/api/v1',
          ),
        ),
        throwsArgumentError,
      );
    });

    test('loopback HTTP stays available for local development', () {
      final client = FeedbackKitHttpClient(
        config: const FeedbackKitConfig(
          apiKey: 'secret',
          baseUrl: 'http://127.0.0.1:8080/api/v1',
        ),
      );
      client.close();
    });
  });

  test('Arabic lays out right to left and the other catalogs do not', () {
    FeedbackKitLocalizations.setLocale('ar-SA');
    expect(FeedbackKitLocalizations.textDirection, TextDirection.rtl);
    for (final locale in [
      'en',
      'es',
      'fr',
      'de',
      'ja',
      'zh-Hans',
      'pt-BR',
      'ko',
      'it',
      'ru',
    ]) {
      FeedbackKitLocalizations.setLocale(locale);
      expect(
        FeedbackKitLocalizations.textDirection,
        TextDirection.ltr,
        reason: locale,
      );
    }
  });

  test('comment counts and relative ages follow the catalog', () {
    final past = DateTime.utc(2020, 1, 1);
    final now = DateTime.utc(2024, 1, 1);
    FeedbackKitLocalizations.setLocale('en');
    expect(FeedbackKitLocalizations.commentCountLabel(1), '1 comment');
    expect(FeedbackKitLocalizations.commentCountLabel(2), '2 comments');
    expect(
      FeedbackKitLocalizations.relativeTime(past, now: now),
      '4${FeedbackKitLocalizations.t('time.yearsAgo')}',
    );

    FeedbackKitLocalizations.setLocale('es');
    expect(FeedbackKitLocalizations.commentCountLabel(2), '2 comentarios');
  });

  testWidgets('the list waits until the stored user id is applied',
      (tester) async {
    final storage = _GateStorage();
    late FeedbackKitContext kit;
    await tester.pumpWidget(
      FeedbackKitProvider(
        apiKey: 'k',
        baseUrl: 'http://127.0.0.1:9/api/v1',
        storage: storage,
        child: Builder(
          builder: (context) {
            kit = FeedbackKitProvider.of(context);
            return const FeedbackList(autoLoad: true);
          },
        ),
      ),
    );

    expect(kit.isInitialized, isFalse);
    expect(kit.feedbackList.state, FeedbackListState.initial);

    storage.gate.complete();
    await tester.pump();
    await tester.pump();

    expect(kit.isInitialized, isTrue);
    expect(kit.userId, 'stored-user');
    expect(kit.client.userId, 'stored-user');
    expect(kit.feedbackList.state, isNot(FeedbackListState.initial));
  });

  testWidgets('the vote control is a button and stays disabled until ready',
      (tester) async {
    final storage = _GateStorage();
    await tester.pumpWidget(
      FeedbackKitProvider(
        apiKey: 'k',
        baseUrl: 'http://127.0.0.1:9/api/v1',
        storage: storage,
        child: VoteButton(feedback: _item()),
      ),
    );

    final before = tester.getSemantics(find.bySemanticsLabel('Vote, 3'));
    expect(before.flagsCollection.isButton, isTrue);
    expect(before.flagsCollection.isEnabled, Tristate.isFalse);

    storage.gate.complete();
    await tester.pump();
    await tester.pump();

    final after = tester.getSemantics(find.bySemanticsLabel('Vote, 3'));
    expect(after.flagsCollection.isButton, isTrue);
    expect(after.flagsCollection.isEnabled, Tristate.isTrue);
  });

  testWidgets('Arabic locale lays the list out right to left', (tester) async {
    FeedbackKitLocalizations.setLocale('ar');
    await tester.pumpWidget(
      const FeedbackKitProvider(
        apiKey: 'k',
        userId: 'user-1',
        child: FeedbackList(autoLoad: false),
      ),
    );

    expect(
      tester.widget<Directionality>(find.byType(Directionality)).textDirection,
      TextDirection.rtl,
    );
  });

  testWidgets('the comment field keeps one focus node across rebuilds',
      (tester) async {
    final harness = FeedbackKitProvider(
      apiKey: 'k',
      userId: 'user-1',
      baseUrl: 'http://127.0.0.1:9/api/v1',
      child: FeedbackDetailView(feedback: _item()),
    );
    await tester.pumpWidget(harness);
    await tester.pump();
    final first =
        tester.widget<EditableText>(find.byType(EditableText)).focusNode;
    await tester.pumpWidget(harness);
    final second =
        tester.widget<EditableText>(find.byType(EditableText)).focusNode;
    expect(identical(first, second), isTrue);
  });
}

class _GateStorage extends FeedbackKitStorage {
  final Completer<void> gate = Completer<void>();

  @override
  Future<String?> getUserId() async {
    await gate.future;
    return 'stored-user';
  }
}

FeedbackItem _item() {
  return FeedbackItem(
    id: '11111111-1111-4111-8111-111111111111',
    title: 'Dark theme',
    description: 'Hard to read at night.',
    status: FeedbackStatus.pending,
    category: FeedbackCategory.featureRequest,
    voteCount: 3,
    hasVoted: false,
    commentCount: 0,
    createdAt: DateTime.utc(2023, 11, 14),
    updatedAt: DateTime.utc(2023, 11, 14),
  );
}
