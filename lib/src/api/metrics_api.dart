import '../http/http_client.dart';
import '../models/feedback_category.dart';
import '../models/feedback_status.dart';
import '../models/metrics.dart';

/// Options shared by every metrics read.
///
/// The window is either [days] **or** [dateFrom]/[dateTo] — sending both is a
/// `400 METRICS_CONFLICTING_WINDOW_PARAMS`. The SDK does not pre-empt that; the
/// server owns the boundary and its message names the parameter at fault.
///
/// A window wider than the plan allows is **not** an error: it comes back
/// clamped, with `meta.retentionClamped` true and `meta.retentionWindowDays`
/// carrying the allowance.
class MetricSummaryOptions {
  /// The measures to read. Comma-joined into one `measures` parameter.
  final List<MetricMeasure> measures;

  /// Restrict to these feedback statuses.
  final List<FeedbackStatus>? status;

  /// Restrict to these feedback categories.
  final List<FeedbackCategory>? category;

  /// Restrict to a single event name. Free-form, and length-capped at 200 by
  /// the server.
  final String? eventName;

  /// Inclusive window start, sent as an ISO-8601 instant.
  final DateTime? dateFrom;

  /// Inclusive window end, sent as an ISO-8601 instant.
  final DateTime? dateTo;

  /// A trailing window in days, as an alternative to [dateFrom]/[dateTo].
  final int? days;

  MetricSummaryOptions({
    required this.measures,
    this.status,
    this.category,
    this.eventName,
    this.dateFrom,
    this.dateTo,
    this.days,
  }) {
    _assertOrderedWindow(dateFrom, dateTo);
  }

  /// The wire parameters for `GET /metrics/summary`.
  Map<String, String?> toQueryParams() {
    return {
      'measures': _joinMeasures(measures),
      'status': _joinStatuses(status),
      'category': _joinCategories(category),
      'event_name': eventName,
      'date_from': _instant(dateFrom),
      'date_to': _instant(dateTo),
      'days': days?.toString(),
    };
  }
}

/// Options for a timeseries read.
class MetricTimeseriesOptions {
  /// The measures to read. Comma-joined into one `measures` parameter.
  final List<MetricMeasure> measures;

  /// The bucket width. The server defaults to `day` when omitted.
  final MetricGranularity? granularity;

  /// Restrict to these feedback statuses.
  final List<FeedbackStatus>? status;

  /// Restrict to these feedback categories.
  final List<FeedbackCategory>? category;

  /// Restrict to a single event name.
  final String? eventName;

  /// Inclusive window start, sent as an ISO-8601 instant.
  final DateTime? dateFrom;

  /// Inclusive window end, sent as an ISO-8601 instant.
  final DateTime? dateTo;

  /// A trailing window in days, as an alternative to [dateFrom]/[dateTo].
  final int? days;

  MetricTimeseriesOptions({
    required this.measures,
    this.granularity,
    this.status,
    this.category,
    this.eventName,
    this.dateFrom,
    this.dateTo,
    this.days,
  }) {
    _assertOrderedWindow(dateFrom, dateTo);
  }

  /// The wire parameters for `GET /metrics/timeseries`.
  Map<String, String?> toQueryParams() {
    return {
      'measures': _joinMeasures(measures),
      'granularity': granularity?.toJson(),
      'status': _joinStatuses(status),
      'category': _joinCategories(category),
      'event_name': eventName,
      'date_from': _instant(dateFrom),
      'date_to': _instant(dateTo),
      'days': days?.toString(),
    };
  }
}

/// Options for a breakdown read.
///
/// [granularity] is accepted here because the server reads it on this route and
/// echoes it into `meta` — where it is **inert**, buckets nothing, and defaults
/// to `day`. An unparseable value is still a `400` on this route.
class MetricBreakdownOptions {
  /// The measures to read. Comma-joined into one `measures` parameter.
  final List<MetricMeasure> measures;

  /// The axis to group by.
  final MetricDimension dimension;

  /// Echoed into `meta.granularity`; it does not bucket anything here.
  final MetricGranularity? granularity;

  /// Restrict to these feedback statuses.
  final List<FeedbackStatus>? status;

  /// Restrict to these feedback categories.
  final List<FeedbackCategory>? category;

  /// Restrict to a single event name.
  final String? eventName;

  /// Inclusive window start, sent as an ISO-8601 instant.
  final DateTime? dateFrom;

  /// Inclusive window end, sent as an ISO-8601 instant.
  final DateTime? dateTo;

  /// A trailing window in days, as an alternative to [dateFrom]/[dateTo].
  final int? days;

  MetricBreakdownOptions({
    required this.measures,
    required this.dimension,
    this.granularity,
    this.status,
    this.category,
    this.eventName,
    this.dateFrom,
    this.dateTo,
    this.days,
  }) {
    _assertOrderedWindow(dateFrom, dateTo);
  }

