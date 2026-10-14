import 'package:feedbackkit_flutter/feedbackkit_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;
import 'package:flutter_test/flutter_test.dart' as flutter_test
    show testWidgets;
import 'package:shared_preferences/shared_preferences.dart';

import '../support/showcase_harness.dart';

/// Regenerate with `flutter test --update-goldens test/goldens`.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FeedbackKitLocalizations.setLocale('en');
  });

  // flutter_test paints elevation as a hard black outline unless shadows are
  // re-enabled; the goldens should show what a device draws.
  void testWidgets(String description, WidgetTesterCallback body) {
    flutter_test.testWidgets(description, (tester) async {
      debugDisableShadows = false;
      try {
        await body(tester);
      } finally {
        debugDisableShadows = true;
      }
    });
  }

  Future<void> golden(WidgetTester tester, String name) => expectLater(
        find.byType(FeedbackKitProvider),
        matchesGoldenFile('images/$name.png'),
      );

  const scales = [0.85, 1.0, 1.3, 1.5, 2.0];

  for (final brightness in Brightness.values) {
    for (final scale in scales) {
      testWidgets('showcase ${brightness.name} at ${scale}x', (tester) async {
        usePhoneSurface(tester);
        final server = FakeFeedbackServer(showcaseFixture());
        await pumpWithServer(
          tester,
          server,
          materialHost(
            list: FeedbackList(onFeedbackTap: (_) {}),
            brightness: brightness,
            textScale: scale,
          ),
        );
        await golden(tester, 'showcase_${brightness.name}_${scale}x');
      });
    }
  }

  for (final brightness in Brightness.values) {
    testWidgets('filtered ${brightness.name}', (tester) async {
      usePhoneSurface(tester);
      final controller = FeedbackListController(
        statusFilter: FeedbackStatus.inProgress,
        categoryFilter: FeedbackCategory.improvement,
      );
      addTearDown(controller.dispose);
      await pumpWithServer(
        tester,
        FakeFeedbackServer(showcaseFixture()),
        materialHost(
          list: FeedbackList(controller: controller),
          brightness: brightness,
        ),
      );
      await golden(tester, 'filtered_${brightness.name}');
    });

    testWidgets('sheet ${brightness.name}', (tester) async {
      usePhoneSurface(tester);
      final controller = FeedbackListController(
        categoryFilter: FeedbackCategory.bugReport,
      );
      addTearDown(controller.dispose);
      await pumpWithServer(
        tester,
        FakeFeedbackServer(showcaseFixture()),
        materialHost(
          list: FeedbackList(controller: controller),
          brightness: brightness,
        ),
      );
      await tester.tap(find.byTooltip('Sort & Filter'));
      await tester.pumpAndSettle();
      await golden(tester, 'sheet_${brightness.name}');
    });

    testWidgets('cupertino host ${brightness.name}', (tester) async {
      usePhoneSurface(tester);
      await pumpWithServer(
        tester,
        FakeFeedbackServer(showcaseFixture()),
        cupertinoHost(list: const FeedbackList(), brightness: brightness),
      );
      await golden(tester, 'cupertino_${brightness.name}');
    });
  }

  testWidgets('cupertino host sheet', (tester) async {
    usePhoneSurface(tester);
    await pumpWithServer(
      tester,
      FakeFeedbackServer(showcaseFixture()),
      cupertinoHost(list: const FeedbackList()),
    );
    await tester.tap(find.byTooltip('Sort & Filter'));
    await tester.pumpAndSettle();
    await golden(tester, 'cupertino_sheet_light');
  });

  testWidgets('sheet at 2x text', (tester) async {
    usePhoneSurface(tester);
    await pumpWithServer(
      tester,
      FakeFeedbackServer(showcaseFixture()),
      materialHost(list: const FeedbackList(), textScale: 2.0),
    );
    await tester.tap(find.byTooltip('Sort & Filter'));
    await tester.pumpAndSettle();
    await golden(tester, 'sheet_light_2.0x');
  });

  testWidgets('skeleton', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(
      materialHost(list: const FeedbackList(autoLoad: false)),
    );
    await tester.pumpAndSettle();
    await golden(tester, 'skeleton_light');
  });

  testWidgets('project empty', (tester) async {
    usePhoneSurface(tester);
    await pumpWithServer(
      tester,
      FakeFeedbackServer(const []),
      materialHost(list: const FeedbackList()),
    );
    await golden(tester, 'empty_light');
  });

  testWidgets('filtered empty', (tester) async {
    usePhoneSurface(tester);
    final controller = FeedbackListController(
      statusFilter: FeedbackStatus.rejected,
      categoryFilter: FeedbackCategory.bugReport,
    );
    addTearDown(controller.dispose);
    await pumpWithServer(
      tester,
      FakeFeedbackServer(showcaseFixture()),
      materialHost(list: FeedbackList(controller: controller)),
    );
    await golden(tester, 'filtered_empty_light');
  });

  testWidgets('search empty', (tester) async {
    usePhoneSurface(tester);
    await pumpWithServer(
      tester,
      FakeFeedbackServer(showcaseFixture()),
      materialHost(list: const FeedbackList()),
    );
    await tester.enterText(find.byType(TextField), 'nothing like this');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await golden(tester, 'search_empty_light');
  });

  testWidgets('error', (tester) async {
    usePhoneSurface(tester);
    await pumpWithServer(
      tester,
      FakeFeedbackServer(const [], failList: true),
      materialHost(list: const FeedbackList()),
    );
    await golden(tester, 'error_light');
  });

  testWidgets('brand tint', (tester) async {
    usePhoneSurface(tester);
    await pumpWithServer(
      tester,
      FakeFeedbackServer(showcaseFixture()),
      materialHost(
        list: const FeedbackList(),
        kitTheme: const FeedbackKitTheme(primaryColor: Color(0xFFE11D48)),
      ),
    );
    await golden(tester, 'brand_tint_light');
  });

  testWidgets('classic', (tester) async {
    usePhoneSurface(tester);
    await pumpWithServer(
      tester,
      FakeFeedbackServer(showcaseFixture()),
      materialHost(
        list: const FeedbackList(),
        listStyle: FeedbackListStyle.classic,
      ),
    );
    await golden(tester, 'classic_light');
  });

  for (final brightness in Brightness.values) {
    testWidgets('arabic ${brightness.name}', (tester) async {
      usePhoneSurface(tester);
      await pumpWithServer(
        tester,
        FakeFeedbackServer(_arabicFixture()),
        materialHost(
          list: const FeedbackList(),
          appLocale: 'ar',
          brightness: brightness,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3B6EF5),
              brightness: brightness,
            ),
            fontFamilyFallback: const ['Noto Sans Arabic'],
          ),
        ),
      );
      await golden(tester, 'arabic_${brightness.name}');
    });
  }
}

