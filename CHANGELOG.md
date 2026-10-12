# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Documentation matches 1.2.2. [docs/getting-started.md](docs/getting-started.md) is the setup guide. pub.dev still serves 1.0.1, and the public GitHub repository is still 1.1.1. Neither is this API. This changelog entry does not publish the package.

## [1.2.2] - 2026-10-11

### Fixed

- **Removing a vote did not reach the server.** `unvote` put `userId` on the query string. `DELETE /feedbacks/:id/votes` reads the user id from the JSON body and ignores the query, so the call failed. The body now sends `user_id`. Published 1.0.0 and 1.0.1 are affected, as is every later revision through 1.2.1.
- **Custom events were stored under the wrong keys, and decoding one crashed.** Track requests sent `name` and `timestamp` and omitted `user_id`. The route requires `event_name` and `user_id`, and stores `properties` as strings. Numeric and boolean properties are now written as strings. `TrackedEvent.fromJson` reads `event_name`. Same affected versions.
- **A submitted email never reached the server.** Create-feedback sent `email` where the API reads `user_email`, so the address was stored empty and mailing-list sync never saw it. The create body now uses `user_email`, `user_id`, `subscribe_to_mailing_list`, and `mailing_list_email_types`. Same affected versions.
- **Feedback responses dropped `user_email`.** `FeedbackItem.userEmail` reads that field, and stays null when the server omits it.
- `votes.vote` sent `notify_on_status_change`, which the server does not bind to
  `notifyStatusChange`. The flag is now `notify_status_change`, and an optional
  `email` is sent with it. The old `notifyOnStatusChange` argument still compiles
  and sends the corrected key.
- `users.register` sent `id`, `email`, and `name`. `POST /users/register` accepts
  `user_id` and an optional `mrr` only. `email` and `name` remain as deprecated
  arguments and are not sent. The old `id` argument still compiles as an alias
  for `userId`.
- **An explicit user id was replaced by whatever was already stored, and the list loaded before that id existed.** `hasVoted` and the creator's over-limit rows are decided from `X-User-Id` on the list request, so the first load was anonymous. An id passed to the provider now wins and is stored. When none is set, the SDK creates a `local_` id, the same shape the Swift SDK uses. The list waits until that id is ready. Voting with no id is refused before the request. Vote bodies send `user_id`, `subscribe_to_mailing_list`, and `mailing_list_email_types`. Published 1.0.0 and 1.0.1 are affected, as is every later revision through 1.2.1.
- **The API key could be sent over cleartext.** A base URL that is not HTTPS is rejected, except loopback HTTP for a local server.
- **Vote, retry, submit, and the mailing-list checks were not buttons or checkboxes** to assistive technologies. They now are. Arabic uses a right-to-left layout. The feedback card's comment count and age follow the active catalog instead of hardcoded English.
- **The comment field allocated a new focus node on every rebuild** and never disposed it.
- **The example app contained a project API key.** It is a placeholder now.

## [1.2.1] - 2026-10-10

### Fixed

- **Creating a comment omitted `userId` from the body.** `CreateCommentRequest`
  sent only `content`, and the configured user id travelled in the `X-User-Id`
  header. The API requires `userId` in the JSON body, so comment create returned
  400. The request now includes `userId`: the value passed on the request, or
  the configured user id when the request omits it.

## [1.2.0] - 2026-08-25

> ⚠️ **Release precondition — read before upgrading.** This version's headline feature is the
> metrics read API, and the metrics endpoints are **not yet deployed to every environment**.
> Measured 2026-08-25: the development API serves them; the **testflight and production APIs
> answer `404`** to `/api/v1/metrics/summary` while their `/health` answers `200`, so the routes
> are genuinely absent rather than the service being down. Until that deploy lands, a metrics call
> against production fails. Every other change in this release is unaffected.

### Changed

- Documented metrics windows are Free 30 days, Pro 90 days and Team 365 days. The client still reads `retentionWindowDays` from the response and does not hardcode them.

### Added