  /// The wire parameters for `GET /metrics/breakdown`.
  Map<String, String?> toQueryParams() {
    return {
      'measures': _joinMeasures(measures),
      'granularity': granularity?.toJson(),
      'dimension': dimension.toJson(),
      'status': _joinStatuses(status),
      'category': _joinCategories(category),
      'event_name': eventName,
      'date_from': _instant(dateFrom),
      'date_to': _instant(dateTo),
      'days': days?.toString(),
    };
  }
}

/// Options for the raw event feed.
class MetricEventsOptions {
  /// Optional measures to resolve alongside the feed. Omitted when empty.
  final List<MetricMeasure> measures;

  /// Restrict to these feedback statuses.
  final List<FeedbackStatus>? status;

  /// Restrict to these feedback categories.
  final List<FeedbackCategory>? category;

  /// Restrict to a single event name.
  final String? eventName;

  /// Inclusive window start, sent as an ISO-8601 instant.
  final DateTime? dateFrom;

  /// Inclusive window end, sent as an ISO-8601 instant.
  final DateTime? dateTo;

  /// A trailing window in days, as an alternative to [dateFrom]/[dateTo].
  final int? days;

  /// The 1-based page to fetch.
  final int? page;

  /// The page size, clamped **client-side** to `1...200`.
  ///
  /// That clamp is a courtesy of this SDK, not a mirror of the server: the
  /// server rejects an out-of-range value with a `400 METRICS_INVALID_PER_PAGE`
  /// and never clamps silently. The server's default is 50.
  final int? perPage;

  MetricEventsOptions({
    this.measures = const [],
    this.status,
    this.category,
    this.eventName,
    this.dateFrom,
    this.dateTo,
    this.days,
    this.page,
    int? perPage,
  }) : perPage = _clampPerPage(perPage) {
    _assertOrderedWindow(dateFrom, dateTo);
  }

  /// The wire parameters for `GET /metrics/events`.
  Map<String, String?> toQueryParams() {
    return {
      'measures': _joinMeasures(measures),
      'status': _joinStatuses(status),
      'category': _joinCategories(category),
      'event_name': eventName,
      'date_from': _instant(dateFrom),
      'date_to': _instant(dateTo),
      'days': days?.toString(),
      'page': page?.toString(),
      'per_page': perPage?.toString(),
    };
  }
}

/// API client for metrics reads.
///
/// Reached through `kit.metrics`. Every operation here is on the API-key
/// surface, which is rate limited at **60 requests per 60 seconds** — this SDK
/// adds no retry, no backoff and no automatic page-following, so a caller that
/// pages a large feed must pace itself.
class MetricsApi {
  final FeedbackKitHttpClient _http;

  MetricsApi(this._http);

  /// Reads one bag of totals for the window.
  Future<MetricSummary> summary(MetricSummaryOptions options) {
    return _http.get<MetricSummary>(
      '/metrics/summary',
      params: options.toQueryParams(),
      decoder: (data) => MetricSummary.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Reads one value per bucket across the window.
  Future<MetricSeries> timeseries(MetricTimeseriesOptions options) {
    return _http.get<MetricSeries>(
      '/metrics/timeseries',
      params: options.toQueryParams(),
      decoder: (data) => MetricSeries.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Reads the window grouped by one dimension.
  Future<MetricBreakdown> breakdown(MetricBreakdownOptions options) {
    return _http.get<MetricBreakdown>(
      '/metrics/breakdown',
      params: options.toQueryParams(),
      decoder: (data) => MetricBreakdown.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Reads one page of the raw event feed.
  Future<MetricEventList> events(MetricEventsOptions options) {
    return _http.get<MetricEventList>(
      '/metrics/events',
      params: options.toQueryParams(),
      decoder: (data) => MetricEventList.fromJson(data as Map<String, dynamic>),
    );
  }
}

String? _joinMeasures(List<MetricMeasure> measures) {
  if (measures.isEmpty) return null;
  return measures.map((m) => m.toJson()).join(',');
}

String? _joinStatuses(List<FeedbackStatus>? statuses) {
  if (statuses == null || statuses.isEmpty) return null;
  return statuses.map((s) => s.toJson()).join(',');
}

String? _joinCategories(List<FeedbackCategory>? categories) {
  if (categories == null || categories.isEmpty) return null;
  return categories.map((c) => c.toJson()).join(',');
}

String? _instant(DateTime? value) => value?.toUtc().toIso8601String();

int? _clampPerPage(int? value) {
  if (value == null) return null;
  if (value < 1) return 1;
  if (value > 200) return 200;
  return value;
}

void _assertOrderedWindow(DateTime? from, DateTime? to) {
  if (from != null && to != null && from.isAfter(to)) {
    throw ArgumentError.value(
      from,
      'dateFrom',
      'must not be after dateTo',
    );
  }
}