List<FeedbackItem> _arabicFixture() => [
      fixtureItem(
        id: 'a1',
        title: 'الوضع الداكن للوحة العامة',
        description: 'اللوحة فاتحة فقط، ومن يتابع الطلبات ليلاً يخفض السطوع.',
        status: FeedbackStatus.inProgress,
        voteCount: 186,
        hasVoted: true,
        commentCount: 24,
        daysAgo: 40,
      ),
      fixtureItem(
        id: 'a2',
        title: 'تصدير الطلبات إلى CSV',
        description:
            'جدول بالعنوان والحالة والأصوات والتعليقات قبل كل جلسة تخطيط.',
        status: FeedbackStatus.approved,
        category: FeedbackCategory.improvement,
        voteCount: 142,
        commentCount: 11,
        daysAgo: 28,
      ),
      fixtureItem(
        id: 'a3',
        title: 'تختفي المسودة عند انقطاع الشبكة',
        description: 'تمسح نافذة الإرسال العنوان والوصف إذا فشل الطلب.',
        category: FeedbackCategory.bugReport,
        voteCount: 97,
        commentCount: 2,
        daysAgo: 12,
      ),
      fixtureItem(
        id: 'a4',
        title: 'إشعار عند شحن طلب صوّتُّ له',
        description: 'رسالة واحدة عند اكتمال الطلب مع ملاحظة الإصدار.',
        status: FeedbackStatus.completed,
        voteCount: 51,
        hasVoted: true,
        commentCount: 1,
        daysAgo: 70,
      ),
    ];