- `kit.metrics` — a metrics read API with four operations (`summary`,
  `timeseries`, `breakdown`, `events`) on the API-key surface, with typed
  options and models: `MetricsMeta`, `MetricSummary`, `MetricSeries`,
  `MetricSeriesPoint`, `MetricBreakdown`, `MetricBreakdownItem`,
  `MetricEventList`, `MetricEventRow` and `MetricsPaginationMeta`.
- Closed vocabularies for the metrics surface: `MetricMeasure` (9),
  `MetricDimension` (3), `MetricGranularity` (4) and `MetricEventScope` (2), each
  with its exact wire token, so a measure or granularity cannot be mistyped into
  a silent default.
- Optional-returning measure accessors — `double? measure(MetricMeasure)` on
  every type carrying a `values` map. The server omits `unique_event_users` from
  a breakdown's overflow row by design, and that sparsity reaches the caller as
  a `null` rather than a crash.
- `PredefinedEventNames` — the three event names every plan can read
  (`feedback_list`, `feedback_detail`, `submit_feedback`), exact and
  case-sensitive, so they need not be spelled by hand.
- `FeedbackKitError.field`, and a `code` that now carries the server's own
  machine-readable token when the response used the detailed error envelope.
  A `402 METRICS_CUSTOM_EVENTS_REQUIRE_PRO` and a
  `403 METRICS_MEASURE_REQUIRES_BEARER` are finally distinguishable.

### Fixed

- **Enveloped error responses reached callers as a generic `NetworkError`, with
  the server's message and error code lost.** The transport built the error
  message by casting `error` to `String?`, which throws when the server sends
  the detailed envelope (`{"error": {"code", "message", "field"}}`); the
  resulting `TypeError` was caught by the outer handler and rethrown as
  `NetworkError('Unexpected error: …')`. The transport now branches on the JSON
  type of `error` — which is also the only way to tell the two shapes of `403`
  apart, since a status-code branch cannot. This affected every operation in the
  SDK, not only the new ones.
- **`429 Too Many Requests` had no mapping** and fell through to the generic
  `FeedbackKitError` with code `UNKNOWN_ERROR`, where no caller could recognise
  it. It now raises `RateLimitError`, carrying `retryAfterSeconds` when the
  server sends `Retry-After` in the integer-seconds form. The SDK still performs
  no retry or backoff of its own.

## [1.1.1] - 2026-04-24

### Changed

- Version alignment with Swift SDK 1.1.1 hotfix (Xcode 26 / Swift 6.2 compatibility). No functional changes to this SDK.

## [1.1.0] - 2026-04-15

### Added

- CONTRIBUTING.md with contribution guidelines
- SECURITY.md with vulnerability reporting policy
- CODE_OF_CONDUCT.md (Contributor Covenant v2.1)
- SUPPORT.md with support channels
- Topics metadata for pub.dev discoverability

### Changed

- Migrated API URLs to getfeedbackkit.com
- Standardized LICENSE copyright year to 2025
- Reformatted CHANGELOG to Keep a Changelog standard
- Standardized documentation across all FeedbackKit SDKs

## [1.0.1] - 2026-02-09

### Changed

- Updated production URLs
- Bumped version for republishing

## [1.0.0] - 2026-02-08

### Added

- Initial release of FeedbackKit Flutter SDK
- FeedbackKit client with full API support
- FeedbackKitProvider for easy integration
- Pre-built widgets: FeedbackList, FeedbackCard, FeedbackDetailView, SubmitFeedbackView
- StatusBadge and CategoryBadge widgets
- VoteButton with optimistic updates
- Customizable theming with light and dark mode support
- User ID management with persistence
- Event tracking
- Comprehensive error handling

[1.1.1]: https://github.com/Swiftly-Developed/SwiftlyFeedbackKit-Flutter-SDK/releases/tag/1.1.1
[1.1.0]: https://github.com/Swiftly-Developed/SwiftlyFeedbackKit-Flutter-SDK/releases/tag/1.1.0
[1.0.1]: https://github.com/Swiftly-Developed/SwiftlyFeedbackKit-Flutter-SDK/releases/tag/1.0.1
[1.0.0]: https://github.com/Swiftly-Developed/SwiftlyFeedbackKit-Flutter-SDK/releases/tag/1.0.0
