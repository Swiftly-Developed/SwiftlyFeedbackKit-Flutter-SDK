import 'dart:convert';
import 'dart:io';

import 'package:feedbackkit_flutter/src/api/metrics_api.dart';
import 'package:feedbackkit_flutter/src/client/feedbackkit_config.dart';
import 'package:feedbackkit_flutter/src/errors/feedbackkit_error.dart';
import 'package:feedbackkit_flutter/src/http/http_client.dart';
import 'package:feedbackkit_flutter/src/models/feedback_category.dart';
import 'package:feedbackkit_flutter/src/models/feedback_status.dart';
import 'package:feedbackkit_flutter/src/models/metrics.dart';
import 'package:feedbackkit_flutter/src/models/predefined_event_names.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// `METRICS03` phase `08`, Flutter lane — the metrics client surface.
///
/// Every decode fixture is a committed copy of the server-generated corpus from
/// phase `01`; no JSON literal is hand-written here, and every negative case is
/// runtime surgery on a **parsed** row (the rule `sdk_parity_test.dart` already
/// follows). Every parity assertion is a **set equality**, never a `contains`:
/// a presence oracle cannot see an extra field, an extra operation or an extra
/// measure, and those are exactly this phase's regression axes.
void main() {
  Map<String, dynamic> loadCorpus(String name) =>
      jsonDecode(File('test/fixtures/$name').readAsStringSync())
          as Map<String, dynamic>;

  Map<String, dynamic> row(Map<String, dynamic> corpus, String key) =>
      corpus[key] as Map<String, dynamic>;

  /// Strips `//`, `///` and `/* */` so an absence leg cannot be satisfied by a
  /// doc comment that merely *mentions* the forbidden token. Callers assert
  /// non-vacuity on the result: a stripper that returns `''` turns every
  /// absence leg green.
  String stripComments(String source) {
    final withoutBlocks =
        source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
    return withoutBlocks.split('\n').map((line) {
      final i = line.indexOf('//');
      return i < 0 ? line : line.substring(0, i);
    }).join('\n');
  }

  List<File> dartFilesUnder(List<String> dirs) {
    final files = <File>[];
    for (final dir in dirs) {
      for (final entity in Directory(dir).listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          files.add(entity);
        }
      }
    }
    return files;
  }

  // ---------------------------------------------------------------------------
  // G1 — the query builder
  // ---------------------------------------------------------------------------

  group(
      'G1 · query building survives every breaking class, and the controls '
      'prove the suite looked', () {
    /// Vapor's own parser semantics, re-implemented: `URLEncodedFormParser`
    /// replaces every literal `+` with `%20` BEFORE percent-decoding, then
    /// splits on `&` and on the first `=`.
    Map<String, String> serverWouldSee(Uri uri) {
      final out = <String, String>{};
      final query = uri.query.replaceAll('+', '%20');
      for (final pair in query.split('&')) {
        if (pair.isEmpty) continue;
        final i = pair.indexOf('=');
        final key = i < 0 ? pair : pair.substring(0, i);
        final value = i < 0 ? '' : pair.substring(i + 1);
        out[Uri.decodeComponent(key)] = Uri.decodeComponent(value);
      }
      return out;
    }

    /// Sends the four operations through the REAL transport and returns the
    /// URIs it put on the wire. Nothing here re-implements `_buildUri`: a gate
    /// that mimics the product cannot see the product break.
    Future<List<Uri>> urisOnTheWire(String eventName) async {
      final seen = <Uri>[];
      final client = MockClient((request) async {
        seen.add(request.url);
        return http.Response(
          '{}',
          500,
          headers: const {'content-type': 'application/json'},
        );
      });
      final api = MetricsApi(
        FeedbackKitHttpClient(
          config: const FeedbackKitConfig(apiKey: 'fixture-key'),
          client: client,
        ),
      );
      try {
        await api.summary(
          MetricSummaryOptions(
            measures: const [MetricMeasure.eventCount],
            eventName: eventName,
          ),
        );
      } catch (_) {}
      try {
        await api.timeseries(
          MetricTimeseriesOptions(
            measures: const [MetricMeasure.eventCount],
            eventName: eventName,
          ),
        );
      } catch (_) {}
      try {
        await api.breakdown(
          MetricBreakdownOptions(
            measures: const [MetricMeasure.eventCount],
            dimension: MetricDimension.eventName,
            eventName: eventName,
          ),
        );
      } catch (_) {}
      try {
        await api.events(MetricEventsOptions(eventName: eventName));
      } catch (_) {}
      return seen;
    }

    // Five values that BREAK a naive builder, then seven controls. A suite whose
    // only hostile value is `my event` reds on nothing: spaces, accents and emoji
    // survive even a hand-concatenated query string.
    const breaking = <String>[
      'a&b=c', // would inject a parameter
      'a#b', // would truncate at the fragment
      'a+b', // the server plus-decodes a literal +
      '100%20done', // literal % would double-decode
      'my event & more · ünïcode', // the canonical spec string
    ];
    const controls = <String>[
      'my event',
      'ünïcode · dot',
      'checkout 🛒',
      'say "hi"',
      'a=b',
      'a?b',
      'a;b',
    ];
    const hostileValues = <String>[...breaking, ...controls];

    List<Map<String, String?>> allOperations(String eventName) => [
          MetricSummaryOptions(
            measures: const [MetricMeasure.eventCount],
            eventName: eventName,
          ).toQueryParams(),
          MetricTimeseriesOptions(
            measures: const [MetricMeasure.eventCount],
            eventName: eventName,
          ).toQueryParams(),
          MetricBreakdownOptions(
            measures: const [MetricMeasure.eventCount],
            dimension: MetricDimension.eventName,
            eventName: eventName,
          ).toQueryParams(),
          MetricEventsOptions(eventName: eventName).toQueryParams(),
        ];

    test(
        'all twelve hostile event names round-trip through all four operations',
        () async {
      expect(
        hostileValues.length,
        12,
        reason: 'the denominator: five breaking classes plus seven controls',
      );
      expect(breaking.length, 5);

      final wrong = <String>[];
      var checked = 0;
      for (final value in hostileValues) {
        final uris = await urisOnTheWire(value);
        expect(uris.length, 4, reason: 'four operations were sent: $value');
        for (final uri in uris) {
          final decoded = serverWouldSee(uri);
          if (decoded['event_name'] != value) {
            wrong.add('$value -> ${decoded['event_name']}');
          }
          checked++;
        }
      }
      expect(checked, 48, reason: '12 values × 4 operations');
      // Reported as one whole vector: a per-iteration assertion surfaces only
      // the first of several failures, and the silence reads as a finding.
      expect(wrong, isEmpty);
    });

    test(
        'the emitted key list is exactly C2\'s spelling, in order, per '
        'operation', () {
      final summary = MetricSummaryOptions(
        measures: const [MetricMeasure.eventCount],
      ).toQueryParams();
      expect(summary.keys.toList(), [
        'measures',
        'status',
        'category',
        'event_name',
        'date_from',
        'date_to',
        'days',
      ]);

      final timeseries = MetricTimeseriesOptions(
        measures: const [MetricMeasure.eventCount],
      ).toQueryParams();
      expect(timeseries.keys.toList(), [
        'measures',
        'granularity',
        'status',
        'category',
        'event_name',
        'date_from',
        'date_to',
        'days',
      ]);

      // `granularity` is read on breakdown too — the contract's C2 note. It is
      // inert there (it buckets nothing) but an unparseable value is still a
      // 400 on this route, and `meta.granularity` comes back present.
      final breakdown = MetricBreakdownOptions(
        measures: const [MetricMeasure.eventCount],
        dimension: MetricDimension.status,
      ).toQueryParams();
      expect(breakdown.keys.toList(), [
        'measures',
        'granularity',
        'dimension',
        'status',
        'category',
        'event_name',
        'date_from',
        'date_to',
        'days',
      ]);

      final events = MetricEventsOptions().toQueryParams();
      expect(events.keys.toList(), [
        'measures',
        'status',
        'category',
        'event_name',
        'date_from',
        'date_to',
        'days',
        'page',
        'per_page',
      ]);
    });

    test('no emitted key is camelCase, and the leg proves it examined keys',
        () {
      final keys = <String>[];
      for (final params in allOperations('x')) {
        keys.addAll(params.keys);
      }
      expect(keys.length, greaterThan(0), reason: 'the denominator');
      expect(keys.length, 33, reason: '7 + 8 + 9 + 9, derived from C2');
      final camel = keys.where((k) => RegExp(r'[A-Z]').hasMatch(k)).toList();
      expect(
        camel,
        isEmpty,
        reason: 'a camelCase key is a silent 200 over the default window',
      );
    });

    test('measures, status and category are ONE comma-joined entry each',
        () async {
      final params = MetricSummaryOptions(
        measures: const [MetricMeasure.eventCount, MetricMeasure.voteCount],
        status: const [FeedbackStatus.pending, FeedbackStatus.inProgress],
        category: const [
          FeedbackCategory.bugReport,
          FeedbackCategory.featureRequest,
        ],
        eventName: 'checkout_completed',
      ).toQueryParams();

      expect(params['measures'], 'event_count,vote_count');
      expect(params['status'], 'pending,in_progress');
      expect(params['category'], 'bug_report,feature_request');
      expect(params['event_name'], 'checkout_completed');

      // One entry each on the wire, not repeated parameters.
      final uris = await urisOnTheWire('checkout_completed');
      final decoded = serverWouldSee(uris.first);
      expect(decoded['event_name'], 'checkout_completed');
      expect(
        '&'.allMatches(uris.first.query).length,
        1,
        reason: 'measures and event_name only, so one separator',
      );
    });

    test('dates serialise as ISO-8601 instants, never a yyyy-MM-dd substring',
        () {
      final params = MetricSummaryOptions(
        measures: const [MetricMeasure.eventCount],
        dateFrom: DateTime.utc(2023, 10, 16, 4),
        dateTo: DateTime.utc(2023, 11, 14, 5),
      ).toQueryParams();
      // Whole seconds. A fractional second is METRICS_INVALID_DATE.
      expect(params['date_from'], '2023-10-16T04:00:00Z');
      expect(params['date_to'], '2023-11-14T05:00:00Z');
      expect(params['date_from']!.contains('.'), isFalse);
      expect(
        params['date_from']!.length,
        greaterThan(10),
        reason: 'a date-only value would be exactly 10 characters',
      );
    });

    test(
        'a fractional second and a parsed meta date_from stay whole seconds '
        'on every operation, including on the wire', () async {
      // These three inputs are the spellings the resolver rejects. The
      // assertions below are on what the SDK sends, not on these strings.
      final fractional = DateTime.utc(2023, 10, 16, 4, 0, 0, 123, 456);
      final fromMeta = DateTime.parse('2023-10-16T04:00:00Z');
      final withOffset = DateTime.parse('2023-10-15T21:00:00-07:00');
      expect(fractional.toIso8601String(), '2023-10-16T04:00:00.123456Z');
      expect(fromMeta.toIso8601String(), '2023-10-16T04:00:00.000Z');
      expect(withOffset.toUtc().toIso8601String(), '2023-10-16T04:00:00.000Z');

      const from = '2023-10-16T04:00:00Z';
      const to = '2023-11-14T05:00:00Z';
      final end = DateTime.utc(2023, 11, 14, 5, 0, 0, 999);
      expect(end.toIso8601String(), '2023-11-14T05:00:00.999Z');

      final params = <Map<String, String?>>[
        MetricSummaryOptions(
          measures: const [MetricMeasure.eventCount],
          dateFrom: fractional,
          dateTo: end,
        ).toQueryParams(),
        MetricTimeseriesOptions(
          measures: const [MetricMeasure.eventCount],
          dateFrom: fromMeta,
          dateTo: end,
        ).toQueryParams(),
        MetricBreakdownOptions(
          measures: const [MetricMeasure.eventCount],
          dimension: MetricDimension.status,
          dateFrom: withOffset,
          dateTo: end,
        ).toQueryParams(),
        MetricEventsOptions(
          dateFrom: fractional,
          dateTo: end,
        ).toQueryParams(),
      ];
      expect(params.length, 4);
      for (final row in params) {
        expect(row['date_from'], from);
        expect(row['date_to'], to);
      }

      final seen = <Uri>[];
      final client = MockClient((request) async {
        seen.add(request.url);
        return http.Response(
          '{}',
          500,
          headers: const {'content-type': 'application/json'},
        );
      });
      final api = MetricsApi(
        FeedbackKitHttpClient(
          config: const FeedbackKitConfig(apiKey: 'fixture-key'),
          client: client,
        ),
      );
      const measures = [MetricMeasure.eventCount];
      try {
        await api.summary(
          MetricSummaryOptions(
            measures: measures,
            dateFrom: fractional,
            dateTo: end,
          ),
        );
      } catch (_) {}
      try {
        await api.timeseries(
          MetricTimeseriesOptions(
            measures: measures,
            dateFrom: fromMeta,
            dateTo: end,
          ),
        );
      } catch (_) {}
      try {
        await api.breakdown(
          MetricBreakdownOptions(
            measures: measures,
            dimension: MetricDimension.status,
            dateFrom: withOffset,
            dateTo: end,
          ),
        );
      } catch (_) {}
      try {
        await api.events(
          MetricEventsOptions(dateFrom: fractional, dateTo: end),
        );
      } catch (_) {}

      expect(seen.length, 4, reason: 'summary, timeseries, breakdown, events');
      for (final uri in seen) {
        final decoded = serverWouldSee(uri);
        expect(decoded['date_from'], from);
        expect(decoded['date_to'], to);
      }
    });

    test('an inverted window throws before any request is made', () {
      expect(
        () => MetricSummaryOptions(
          measures: const [MetricMeasure.eventCount],
          dateFrom: DateTime.utc(2023, 11, 14),
          dateTo: DateTime.utc(2023, 10, 16),
        ),
        throwsArgumentError,
      );
    });

    test('perPage is clamped client-side to 1...200, and says it is a courtesy',
        () {
      expect(MetricEventsOptions(perPage: 0).perPage, 1);
      expect(MetricEventsOptions(perPage: 500).perPage, 200);
      expect(MetricEventsOptions(perPage: 50).perPage, 50);
      expect(MetricEventsOptions().toQueryParams()['per_page'], isNull);

      final source = File('lib/src/api/metrics_api.dart').readAsStringSync();
      expect(
        source.contains('never clamps silently'),
        isTrue,
        reason: 'the clamp must not be documented as server behaviour',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // G3 — meta
  // ---------------------------------------------------------------------------

  group(
      'G3 · meta is exactly the contract\'s nine, and granularity is ABSENT '
      'where it must be', () {
    late Map<String, dynamic> corpus;

    setUp(() => corpus = loadCorpus('metrics-wire-corpus.json'));

    Map<String, dynamic> metaOf(String rowKey, {String block = 'meta'}) =>
        row(corpus, rowKey)[block] as Map<String, dynamic>;

    test('the union of every meta block is nine keys — the denominator', () {
      final union = <String>{};
      final blocks = [
        metaOf('summary_free_scoped_and_clamped'),
        metaOf('summary_team_all_scope'),
        metaOf('timeseries_daily'),
        metaOf('breakdown_event_name_with_overflow'),
        metaOf('events_page', block: 'metrics'),
      ];
      expect(blocks.length, 5, reason: 'the corpus rows examined');
      for (final block in blocks) {
        union.addAll(block.keys);
      }
      expect(union.length, 9);
    });

    test(
        'granularity splits the four surfaces 2/2, by set equality both '
        'directions', () {
      final union = <String>{
        ...metaOf('timeseries_daily').keys,
        ...metaOf('breakdown_event_name_with_overflow').keys,
      };
      expect(union.length, 9);
      final withoutGranularity = union.difference({'granularity'});
      expect(withoutGranularity.length, 8);

      // Present: timeseries AND breakdown. The breakdown leg is the one a
      // "breakdown looks like summary" reading gets wrong, in the direction
      // that passes.
      expect(metaOf('timeseries_daily').keys.toSet(), union);
      expect(metaOf('breakdown_event_name_with_overflow').keys.toSet(), union);

      // Absent: summary and the event feed's metrics block.
      expect(
        metaOf('summary_free_scoped_and_clamped').keys.toSet(),
        withoutGranularity,
      );
      expect(metaOf('summary_team_all_scope').keys.toSet(), withoutGranularity);
      expect(
        metaOf('events_page', block: 'metrics').keys.toSet(),
        withoutGranularity,
      );
    });

    test('granularity is ABSENT, not null — containsKey is false', () {
      // A `expect(meta['granularity'], isNull)` assertion never fires: absent
      // and null are indistinguishable through a map read.
      expect(
        metaOf('summary_free_scoped_and_clamped').containsKey('granularity'),
        isFalse,
      );
      expect(
        metaOf('events_page', block: 'metrics').containsKey('granularity'),
        isFalse,
      );
      expect(
        metaOf('breakdown_event_name_with_overflow').containsKey('granularity'),
        isTrue,
      );
    });

    test('the model decodes an absent granularity without throwing', () {
      final meta = MetricsMeta.fromJson(
        metaOf('summary_free_scoped_and_clamped'),
      );
      expect(meta.granularity, isNull);
      expect(meta.timezone, 'America/New_York');
      expect(meta.eventScope, MetricEventScope.predefinedOnly);
      expect(meta.retentionClamped, isTrue);
      expect(meta.retentionWindowDays, 30);

      final breakdownMeta =
          MetricsMeta.fromJson(metaOf('breakdown_event_name_with_overflow'));
      expect(breakdownMeta.granularity, 'day');
    });

    test('retention_window_days is READ, not defaulted — removing it throws',
        () {
      // A model answering 30 here has hardcoded the number the spec forbids,
      // wearing a defensive-coding costume.
      final mutated =
          Map<String, dynamic>.from(metaOf('summary_team_all_scope'))
            ..remove('retention_window_days');
      expect(mutated.containsKey('retention_window_days'), isFalse);
      expect(() => MetricsMeta.fromJson(mutated), throwsA(isA<TypeError>()));

      // Both allowances appear in the corpus, so neither is a lucky constant.
      expect(
        MetricsMeta.fromJson(metaOf('summary_team_all_scope'))
            .retentionWindowDays,
        365,
      );
      expect(
        MetricsMeta.fromJson(metaOf('summary_free_scoped_and_clamped'))
            .retentionWindowDays,
        30,
      );
    });

    test('date_from and date_to are ISO-8601 INSTANTS, not yyyy-MM-dd', () {
      var examined = 0;
      var withTimeOfDay = 0;
      for (final key in corpus.keys) {
        final r = row(corpus, key);
        // The event feed puts the metrics block under `metrics`; every other
        // operation puts it under `meta`. Reading `meta` blindly here would
        // silently skip the feed row and drop the denominator to four.
        final block = (r.containsKey('metrics') ? r['metrics'] : r['meta'])
            as Map<String, dynamic>;
        if (!block.containsKey('date_from')) continue;
        examined++;
        final parsed = DateTime.parse(block['date_from'] as String);
        if (parsed.hour != 0 || parsed.minute != 0 || parsed.second != 0) {
          withTimeOfDay++;
        }
      }
      expect(examined, greaterThan(0), reason: 'the denominator');
      expect(examined, 5);
      expect(
        withTimeOfDay,
        greaterThan(0),
        reason: 'a yyyy-MM-dd format assumption would lose this',
      );
    });

    test('the model\'s own field set equals the wire\'s nine', () {
      final wireKeys =
          metaOf('breakdown_event_name_with_overflow').keys.toSet();
      final model = MetricsMeta.fromJson(
        metaOf('breakdown_event_name_with_overflow'),
      );
      expect(model.toJson().keys.toSet(), wireKeys);
      expect(model.toJson().keys.length, 9);
    });
  });

  // ---------------------------------------------------------------------------
  // G4 — values, sparsity, key fidelity
  // ---------------------------------------------------------------------------

  group(
      'G4 · values are sparse, snake_case-keyed, and the accessor is '
      'optional-returning — BOTH directions', () {
    late Map<String, dynamic> corpus;

    setUp(() => corpus = loadCorpus('metrics-wire-corpus.json'));

    test('no values key is rewritten in either direction', () {
      final raw = row(corpus, 'summary_team_all_scope')['values']
          as Map<String, dynamic>;
      final summary =
          MetricSummary.fromJson(row(corpus, 'summary_team_all_scope'));

      expect(raw.keys.toSet(), isNotEmpty, reason: 'the denominator');
      expect(summary.values.keys.toSet(), raw.keys.toSet());

      // Both halves. A one-directional gate is green on a decoder that emitted
      // BOTH spellings.
      expect(summary.measure(MetricMeasure.eventCount), isNotNull);
      expect(summary.values['eventCount'], isNull);
      expect(summary.values['uniqueEventUsers'], isNull);
      expect(summary.measure(MetricMeasure.uniqueEventUsers), 1733);
    });

    test(
        'the overflow row omits unique_event_users and the accessor returns '
        'null', () {
      final breakdown = MetricBreakdown.fromJson(
        row(corpus, 'breakdown_event_name_with_overflow'),
      );
      expect(breakdown.dimension, MetricDimension.eventName);

      final overflow = breakdown.items.where((i) => i.isOverflow).toList();
      expect(
        overflow.length,
        1,
        reason: 'the denominator: "the overflow row returns null" is '
            'vacuously true when there is no overflow row',
      );
      expect(overflow.single.measure(MetricMeasure.uniqueEventUsers), isNull);
      expect(overflow.single.measure(MetricMeasure.eventCount), 402);

      final normal = breakdown.items.where((i) => !i.isOverflow).single;
      expect(normal.measure(MetricMeasure.uniqueEventUsers), 317);
    });

    test('a series point carries the same optional-returning accessor', () {
      final series = MetricSeries.fromJson(row(corpus, 'timeseries_daily'));
      expect(series.series.length, 3);
      // The empty bucket is PRESENT and zero-valued, not omitted.
      expect(series.series[1].measure(MetricMeasure.eventCount), 0);
      expect(series.series[1].measure(MetricMeasure.mrrSum), isNull);
      expect(
        series.series.map((p) => p.bucket).toList(),
        ['2023-11-12', '2023-11-13', '2023-11-14'],
      );
    });

    test('an event row\'s properties survive verbatim, keys and types', () {
      final events = MetricEventList.fromJson(row(corpus, 'events_page'));
      final withProps = events.items.firstWhere((e) => e.properties != null);
      expect(
        withProps.properties!.keys.toSet(),
        {'checkout_step', 'utm_source'},
      );
      expect(withProps.properties!['checkout_step'], 'payment');

      // A non-String value keeps its JSON type: the map is dynamic-valued, not
      // String-valued. Runtime surgery on a parsed row, never a literal fixture.
      final rawRow = Map<String, dynamic>.from(
        (row(corpus, 'events_page')['items'] as List<dynamic>)[0]
            as Map<String, dynamic>,
      );
      rawRow['properties'] = <String, dynamic>{
        ...rawRow['properties'] as Map<String, dynamic>,
        'retry_count': 3,
        'is_guest': true,
      };
      final decoded = MetricEventRow.fromJson(rawRow);
      expect(decoded.properties!['retry_count'], 3);
      expect(decoded.properties!['is_guest'], true);

      // The row that omits created_at decodes with it null, not with a fake.
      final sparse = events.items.firstWhere((e) => e.properties == null);
      expect(sparse.createdAt, isNull);
      expect(sparse.eventName, 'feedback_detail');
    });

    test('measure() returns double?, asserted statically over the source', () {
      final source =
          stripComments(File('lib/src/models/metrics.dart').readAsStringSync());
      expect(source.length, greaterThan(0), reason: 'the stripper looked');
      expect(source.contains('double? measure('), isTrue);
      expect(
        source.contains('double measure('),
        isFalse,
        reason: 'a non-optional accessor crashes on the overflow row',
      );
      expect(
        RegExp(r'double\? measure\(').allMatches(source).length,
        3,
        reason: 'summary, series point and breakdown item',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // G5 — the two error bodies
  // ---------------------------------------------------------------------------

  group(
      'G5 · both error bodies, cardinality exactly 2, and the 403 that '
      'arrives in both', () {
    late Map<String, dynamic> corpus;

    setUp(() => corpus = loadCorpus('metrics-error-wire-corpus.json'));

    /// The corpus's `middleware` rows, each `{http_status, source, body}`.
    ///
    /// This list used to be shadowed by a hand-written
    /// `const middlewareStatuses = <int>[401, 403, 403, 404, 429, 500]` — a second
    /// copy of `C6`'s prose, paired to rows by index. Each row now carries its own
    /// `http_status`, derived by the generator from the server source line the
    /// `reason` occurs on, so nothing here restates the contract.
    List<Map<String, dynamic>> middlewareRows() =>
        (corpus['middleware'] as List<dynamic>).cast<Map<String, dynamic>>();

    /// One row, selected **by content** — never by index.
    Map<String, dynamic> middlewareRow(String reasonFragment) {
      final matches = middlewareRows()
          .where((r) => (r['body'] as Map<String, dynamic>)['reason']
              .toString()
              .contains(reasonFragment),)
          .toList();
      expect(matches, hasLength(1),
          reason: 'ambiguous fragment: $reasonFragment',);
      return matches.single;
    }

    /// Drives the REAL transport: the mock answers, `_handleResponse` decodes.
    Future<Object> errorFrom(Map<String, dynamic> body, int status) async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode(body),
          status,
          headers: const {'content-type': 'application/json'},
        ),
      );
      final transport = FeedbackKitHttpClient(
        config: const FeedbackKitConfig(apiKey: 'fixture-key'),
        client: client,
      );
      Object? thrown;
      try {
        await transport.get<dynamic>('/metrics/summary');
      } catch (e) {
        thrown = e;
      }
      expect(thrown, isNotNull, reason: 'expected a throw for status $status');
      return thrown!;
    }

    /// The status for an enveloped row, DERIVED from the corpus's own
    /// vocabulary table rather than typed in here.
    int statusForToken(String token) {
      final vocabulary = corpus['vocabulary'] as List<dynamic>;
      final matches = vocabulary
          .cast<Map<String, dynamic>>()
          .where((v) => v['wire_token'] == token)
          .map((v) => v['http_status'] as int)
          .toSet();
      expect(
        matches.length,
        1,
        reason: 'the token must map to exactly one status: $token',
      );
      return matches.single;
    }

    Map<String, dynamic> envelopedWith(String token, {bool? withField}) {
      final rows = (corpus['enveloped'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where(
            (r) =>
                (r['error'] as Map<String, dynamic>)['code'] == token &&
                (withField == null ||
                    (r['error'] as Map<String, dynamic>).containsKey('field') ==
                        withField),
          )
          .toList();
      expect(rows, isNotEmpty, reason: 'no corpus row carries $token');
      return rows.first;
    }

    test(
        'the set of JSON types of the top-level `error` has cardinality '
        'exactly 2', () {
      // The load-bearing gate. A one-shape decoder passes any presence oracle;
      // only cardinality catches it.
      // Enveloped rows ARE the wire body; middleware rows WRAP it under `body`.
      final types = <String>{};
      var examined = 0;
      for (final r in (corpus['enveloped'] as List<dynamic>)
          .cast<Map<String, dynamic>>()) {
        final error = r['error'];
        types.add(error is Map ? 'object' : error.runtimeType.toString());
        examined++;
      }
      for (final r in middlewareRows()) {
        final error = (r['body'] as Map<String, dynamic>)['error'];
        types.add(error is Map ? 'object' : error.runtimeType.toString());
        examined++;
      }
      expect(examined, greaterThan(0), reason: 'the denominator');
      // Derived from the corpus, not typed: the `enveloped` section is a total
      // cover of the 17 wire tokens (plus the second, field-less
      // METRICS_CUSTOM_EVENTS_REQUIRE_PRO row), so a literal here would have to
      // be edited every time the server's error vocabulary grows.
      expect(
        examined,
        (corpus['enveloped'] as List<dynamic>).length +
            (corpus['middleware'] as List<dynamic>).length,
      );
      expect(types, {'object', 'bool'});
      expect(types.length, 2);
    });

    test('shape A 402 becomes a PaymentRequiredError carrying the WIRE code',
        () async {
      // Before this phase this threw a TypeError inside _handleResponse and
      // surfaced as NetworkError('Unexpected error: …'), losing the message and
      // the code entirely.
      final body =
          envelopedWith('METRICS_CUSTOM_EVENTS_REQUIRE_PRO', withField: true);
      final error = await errorFrom(
        body,
        statusForToken('METRICS_CUSTOM_EVENTS_REQUIRE_PRO'),
      );
      expect(error, isNot(isA<NetworkError>()));
      expect(error, isA<PaymentRequiredError>());
      final e = error as PaymentRequiredError;
      expect(e.code, 'METRICS_CUSTOM_EVENTS_REQUIRE_PRO');
      expect(e.field, 'dimension');
      expect(e.statusCode, 402);
      expect(e.message, (body['error'] as Map<String, dynamic>)['message']);
    });

    test('the field-less 402 decodes with field null, not with an invention',
        () async {
      final body =
          envelopedWith('METRICS_CUSTOM_EVENTS_REQUIRE_PRO', withField: false);
      final error = await errorFrom(
        body,
        statusForToken('METRICS_CUSTOM_EVENTS_REQUIRE_PRO'),
      );
      expect(error, isA<PaymentRequiredError>());
      expect((error as PaymentRequiredError).field, isNull);
      expect(error.code, 'METRICS_CUSTOM_EVENTS_REQUIRE_PRO');
    });

    test('shape A 400 keeps its own token — not the class default', () async {
      final body = envelopedWith('METRICS_UNKNOWN_MEASURE');
      final error =
          await errorFrom(body, statusForToken('METRICS_UNKNOWN_MEASURE'));
      expect(error, isA<ValidationError>());
      expect((error as ValidationError).code, 'METRICS_UNKNOWN_MEASURE');
      expect(error.field, 'measures');
    });

    test('403 arrives in BOTH shapes and stays distinguishable', () async {
      // Shape A: the measure rejection, with a machine-readable token.
      final envelopedBody = envelopedWith('METRICS_MEASURE_REQUIRES_BEARER');
      final fromEnvelope = await errorFrom(
        envelopedBody,
        statusForToken('METRICS_MEASURE_REQUIRES_BEARER'),
      );
      expect(fromEnvelope, isA<ForbiddenError>());
      expect(
        (fromEnvelope as ForbiddenError).code,
        'METRICS_MEASURE_REQUIRES_BEARER',
      );
      expect(fromEnvelope.field, 'measures');

      // Shape B: the suspended-project denial, with no code at all.
      final suspendedRow = middlewareRow('suspended');
      final suspended = suspendedRow['body'] as Map<String, dynamic>;
      expect(suspendedRow['http_status'], 403);
      final fromMiddleware =
          await errorFrom(suspended, suspendedRow['http_status'] as int);
      expect(fromMiddleware, isA<ForbiddenError>());
      expect((fromMiddleware as ForbiddenError).code, 'FORBIDDEN');
      expect(fromMiddleware.field, isNull);
      expect(fromMiddleware.message, suspended['reason']);

      // The two outcomes are distinguishable — which a status-code branch could
      // never manage.
      expect(fromEnvelope.code == fromMiddleware.code, isFalse);
    });

    test('every shape B row maps to its documented status and keeps its reason',
        () async {
      final middleware = middlewareRows();
      expect(middleware.length, 6, reason: 'the denominator');
      expect(middlewareRow('Invalid API key'), isNotNull);
      expect(middlewareRow('not found'), isNotNull);
      expect(middlewareRow('Too many requests'), isNotNull);
      // Sorted multiset, not a sequence: 403 legitimately repeats, and coupling
      // this to row order would re-introduce the positional dependency removed here.
      expect(
        middleware.map((r) => r['http_status'] as int).toList()..sort(),
        [401, 403, 403, 404, 429, 500],
      );

      final observed = <String>[];
      for (var i = 0; i < middleware.length; i++) {
        final body = middleware[i]['body'] as Map<String, dynamic>;
        final error =
            await errorFrom(body, middleware[i]['http_status'] as int);
        final e = error as FeedbackKitError;
        expect(
          e.message,
          body['reason'],
          reason: 'the reason is the message on shape B',
        );
        expect(e.field, isNull, reason: 'shape B carries no field');
        observed.add('${e.runtimeType}/${e.code}');
      }

      // Asserted as one whole vector: a per-iteration assertion under-reports,
      // surfacing only the first failure of several.
      expect(observed, [
        'AuthenticationError/UNAUTHORIZED',
        'ForbiddenError/FORBIDDEN',
        'ForbiddenError/FORBIDDEN',
        'NotFoundError/NOT_FOUND',
        'RateLimitError/RATE_LIMITED',
        'ServerError/SERVER_ERROR',
      ]);
    });

    test('429 carries Retry-After when the server sends the seconds form',
        () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode(
            middlewareRow('Too many requests')['body'],
          ),
          429,
          headers: const {
            'content-type': 'application/json',
            'retry-after': '17',
          },
        ),
      );
      final transport = FeedbackKitHttpClient(
        config: const FeedbackKitConfig(apiKey: 'fixture-key'),
        client: client,
      );
      Object? thrown;
      try {
        await transport.get<dynamic>('/metrics/summary');
      } catch (e) {
        thrown = e;
      }
      expect(thrown, isA<RateLimitError>());
      expect((thrown! as RateLimitError).statusCode, 429);
      expect((thrown as RateLimitError).retryAfterSeconds, 17);
    });

    test(
        'the error-class set is the shipped baseline plus exactly '
        'RateLimitError', () {
      final source = stripComments(
        File('lib/src/errors/feedbackkit_error.dart').readAsStringSync(),
      );
      expect(source.length, greaterThan(0), reason: 'the stripper looked');
      final declared = RegExp(r'class (\w+) extends FeedbackKitError')
          .allMatches(source)
          .map((m) => m.group(1)!)
          .toSet();

      const shippedBaseline = <String>{
        'AuthenticationError',
        'PaymentRequiredError',
        'ForbiddenError',
        'NotFoundError',
        'ConflictError',
        'ValidationError',
        'NetworkError',
        'ServerError',
      };
      expect(shippedBaseline.length, 8);
      // Set equality, both directions: a tenth class must red here.
      expect(declared, shippedBaseline.union({'RateLimitError'}));
      expect(declared.length, 9);
    });

    test('the transport branches on the TYPE of error, not on the status code',
        () {
      final source = stripComments(
        File('lib/src/http/http_client.dart').readAsStringSync(),
      );
      expect(source.length, greaterThan(0), reason: 'the stripper looked');
      expect(source.contains('if (error is Map<String, dynamic>)'), isTrue);
      // The shipped cast that crashed on every enveloped body is gone.
      expect(source.contains("data['error'] as String?"), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // G6 — the absence D2 requires
  // ---------------------------------------------------------------------------

  group(
      'G6 · no bucket-start field exists anywhere, and the leg proves it '
      'read something', () {
    test('zero occurrences across every dart file under lib/ and test/', () {
      // The needles are assembled rather than written, so this file does not
      // trip its own gate — the self-trip trap that has fired repeatedly in
      // this ladder.
      const snakeNeedle = 'bucket${'_'}start';
      const camelNeedle = 'bucket${'S'}tart';

      final files = dartFilesUnder(['lib', 'test']);
      var bytes = 0;
      var hits = 0;
      for (final file in files) {
        final source = stripComments(file.readAsStringSync());
        bytes += source.length;
        if (source.contains(snakeNeedle) || source.contains(camelNeedle)) {
          hits++;
        }
      }
      expect(files.length, greaterThan(0), reason: 'the denominator');
      expect(
        files.length,
        Directory('lib')
                .listSync(recursive: true)
                .whereType<File>()
                .where((f) => f.path.endsWith('.dart'))
                .length +
            Directory('test')
                .listSync(recursive: true)
                .whereType<File>()
                .where((f) => f.path.endsWith('.dart'))
                .length,
      );
      expect(bytes, greaterThan(0), reason: 'the stripper did not empty them');
      expect(hits, 0);
    });

    test('a series point serialises exactly two keys', () {
      const point = MetricSeriesPoint(
        bucket: '2023-11-12',
        values: {'event_count': 91},
      );
      expect(point.toJson().keys.toSet(), {'bucket', 'values'});
      expect(point.toJson().keys.length, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // G7 — the operations, the constants, the vocabularies
  // ---------------------------------------------------------------------------

  group('G7 · four operations and three constants, by set equality', () {
    test('the operation set equals the contract\'s four — not a superset', () {
      final source = stripComments(
        File('lib/src/api/metrics_api.dart').readAsStringSync(),
      );
      expect(source.length, greaterThan(0), reason: 'the stripper looked');
      final methods = RegExp(r'^\s*Future<[^>]+>\s+(\w+)\(', multiLine: true)
          .allMatches(source)
          .map((m) => m.group(1)!)
          .toSet();
      expect(methods, {'summary', 'timeseries', 'breakdown', 'events'});
      expect(methods.length, 4);
    });

    test('the four paths are the key family\'s, once each, with no Bearer path',
        () {
      final source = File('lib/src/api/metrics_api.dart').readAsStringSync();
      expect(source.length, greaterThan(0), reason: 'the denominator');
      for (final path in [
        '/metrics/summary',
        '/metrics/timeseries',
        '/metrics/breakdown',
        '/metrics/events',
      ]) {
        expect(RegExp("'$path'").allMatches(source).length, 1, reason: path);
      }
      // The Bearer family needs a project id this SDK cannot supply.
      expect(source.contains('projects/'), isFalse);
      expect(source.contains('projectId'), isFalse);
    });

    test('the three predefined names are exact, ordered, and defined once', () {
      expect(
        PredefinedEventNames.all,
        ['feedback_list', 'feedback_detail', 'submit_feedback'],
      );
      expect(PredefinedEventNames.all.length, 3);

      // Count the QUOTED needle. The bare substrings are also FILE names in
      // this package — feedback_list.dart and friends — so an unquoted census
      // reads 3 files and reds on arrival, and its failure looks like a
      // duplicate definition that does not exist.
      final files = dartFilesUnder(['lib']);
      expect(files.length, greaterThan(0), reason: 'the denominator');
      for (final name in PredefinedEventNames.all) {
        final defining = files
            .where((f) => f.readAsStringSync().contains("'$name'"))
            .map((f) => f.path)
            .toList();
        expect(
          defining.length,
          1,
          reason: 'two copies of a string set is how one goes stale: $name',
        );
        expect(defining.single, endsWith('predefined_event_names.dart'));
      }
    });

    test('the four closed vocabularies equal the contract\'s, by set equality',
        () {
      expect(MetricMeasure.values.map((m) => m.toJson()).toSet(), {
        'feedback_count',
        'vote_count',
        'comment_count',
        'event_count',
        'unique_event_users',
        'sdk_user_count',
        'mrr_sum',
        'mrr_average',
        'users_with_mrr',
      });
      expect(MetricMeasure.values.length, 9);

      expect(
        MetricDimension.values.map((d) => d.toJson()).toSet(),
        {'status', 'category', 'event_name'},
      );
      expect(MetricDimension.values.length, 3);

      // The wire tokens are hour/day/week/month. The server's own Swift case
      // names are hourly/daily/… and sending one of those is a 400.
      expect(
        MetricGranularity.values.map((g) => g.toJson()).toSet(),
        {'hour', 'day', 'week', 'month'},
      );
      expect(MetricGranularity.values.length, 4);
      expect(
        MetricGranularity.values
            .map((g) => g.toJson())
            .any((t) => t.endsWith('ly')),
        isFalse,
      );

      expect(
        MetricEventScope.values.map((s) => s.toJson()).toSet(),
        {'all', 'predefined_only'},
      );
      expect(MetricEventScope.values.length, 2);
    });

    test('every vocabulary round-trips and rejects an unknown token', () {
      for (final m in MetricMeasure.values) {
        expect(MetricMeasure.fromJson(m.toJson()), m);
      }
      expect(
        () => MetricMeasure.fromJson('mrr_median'),
        throwsA(isA<Exception>()),
      );
      expect(
        () => MetricGranularity.fromJson('daily'),
        throwsA(isA<Exception>()),
      );
      expect(
        () => MetricEventScope.fromJson('none'),
        throwsA(isA<Exception>()),
      );
      expect(
        () => MetricDimension.fromJson('platform'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // G8 — the event feed's two meta blocks
  // ---------------------------------------------------------------------------

  group(
      'G8 · the event feed carries two meta blocks, and conflating them '
      'throws', () {
    late Map<String, dynamic> corpus;

    setUp(() => corpus = loadCorpus('metrics-wire-corpus.json'));

    test('both blocks land, in the right fields, with the right types', () {
      final feed = MetricEventList.fromJson(row(corpus, 'events_page'));
      expect(feed.meta, isA<MetricsPaginationMeta>());
      expect(feed.metrics, isA<MetricsMeta>());
      expect(feed.meta.totalPages, 3);
      expect(feed.meta.total, 137);
      expect(feed.meta.page, 2);
      expect(feed.meta.perPage, 50);
      expect(feed.metrics.retentionWindowDays, 30);
      expect(feed.metrics.granularity, isNull);
      expect(feed.items.length, 2);
    });

    test(
        'moving the metrics block under meta throws — tolerance is not '
        'blindness', () {
      final mutated = Map<String, dynamic>.from(row(corpus, 'events_page'));
      mutated['meta'] = mutated['metrics'];
      expect(
        () => MetricEventList.fromJson(mutated),
        throwsA(isA<TypeError>()),
      );
    });

    test('the pagination block serialises exactly four keys', () {
      const meta = MetricsPaginationMeta(
        total: 137,
        page: 2,
        perPage: 50,
        totalPages: 3,
      );
      expect(
        meta.toJson().keys.toSet(),
        {'total', 'page', 'per_page', 'total_pages'},
      );
    });
  });

  // ---------------------------------------------------------------------------
  // End to end, through the real transport
  // ---------------------------------------------------------------------------

  group('the four operations decode the corpus through the real transport', () {
    late Map<String, dynamic> corpus;

    setUp(() => corpus = loadCorpus('metrics-wire-corpus.json'));

    Future<T> drive<T>(
      Map<String, dynamic> body,
      Future<T> Function(MetricsApi api) call,
      void Function(Uri uri) inspect,
    ) async {
      final client = MockClient((request) async {
        inspect(request.url);
        return http.Response(
          jsonEncode(body),
          200,
          headers: const {'content-type': 'application/json'},
        );
      });
      final api = MetricsApi(
        FeedbackKitHttpClient(
          config: const FeedbackKitConfig(apiKey: 'fixture-key'),
          client: client,
        ),
      );
      return call(api);
    }

    test('summary', () async {
      Uri? seen;
      final result = await drive(
        row(corpus, 'summary_free_scoped_and_clamped'),
        (api) => api.summary(
          MetricSummaryOptions(
            measures: const [MetricMeasure.eventCount],
            days: 30,
          ),
        ),
        (uri) => seen = uri,
      );
      expect(seen!.path, '/api/v1/metrics/summary');
      expect(seen!.queryParameters, {'measures': 'event_count', 'days': '30'});
      expect(result.meta.eventScope, MetricEventScope.predefinedOnly);
      expect(result.meta.retentionClamped, isTrue);
      expect(result.measure(MetricMeasure.feedbackCount), 10);
    });

    test('timeseries', () async {
      Uri? seen;
      final result = await drive(
        row(corpus, 'timeseries_daily'),
        (api) => api.timeseries(
          MetricTimeseriesOptions(
            measures: const [
              MetricMeasure.feedbackCount,
              MetricMeasure.eventCount,
            ],
            granularity: MetricGranularity.day,
          ),
        ),
        (uri) => seen = uri,
      );
      expect(seen!.queryParameters['granularity'], 'day');
      expect(result.series.length, 3);
      expect(result.meta.granularity, 'day');
    });

    test('breakdown', () async {
      Uri? seen;
      final result = await drive(
        row(corpus, 'breakdown_event_name_with_overflow'),
        (api) => api.breakdown(
          MetricBreakdownOptions(
            measures: const [MetricMeasure.eventCount],
            dimension: MetricDimension.eventName,
          ),
        ),
        (uri) => seen = uri,
      );
      expect(seen!.queryParameters['dimension'], 'event_name');
      expect(result.items.length, 2);
      expect(result.meta.truncated, isTrue);
    });

    test('events', () async {
      Uri? seen;
      final result = await drive(
        row(corpus, 'events_page'),
        (api) => api.events(MetricEventsOptions(page: 2, perPage: 50)),
        (uri) => seen = uri,
      );
      expect(seen!.queryParameters, {'page': '2', 'per_page': '50'});
      expect(result.items.first.eventName, 'checkout_completed');
      expect(result.meta.page, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // G11 — no UI, no logging, no hand-written fixtures, no hardcoded retention
  // ---------------------------------------------------------------------------

  group('G11 · this phase added no UI, no logging and no hardcoded retention',
      () {
    const newLibFiles = <String>[
      'lib/src/models/metrics.dart',
      'lib/src/models/predefined_event_names.dart',
      'lib/src/api/metrics_api.dart',
    ];

    test('no logging call site was added', () {
      var bytes = 0;
      final offenders = <String>[];
      for (final path in newLibFiles) {
        final source = stripComments(File(path).readAsStringSync());
        bytes += source.length;
        for (final needle in ['print(', 'debugPrint(', 'log(']) {
          if (source.contains(needle)) offenders.add('$path:$needle');
        }
      }
      expect(bytes, greaterThan(0), reason: 'the denominator');
      expect(offenders, isEmpty);
    });

    test('no retention allowance is hardcoded in the new sources', () {
      var bytes = 0;
      final offenders = <String>[];
      for (final path in newLibFiles) {
        final source = stripComments(File(path).readAsStringSync());
        bytes += source.length;
        if (RegExp(r'(^|[^0-9A-Za-z_])(30|365)([^0-9A-Za-z_]|$)')
            .hasMatch(source)) {
          offenders.add(path);
        }
      }
      expect(bytes, greaterThan(0), reason: 'the denominator');
      expect(
        offenders,
        isEmpty,
        reason: 'the allowance is read from retention_window_days',
      );
    });

    test('this suite hand-writes no JSON fixture', () {
      final source = File('test/metrics_test.dart').readAsStringSync();
      expect(source.length, greaterThan(0), reason: 'the denominator');
      // Every decode starts at a committed corpus file; jsonDecode is only ever
      // called on file contents.
      expect(RegExp(r"jsonDecode\('").hasMatch(source), isFalse);
      expect(RegExp(r'jsonDecode\("').hasMatch(source), isFalse);
      expect(source.contains('File(\'test/fixtures/'), isTrue);
    });

    test('no widget was added or touched by this phase', () {
      final widgets = Directory('lib/src/widgets')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      expect(widgets.length, 9,
          reason: 'the seven views plus the direction and pressable helpers',);
    });
  });
}
