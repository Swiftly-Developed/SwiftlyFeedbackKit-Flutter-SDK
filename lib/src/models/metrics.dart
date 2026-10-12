import 'unknown_enum_value_exception.dart';

// -----------------------------------------------------------------------------
// The closed vocabularies (contract C5).
//
// Each carries an explicit wire token, following the `FeedbackStatus` /
// `FeedbackCategory` convention in this package: a `toJson()` instance method
// and a throwing static `fromJson`. The tokens below are the server's, verbatim.
// -----------------------------------------------------------------------------

/// A metric measure — the quantity a metrics read asks for.
///
/// Nine members. Five are available on the `X-API-Key` surface this SDK speaks;
/// the four SDK-user and MRR measures are Bearer-only and the server answers a
/// request for one with a `403` carrying `METRICS_MEASURE_REQUIRES_BEARER`. All
/// nine are enumerated anyway so the vocabulary agrees with the server's and with
/// the other SDKs, and so that rejection is reachable from a typed call site.
enum MetricMeasure {
  feedbackCount,
  voteCount,
  commentCount,
  eventCount,
  uniqueEventUsers,
  sdkUserCount,
  mrrSum,
  mrrAverage,
  usersWithMrr;

  /// Creates a [MetricMeasure] from its wire token.
  ///
  /// Throws [UnknownEnumValueException] for a token this SDK version does not
  /// know — a tenth measure added to the server after this client shipped.
  static MetricMeasure fromJson(String value) {
    switch (value) {
      case 'feedback_count':
        return MetricMeasure.feedbackCount;
      case 'vote_count':
        return MetricMeasure.voteCount;
      case 'comment_count':
        return MetricMeasure.commentCount;
      case 'event_count':
        return MetricMeasure.eventCount;
      case 'unique_event_users':
        return MetricMeasure.uniqueEventUsers;
      case 'sdk_user_count':
        return MetricMeasure.sdkUserCount;
      case 'mrr_sum':
        return MetricMeasure.mrrSum;
      case 'mrr_average':
        return MetricMeasure.mrrAverage;
      case 'users_with_mrr':
        return MetricMeasure.usersWithMrr;
      default:
        throw UnknownEnumValueException('MetricMeasure', value);
    }
  }

  /// This measure's wire token, as sent and as keyed in a `values` map.
  String toJson() {
    switch (this) {
      case MetricMeasure.feedbackCount:
        return 'feedback_count';
      case MetricMeasure.voteCount:
        return 'vote_count';
      case MetricMeasure.commentCount:
        return 'comment_count';
      case MetricMeasure.eventCount:
        return 'event_count';
      case MetricMeasure.uniqueEventUsers:
        return 'unique_event_users';
      case MetricMeasure.sdkUserCount:
        return 'sdk_user_count';
      case MetricMeasure.mrrSum:
        return 'mrr_sum';
      case MetricMeasure.mrrAverage:
        return 'mrr_average';
      case MetricMeasure.usersWithMrr:
        return 'users_with_mrr';
    }
  }
}

/// The axis a breakdown groups by.
enum MetricDimension {
  status,
  category,
  eventName;

  /// Creates a [MetricDimension] from its wire token.
  ///
  /// Throws [UnknownEnumValueException] for an unknown token.
  static MetricDimension fromJson(String value) {
    switch (value) {
      case 'status':
        return MetricDimension.status;
      case 'category':
        return MetricDimension.category;
      case 'event_name':
        return MetricDimension.eventName;
      default:
        throw UnknownEnumValueException('MetricDimension', value);
    }
  }

  /// This dimension's wire token.
  String toJson() {
    switch (this) {
      case MetricDimension.status:
        return 'status';
      case MetricDimension.category:
        return 'category';
      case MetricDimension.eventName:
        return 'event_name';
    }
  }
}

/// The bucket width of a timeseries.
///
/// The wire tokens are `hour` / `day` / `week` / `month`. The server's own Swift
/// case names are `hourly`, `daily`, … and are deliberately **not** the tokens;
/// sending `daily` is a `400 METRICS_UNKNOWN_GRANULARITY`.
enum MetricGranularity {
  hour,
  day,
  week,
  month;

  /// Creates a [MetricGranularity] from its wire token.
  ///
  /// Throws [UnknownEnumValueException] for an unknown token.
  static MetricGranularity fromJson(String value) {
    switch (value) {
      case 'hour':
        return MetricGranularity.hour;
      case 'day':
        return MetricGranularity.day;
      case 'week':
        return MetricGranularity.week;
      case 'month':
        return MetricGranularity.month;
      default:
        throw UnknownEnumValueException('MetricGranularity', value);
    }
  }

