import 'dart:io';

import 'package:feedbackkit_flutter/feedbackkit_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// `METRICS03` phase `08`, `G9` — the barrel and the client agree.
///
/// This file imports **only** the public barrel, deliberately. Naming a type
/// here is the reachability proof: if the barrel stopped exporting it the file
/// would not compile. `metrics_test.dart` cannot discharge this gate because it
/// reaches into `src/` for the transport it drives.
void main() {
  group('G9 · every public type this phase adds is reachable from the barrel',
      () {
    test('the referenced type set equals the source census of metrics.dart',
        () {
      // Referencing the types. This list is the compile-time claim.
      final referenced = <Type>[
        MetricsMeta,
        MetricSummary,
        MetricSeries,
        MetricSeriesPoint,
        MetricBreakdown,
        MetricBreakdownItem,
        MetricEventList,
        MetricEventRow,
        MetricsPaginationMeta,
        MetricMeasure,
        MetricDimension,
        MetricGranularity,
        MetricEventScope,
      ].map((t) => t.toString()).toSet();

      // Derived, not retyped: every public declaration in the model file.
      final source = File('lib/src/models/metrics.dart').readAsStringSync();
      expect(source.length, greaterThan(0), reason: 'the denominator');
      final declared = RegExp(r'^(?:class|enum) (\w+)', multiLine: true)
          .allMatches(source)
          .map((m) => m.group(1)!)
          .where((n) => !n.startsWith('_'))
          .toSet();

      // Set equality both directions: a tenth model class that nobody exported
      // must red here, and so must a name that no longer exists.
      expect(referenced, declared);
      expect(declared.length, 13, reason: '9 classes and 4 vocabularies');
    });

    test(
        'the four option types are reachable, and equal the API file\'s '
        'public option classes', () {
      final referenced = <Type>[
        MetricSummaryOptions,
        MetricTimeseriesOptions,
        MetricBreakdownOptions,
        MetricEventsOptions,
      ].map((t) => t.toString()).toSet();

      final source = File('lib/src/api/metrics_api.dart').readAsStringSync();
      expect(source.length, greaterThan(0), reason: 'the denominator');
      final declared = RegExp(r'^class (\w+)', multiLine: true)
          .allMatches(source)
          .map((m) => m.group(1)!)
          .where((n) => n != 'MetricsApi')
          .toSet();

      expect(referenced, declared);
      expect(declared.length, 4);
    });

    test('the predefined-name constants are reachable and exact', () {
      expect(
        PredefinedEventNames.all,
        ['feedback_list', 'feedback_detail', 'submit_feedback'],
      );
      expect(PredefinedEventNames.feedbackList, 'feedback_list');
    });

    test('RateLimitError is reachable through the unqualified error export',
        () {
      const error = RateLimitError(retryAfterSeconds: 5);
      expect(error, isA<FeedbackKitError>());
      expect(error.statusCode, 429);
      expect(error.retryAfterSeconds, 5);
    });

    test('MetricsApi itself is NOT exported — the package\'s own convention',
        () {
      // Every other API class is likewise unexported and reached through the
      // client. Asserted as a source absence because an unexported type cannot
      // be named from this file at all.
      final barrel = File('lib/feedbackkit_flutter.dart').readAsStringSync();
      final lines = barrel.split('\n');
      expect(lines.length, greaterThan(0), reason: 'the denominator');
      expect(barrel.contains('MetricsApi'), isFalse);
      for (final api in [
        'FeedbackApi',
        'VotesApi',
        'CommentsApi',
        'UsersApi',
        'EventsApi',
      ]) {
        expect(
          barrel.contains(api),
          isFalse,
          reason: 'the convention this follows: $api is unexported too',
        );
      }
    });

    test('kit.metrics is the sixth API group on the client', () {
      final kit = FeedbackKit.configure(apiKey: 'fixture-key');
      addTearDown(kit.close);
      expect(kit.metrics, isNotNull);

      final source =
          File('lib/src/client/feedbackkit_client.dart').readAsStringSync();
      expect(source.length, greaterThan(0), reason: 'the denominator');
      final groups = RegExp(r'late final (\w+Api) \w+;')
          .allMatches(source)
          .map((m) => m.group(1)!)
          .toSet();
      expect(groups, {
        'FeedbackApi',
        'VotesApi',
        'CommentsApi',
        'UsersApi',
        'EventsApi',
        'MetricsApi',
      });
      expect(groups.length, 6);
    });
  });
}
