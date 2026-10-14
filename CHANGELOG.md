# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2026-10-14

### Added

- **Showcase feedback list (FEEDBACK01), now the default.** Material 3 cards: a status line, the title, two lines of description, category and comment facts, and a vote pill tinted by `FeedbackKitTheme.primaryColor`. A search field and a Sort & Filter button sit above the cards. The button opens a modal bottom sheet with sort (Votes, Newest, Oldest, Comments) and Status and Category filters. Active filters show as removable chips with a Clear button. Search, sort and filters run on the device over the loaded items. Cards keep their order while a reader votes. A failed vote rolls back and shows a snackbar. Includes Showcase skeleton, filtered-empty ("No Matching Requests" with Clear Filters) and search-empty states.
- `FeedbackListStyle` (`showcase`, `classic`) on `FeedbackList.listStyle` and `FeedbackKitProvider.listStyle`.
- `FeedbackListController` and `FeedbackSortOption`, to drive search, sort and filters from host UI. `FeedbackSortFilterButton` places the Sort & Filter button in an `AppBar`. A list that owns its controller persists the sort, but never the filters.
- `FeedbackList` options for Showcase: `controller`, `showToolbar`, `showStatusBadge`, `showCategoryBadge`, `showCommentCount`, `showVoteCount`, `allowUndoVote`, `showStatusFilter`, `showCategoryFilter`. Classic ignores them.
- Showcase strings in all 11 catalogs, with CLDR plural categories for counts and locale digit grouping.

### Changed

- **The default list layout changed.** Pass `listStyle: FeedbackListStyle.classic` to keep the 1.x cards. Showcase uses the host `ColorScheme`, including dynamic color, and supports dark theme, RTL, text scaling up to 2.0, 48dp touch targets and screen-reader labels. In a `CupertinoApp` or a bare widget tree, the list supplies its own Material 3 theme, localizations and overlay. Its sheet then opens as a Cupertino modal popup.
- Minimum SDK is Dart 3.6 and Flutter 3.27.

### Fixed

- **Metrics date windows were rejected.** `dateFrom` and `dateTo` on summary, timeseries, breakdown, and the event feed were sent with a fractional second (`2023-10-16T04:00:00.000Z`). The server reads that form as `400 METRICS_INVALID_DATE`. The four operations now send whole seconds (`2023-10-16T04:00:00Z`), including when a response `meta.dateFrom` is passed into the next request. No tagged release is affected: the metrics API first ships in 2.1.0, and pub.dev 1.0.1 and tags 1.1.0 through 1.2.0 have none. This entry does not publish the package.

### Changed

- Documentation matches 2.1.0. [docs/getting-started.md](docs/getting-started.md) is the setup guide. pub.dev still serves 1.0.1. Tags 1.1.0 through 1.2.0 are not this API. This changelog entry does not publish the package.

Also first shipped in 2.1.0 (drafted earlier under the untagged 1.2.0, 1.2.1 and 1.2.2 headings):

> ⚠️ **Server precondition for the metrics API.** As of 2026-10-14 the metrics routes are on the
> server's `dev` and `testflight` branches but not on `main`, which deploys production. Until that
> merge lands, a metrics call against production answers `404`. Every other change in this release
> is unaffected.

#### Added

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

#### Changed

- Documented metrics windows are Free 30 days, Pro 90 days and Team 365 days. The client still reads `retentionWindowDays` from the response and does not hardcode them.

#### Fixed

- **Removing a vote did not reach the server.** `unvote` put `userId` on the query string. `DELETE /feedbacks/:id/votes` reads the user id from the JSON body and ignores the query, so the call failed. The body now sends `user_id`. pub.dev 1.0.1 and tags 1.0.0 through 1.2.0 are affected.
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
- **An explicit user id was replaced by whatever was already stored, and the list loaded before that id existed.** `hasVoted` and the creator's over-limit rows are decided from `X-User-Id` on the list request, so the first load was anonymous. An id passed to the provider now wins and is stored. When none is set, the SDK creates a `local_` id, the same shape the Swift SDK uses. The list waits until that id is ready. Voting with no id is refused before the request. Vote bodies send `user_id`, `subscribe_to_mailing_list`, and `mailing_list_email_types`. pub.dev 1.0.1 and tags 1.0.0 through 1.2.0 are affected.
- **The API key could be sent over cleartext.** A base URL that is not HTTPS is rejected, except loopback HTTP for a local server.
- **Vote, retry, submit, and the mailing-list checks were not buttons or checkboxes** to assistive technologies. They now are. Arabic uses a right-to-left layout. The feedback card's comment count and age follow the active catalog instead of hardcoded English.
- **The comment field allocated a new focus node on every rebuild** and never disposed it.
- **Creating a comment omitted `userId` from the body.** `CreateCommentRequest`
  sent only `content`, and the configured user id travelled in the `X-User-Id`
  header. The API requires `userId` in the JSON body, so comment create returned
  400. The request now includes `userId`: the value passed on the request, or
  the configured user id when the request omits it.
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

## [1.2.0] - 2026-10-14

### Changed

- `FeedbackStatus.fromJson` and `FeedbackCategory.fromJson` now throw `UnknownEnumValueException` for a token this SDK does not know, instead of silently mapping it to `pending` / `other`. `FeedbackApi.list` drops only the affected rows and keeps the rest in order; a malformed row still throws.

### Added

- `UnknownEnumValueException`, exported from the package.
- Cross-SDK parity tests against server-generated wire corpora, plus comment and status decoding suites.

### Fixed

- `Comment.feedbackId` is now `String?`: the server never sends `feedback_id` on comments, so it always decoded to `''`. Code that treats it as a non-null `String` needs a null check.
- The team-member badge on comments now renders: `Comment.isTeamMember` reads the server's `is_admin` key first.

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

[2.1.0]: https://github.com/Swiftly-Developed/SwiftlyFeedbackKit-Flutter-SDK/releases/tag/2.1.0
[1.2.0]: https://github.com/Swiftly-Developed/SwiftlyFeedbackKit-Flutter-SDK/releases/tag/1.2.0
[1.1.1]: https://github.com/Swiftly-Developed/SwiftlyFeedbackKit-Flutter-SDK/releases/tag/1.1.1
[1.1.0]: https://github.com/Swiftly-Developed/SwiftlyFeedbackKit-Flutter-SDK/releases/tag/1.1.0
[1.0.1]: https://github.com/Swiftly-Developed/SwiftlyFeedbackKit-Flutter-SDK/releases/tag/1.0.1
[1.0.0]: https://github.com/Swiftly-Developed/SwiftlyFeedbackKit-Flutter-SDK/releases/tag/1.0.0