  /// This granularity's wire token.
  String toJson() {
    switch (this) {
      case MetricGranularity.hour:
        return 'hour';
      case MetricGranularity.day:
        return 'day';
      case MetricGranularity.week:
        return 'week';
      case MetricGranularity.month:
        return 'month';
    }
  }
}

/// Which events a metrics read was allowed to count.
///
/// [predefinedOnly] means the plan scoped the read to FeedbackKit's own three
/// predefined events ([PredefinedEventNames]). It arrives on a **`200`**, never
/// as an error: the read succeeded, it simply counted less. Render an upsell from
/// this value, never from a `catch`.
enum MetricEventScope {
  all,
  predefinedOnly;

  /// Creates a [MetricEventScope] from its wire token.
  ///
  /// Throws [UnknownEnumValueException] for an unknown token.
  static MetricEventScope fromJson(String value) {
    switch (value) {
      case 'all':
        return MetricEventScope.all;
      case 'predefined_only':
        return MetricEventScope.predefinedOnly;
      default:
        throw UnknownEnumValueException('MetricEventScope', value);
    }
  }

  /// This scope's wire token.
  String toJson() {
    switch (this) {
      case MetricEventScope.all:
        return 'all';
      case MetricEventScope.predefinedOnly:
        return 'predefined_only';
    }
  }
}

// -----------------------------------------------------------------------------
// Response models (contracts C3 and C4).
// -----------------------------------------------------------------------------

/// The `meta` block every metrics response carries.
///
/// Nine fields, of which exactly one — [granularity] — is optional. It is
/// **absent** from a `summary` response and from the event feed's `metrics`
/// block; the server omits the key rather than sending `null`. It is **present**
/// on `timeseries` and on `breakdown`, where it defaults to `"day"`.
class MetricsMeta {
  /// The resolved measure tokens, in first-seen order.
  final List<String> measures;

  /// The resolved bucket width, or null when this surface does not bucket.
  ///
  /// Absent on `summary` and on the event feed. Do not read its presence as
  /// "this is a timeseries" — a breakdown carries it too.
  final String? granularity;

  /// The reporting time zone actually applied. Bucket keys are in this zone.
  final String timezone;

  /// The inclusive first instant of the window. An ISO-8601 instant, not a date.
  final DateTime dateFrom;

  /// The inclusive last instant of the window — never the exclusive end.
  final DateTime dateTo;

  /// True only when a breakdown's cardinality ceiling elided names.
  final bool truncated;

  /// Which events this read was allowed to count.
  final MetricEventScope eventScope;

  /// True when the plan narrowed the requested window.
  ///
  /// Not idempotent by design: re-requesting an already-clamped window returns
  /// the same window with this flag `false`, because that second request asks
  /// for something inside the allowance. Never derive it by comparing what you
  /// asked for against what came back.
  final bool retentionClamped;

  /// The plan's window allowance, in days (Free 30, Pro 90, Team 365). Read it — never assume one.
  final int retentionWindowDays;

  const MetricsMeta({
    required this.measures,
    this.granularity,
    required this.timezone,
    required this.dateFrom,
    required this.dateTo,
    required this.truncated,
    required this.eventScope,
    required this.retentionClamped,
    required this.retentionWindowDays,
  });

  /// Creates a [MetricsMeta] from a JSON map.
  ///
  /// Every field the contract marks required is read non-nullably and throws
  /// when absent. A missing [retentionWindowDays] is a wire-contract break, not
  /// something to paper over with a default.
  factory MetricsMeta.fromJson(Map<String, dynamic> json) {
    return MetricsMeta(
      measures: (json['measures'] as List<dynamic>)
          .map((e) => e as String)
          .toList(growable: false),
      granularity: json['granularity'] as String?,
      timezone: json['timezone'] as String,
      dateFrom: DateTime.parse(json['date_from'] as String),
      dateTo: DateTime.parse(json['date_to'] as String),
      truncated: json['truncated'] as bool,
      eventScope: MetricEventScope.fromJson(json['event_scope'] as String),
      retentionClamped: json['retention_clamped'] as bool,
      retentionWindowDays: json['retention_window_days'] as int,
    );
  }

  /// Converts this meta block to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'measures': measures,
      if (granularity != null) 'granularity': granularity,
      'timezone': timezone,
      'date_from': dateFrom.toUtc().toIso8601String(),
      'date_to': dateTo.toUtc().toIso8601String(),
      'truncated': truncated,
      'event_scope': eventScope.toJson(),
      'retention_clamped': retentionClamped,
      'retention_window_days': retentionWindowDays,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MetricsMeta &&
        _stringListEquals(other.measures, measures) &&
        other.granularity == granularity &&
        other.timezone == timezone &&
        other.dateFrom == dateFrom &&
        other.dateTo == dateTo &&
        other.truncated == truncated &&
        other.eventScope == eventScope &&
        other.retentionClamped == retentionClamped &&
        other.retentionWindowDays == retentionWindowDays;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(measures),
        granularity,
        timezone,
        dateFrom,
        dateTo,
        truncated,
        eventScope,
        retentionClamped,
        retentionWindowDays,
      );

  @override
  String toString() {
    return 'MetricsMeta(measures: $measures, granularity: $granularity, '
        'timezone: $timezone, dateFrom: $dateFrom, dateTo: $dateTo, '
        'truncated: $truncated, eventScope: $eventScope, '
        'retentionClamped: $retentionClamped, '
        'retentionWindowDays: $retentionWindowDays)';
  }
}

/// A `GET /metrics/summary` response: one `meta` block and one bag of totals.
class MetricSummary {
  /// The read's resolved parameters.
  final MetricsMeta meta;

  /// Measure token to value. Sparse by design — read it through [measure].
  final Map<String, double> values;

  const MetricSummary({
    required this.meta,
    required this.values,
  });

  /// The value of [m], or null when the server omitted it.
  double? measure(MetricMeasure m) => values[m.toJson()];

  /// Creates a [MetricSummary] from a JSON map.
  factory MetricSummary.fromJson(Map<String, dynamic> json) {
    return MetricSummary(
      meta: MetricsMeta.fromJson(json['meta'] as Map<String, dynamic>),
      values: _decodeValues(json['values']),
    );
  }

  /// Converts this summary to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'meta': meta.toJson(),
      'values': values,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MetricSummary &&
        other.meta == meta &&
        _valuesEquals(other.values, values);
  }

  @override
  int get hashCode => Object.hash(meta, _valuesHash(values));

  @override
  String toString() => 'MetricSummary(meta: $meta, values: $values)';
}

/// One bucket of a timeseries: a bucket key and that bucket's values.
///
/// [bucket] stays a [String] deliberately. Its format is the server's, in
/// `meta.timezone` — `yyyy-MM-dd HH:00` for hourly reads and `yyyy-MM-dd`
/// otherwise — and `DateTime.parse` would silently relabel it with the device's
/// zone. Render it beside `meta.timezone`; do not parse it.
class MetricSeriesPoint {
  /// The bucket key, in the response's reporting time zone.
  final String bucket;

  /// Measure token to value for this bucket. Read it through [measure].
  final Map<String, double> values;

  const MetricSeriesPoint({
    required this.bucket,
    required this.values,
  });

  /// The value of [m], or null when the server omitted it.
  double? measure(MetricMeasure m) => values[m.toJson()];

  /// Creates a [MetricSeriesPoint] from a JSON map.
  factory MetricSeriesPoint.fromJson(Map<String, dynamic> json) {
    return MetricSeriesPoint(
      bucket: json['bucket'] as String,
      values: _decodeValues(json['values']),
    );
  }

  /// Converts this point to a JSON map.
  ///
  /// Exactly two keys. The server sends no bucket-start timestamp and this model
  /// declares none.
  Map<String, dynamic> toJson() {
    return {
      'bucket': bucket,
      'values': values,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MetricSeriesPoint &&
        other.bucket == bucket &&
        _valuesEquals(other.values, values);
  }

  @override
  int get hashCode => Object.hash(bucket, _valuesHash(values));

  @override
  String toString() => 'MetricSeriesPoint(bucket: $bucket, values: $values)';
}

/// A `GET /metrics/timeseries` response.
///
/// Empty buckets are **present and zero-valued**, not omitted, so a
/// `series.isEmpty` branch never fires for a quiet project. Check the values.
class MetricSeries {
  /// The read's resolved parameters.
  final MetricsMeta meta;

  /// One entry per bucket, oldest first.
  final List<MetricSeriesPoint> series;

  const MetricSeries({
    required this.meta,
    required this.series,
  });

  /// Creates a [MetricSeries] from a JSON map.
  factory MetricSeries.fromJson(Map<String, dynamic> json) {
    return MetricSeries(
      meta: MetricsMeta.fromJson(json['meta'] as Map<String, dynamic>),
      series: (json['series'] as List<dynamic>)
          .map((e) => MetricSeriesPoint.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  /// Converts this series to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'meta': meta.toJson(),
      'series': series.map((p) => p.toJson()).toList(growable: false),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MetricSeries &&
        other.meta == meta &&
        _listEquals(other.series, series);
  }

  @override
  int get hashCode => Object.hash(meta, Object.hashAll(series));

  @override
  String toString() => 'MetricSeries(meta: $meta, series: $series)';
}

/// One row of a breakdown.
class MetricBreakdownItem {
  /// The dimension value this row aggregates, e.g. a status or an event name.
  final String key;

  /// Measure token to value for this row. Read it through [measure].
  final Map<String, double> values;

  /// True on the single synthetic row that absorbs everything past the
  /// cardinality ceiling.
  ///
  /// That row omits `unique_event_users` from [values] entirely — a distinct-user
  /// count is not additive across elided names, so no honest number exists — and
  /// [measure] returns null for it.
  final bool isOverflow;

  const MetricBreakdownItem({
    required this.key,
    required this.values,
    required this.isOverflow,
  });

  /// The value of [m], or null when the server omitted it.
  double? measure(MetricMeasure m) => values[m.toJson()];

  /// Creates a [MetricBreakdownItem] from a JSON map.
  factory MetricBreakdownItem.fromJson(Map<String, dynamic> json) {
    return MetricBreakdownItem(
      key: json['key'] as String,
      values: _decodeValues(json['values']),
      isOverflow: json['is_overflow'] as bool,
    );
  }

  /// Converts this row to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'values': values,
      'is_overflow': isOverflow,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MetricBreakdownItem &&
        other.key == key &&
        other.isOverflow == isOverflow &&
        _valuesEquals(other.values, values);
  }

  @override
  int get hashCode => Object.hash(key, isOverflow, _valuesHash(values));

  @override
  String toString() {
    return 'MetricBreakdownItem(key: $key, values: $values, '
        'isOverflow: $isOverflow)';
  }
}

/// A `GET /metrics/breakdown` response.
class MetricBreakdown {
  /// The read's resolved parameters. Carries `granularity`, inert here.
  final MetricsMeta meta;

  /// The axis the rows are grouped by.
  final MetricDimension dimension;

  /// The rows, ordered by the first requested measure, descending.
  final List<MetricBreakdownItem> items;

  const MetricBreakdown({
    required this.meta,
    required this.dimension,
    required this.items,
  });

  /// Creates a [MetricBreakdown] from a JSON map.
  factory MetricBreakdown.fromJson(Map<String, dynamic> json) {
    return MetricBreakdown(
      meta: MetricsMeta.fromJson(json['meta'] as Map<String, dynamic>),
      dimension: MetricDimension.fromJson(json['dimension'] as String),
      items: (json['items'] as List<dynamic>)
          .map((e) => MetricBreakdownItem.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  /// Converts this breakdown to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'meta': meta.toJson(),
      'dimension': dimension.toJson(),
      'items': items.map((i) => i.toJson()).toList(growable: false),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MetricBreakdown &&
        other.meta == meta &&
        other.dimension == dimension &&
        _listEquals(other.items, items);
  }

  @override
  int get hashCode => Object.hash(meta, dimension, Object.hashAll(items));

  @override
  String toString() {
    return 'MetricBreakdown(meta: $meta, dimension: $dimension, '
        'items: $items)';
  }
}

/// The event feed's pagination block — the `meta` key, not the `metrics` one.
class MetricsPaginationMeta {
  /// Total matching events across all pages.
  final int total;

  /// The 1-based page this response is.
  final int page;

  /// The page size actually applied.
  final int perPage;

  /// How many pages the window holds at this page size.
  final int totalPages;

  const MetricsPaginationMeta({
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
  });

  /// Creates a [MetricsPaginationMeta] from a JSON map.
  factory MetricsPaginationMeta.fromJson(Map<String, dynamic> json) {
    return MetricsPaginationMeta(
      total: json['total'] as int,
      page: json['page'] as int,
      perPage: json['per_page'] as int,
      totalPages: json['total_pages'] as int,
    );
  }

  /// Converts this pagination block to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'page': page,
      'per_page': perPage,
      'total_pages': totalPages,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MetricsPaginationMeta &&
        other.total == total &&
        other.page == page &&
        other.perPage == perPage &&
        other.totalPages == totalPages;
  }

  @override
  int get hashCode => Object.hash(total, page, perPage, totalPages);

  @override
  String toString() {
    return 'MetricsPaginationMeta(total: $total, page: $page, '
        'perPage: $perPage, totalPages: $totalPages)';
  }
}

/// One row of the raw event feed.
class MetricEventRow {
  /// The event's identifier.
  final String id;

  /// The event name, exactly as tracked. Case-sensitive.
  final String eventName;

  /// The end user the event is attributed to.
  final String userId;

  /// When the event was recorded, when the server sent it.
  final DateTime? createdAt;

  /// The customer's own properties, verbatim.
  ///
  /// Keys are **not** rewritten: a `checkout_step` key stays `checkout_step`.
  /// Values keep their JSON types, so this is `dynamic`, not `String`.
  final Map<String, dynamic>? properties;

  const MetricEventRow({
    required this.id,
    required this.eventName,
    required this.userId,
    this.createdAt,
    this.properties,
  });

  /// Creates a [MetricEventRow] from a JSON map.
  factory MetricEventRow.fromJson(Map<String, dynamic> json) {
    final createdAtStr = json['created_at'] as String?;
    return MetricEventRow(
      id: json['id'] as String,
      eventName: json['event_name'] as String,
      userId: json['user_id'] as String,
      createdAt: createdAtStr != null ? DateTime.parse(createdAtStr) : null,
      properties: json['properties'] as Map<String, dynamic>?,
    );
  }

  /// Converts this row to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_name': eventName,
      'user_id': userId,
      if (createdAt != null) 'created_at': createdAt!.toUtc().toIso8601String(),
      if (properties != null) 'properties': properties,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MetricEventRow &&
        other.id == id &&
        other.eventName == eventName &&
        other.userId == userId &&
        other.createdAt == createdAt &&
        _dynamicMapEquals(other.properties, properties);
  }

  @override
  int get hashCode => Object.hash(id, eventName, userId, createdAt);

  @override
  String toString() {
    return 'MetricEventRow(id: $id, eventName: $eventName, userId: $userId, '
        'createdAt: $createdAt, properties: $properties)';
  }
}

/// A `GET /metrics/events` response — the one operation with **two** meta blocks.
///
/// [meta] is pagination. [metrics] is the metrics meta every other operation
/// puts under `meta`. A model that conflates them decodes nothing usable.
class MetricEventList {
  /// This page's rows.
  final List<MetricEventRow> items;

  /// Pagination for the feed.
  final MetricsPaginationMeta meta;

  /// The read's resolved metrics parameters. `granularity` is absent here.
  final MetricsMeta metrics;

  const MetricEventList({
    required this.items,
    required this.meta,
    required this.metrics,
  });

  /// Creates a [MetricEventList] from a JSON map.
  factory MetricEventList.fromJson(Map<String, dynamic> json) {
    return MetricEventList(
      items: (json['items'] as List<dynamic>)
          .map((e) => MetricEventRow.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      meta: MetricsPaginationMeta.fromJson(
        json['meta'] as Map<String, dynamic>,
      ),
      metrics: MetricsMeta.fromJson(json['metrics'] as Map<String, dynamic>),
    );
  }

  /// Converts this page to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'items': items.map((i) => i.toJson()).toList(growable: false),
      'meta': meta.toJson(),
      'metrics': metrics.toJson(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MetricEventList &&
        other.meta == meta &&
        other.metrics == metrics &&
        _listEquals(other.items, items);
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(items), meta, metrics);

  @override
  String toString() {
    return 'MetricEventList(items: $items, meta: $meta, metrics: $metrics)';
  }
}

// -----------------------------------------------------------------------------
// Private helpers.
// -----------------------------------------------------------------------------

/// Decodes a `values` bag.
///
/// Keys pass through **untouched** — no case conversion in either direction.
/// Values widen to double so an integer count and a decimal MRR share a type.
Map<String, double> _decodeValues(dynamic raw) {
  final map = raw as Map<String, dynamic>;
  return map.map((k, v) => MapEntry(k, (v as num).toDouble()));
}

bool _valuesEquals(Map<String, double> a, Map<String, double> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) return false;
  }
  return true;
}

int _valuesHash(Map<String, double> values) {
  final keys = values.keys.toList()..sort();
  return Object.hashAll([
    for (final k in keys) ...[k, values[k]],
  ]);
}

bool _dynamicMapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}

bool _stringListEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
