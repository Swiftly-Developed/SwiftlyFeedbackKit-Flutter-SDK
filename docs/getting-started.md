# Getting started with the Flutter SDK

This guide matches **feedbackkit_flutter 2.1.0** in this repository. It covers install, setup, user ids, the list, submit, votes (including status-change email), comments, events, widgets, errors, and plan limits.

A shorter API listing lives in the [package README](../README.md). The runnable app is [example/lib/main.dart](../example/lib/main.dart).

## Which copy you have

| Source | Version | Matches this guide |
| --- | --- | --- |
| This repository (`SwiftlyFeedbackKit-Flutter/`) | **2.1.0** | Yes |
| [pub.dev `feedbackkit_flutter`](https://pub.dev/packages/feedbackkit_flutter) | **1.0.1** (9 February 2026) | No |
| [SwiftlyFeedbackKit-Flutter-SDK](https://github.com/Swiftly-Developed/SwiftlyFeedbackKit-Flutter-SDK) tag `2.1.0` and `main` | **2.1.0** (tagged 14 October 2026) | Yes |
| [SwiftlyFeedbackKit-Flutter-SDK](https://github.com/Swiftly-Developed/SwiftlyFeedbackKit-Flutter-SDK) tags `1.1.x` and `1.2.0` | **1.1.0**, **1.1.1**, **1.2.0** (1.2.0 tagged 14 October 2026) | No |

`flutter pub add feedbackkit_flutter` installs **1.0.1**. A `^2.1.0` constraint does not resolve on pub.dev, because 2.1.0 is not published. A git dependency on tag **1.1.x** or **1.2.0** is not this API. Use `ref: 2.1.0`.

1.0.1 has no `locale`, no `translations`, no mailing-list fields, no metrics API, and no `local_` anonymous id. Its vote call cannot take an `email`, and it sends `notify_on_status_change`, which the server does not bind to `notifyStatusChange`. Its example hardcodes a project API key. Treat that key as public and rotate it. This checkout's example uses the placeholder `your-api-key-here`.

Tags 1.1.1 and 1.2.0 on the public repository add `locale`, `translations`, and mailing-list fields, and they still use the old vote and event wire keys. They have no metrics API. 1.1.1's example still contains that same project API key. 1.2.0's uses a placeholder.

## Install

From an app that sits next to this repository:

```yaml
dependencies:
  feedbackkit_flutter:
    path: ../SwiftlyFeedbackKit-Flutter
```

Then:

```bash
flutter pub get
```

Without this checkout, use the public repository's `2.1.0` tag:

```yaml
dependencies:
  feedbackkit_flutter:
    git:
      url: https://github.com/Swiftly-Developed/SwiftlyFeedbackKit-Flutter-SDK.git
      ref: 2.1.0
```

Requirements: Flutter 3.27.0 or newer, Dart 3.6.0 or newer.

The SDK depends on `http` and `shared_preferences`. `shared_preferences` is where the user id is kept across launches.

Release builds need network permission. The Flutter template puts `INTERNET` in the debug and profile manifests only. Add this to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

On macOS, `com.apple.security.network.client` must be in both `DebugProfile.entitlements` and `Release.entitlements`.

## Setup

`FeedbackKitProvider` builds the client, holds list and vote state, and publishes them with an `InheritedWidget`. It is not the `provider` package. Put it above `MaterialApp`.

```dart
import 'package:feedbackkit_flutter/feedbackkit_flutter.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeedbackKitProvider(
      apiKey: 'your-api-key',
      child: MaterialApp(
        home: Scaffold(
          body: FeedbackList(),
        ),
      ),
    );
  }
}
```

Read the key from the environment if you would rather not commit it. An empty string is still sent, and the server answers 401.

```dart
FeedbackKitProvider(
  apiKey: const String.fromEnvironment('FEEDBACKKIT_API_KEY'),
  child: const MaterialApp(home: FeedbackList()),
)
```

Pass it at build time with `--dart-define=FEEDBACKKIT_API_KEY=your-api-key`. The value is still compiled into the binary. It is a project key, sent as `X-API-Key`, and it is meant to live in the app. Never paste a real key into the README or the example.

| Parameter | Type | Required | What it does |
| --- | --- | --- | --- |
| `apiKey` | `String` | Yes | Sent as `X-API-Key` |
| `child` | `Widget` | Yes | Usually your `MaterialApp` |
| `userId` | `String?` | No | Wins over a stored id. See below |
| `baseUrl` | `String?` | No | Defaults to `https://api.prod.getfeedbackkit.com/api/v1` |
| `theme` | `FeedbackKitTheme?` | No | `FeedbackKitTheme.dark` is a preset |
| `locale` | `String?` | No | Catalog locale, for example `ar` or `pt-BR` |
| `translations` | `Map<String, String>?` | No | Replaces individual catalog strings |

`locale` and `translations` exist on this checkout. They do not exist on pub.dev 1.0.1.

A base URL that is not HTTPS is rejected, so the API key is not sent in cleartext. `http://localhost`, `http://127.0.0.1`, and `http://[::1]` are allowed for a local server. The example uses `http://localhost:8080/api/v1`.

Without the widget tree, `FeedbackKit.configure` builds the same client. It takes `apiKey`, and optional `baseUrl`, `userId`, and `timeout` (milliseconds, default 30000). It does not generate an anonymous id until you call `resolveUserId`.

```dart
final client = FeedbackKit.configure(
  apiKey: 'your-api-key',
  baseUrl: 'https://api.prod.getfeedbackkit.com/api/v1',
  timeout: 10000,
);
```

Reach the provider's client from a descendant:

```dart
final kit = FeedbackKitProvider.of(context);
final items = await kit.client.feedback.list();
```

`of` throws if no provider is above `context`. `maybeOf` returns null. Do not name the local `context`. That shadows `BuildContext` and does not compile.

## User id and anonymous ids

The SDK always has a user id before the list loads or a widget writes.

1. An id passed to `FeedbackKitProvider` or `FeedbackKit.configure` wins, and it is saved.
2. Otherwise the id already in `shared_preferences` is used.
3. Otherwise the SDK creates `local_` plus a UUID and saves that. The same shape is what the Swift SDK uses.

The list waits until that resolution finishes (`FeedbackKitContext.isInitialized`). `hasVoted`, and whether the creator sees their over-limit rows, are decided from `X-User-Id` on the list request. Loading before the id exists would look anonymous.

```dart
const FeedbackKitProvider(
  apiKey: 'your-api-key',
  userId: 'user-123',
  child: MyApp(),
)
```

Or later, once you know who they are. This replaces a `local_` id and persists the new one:

```dart
final kit = FeedbackKitProvider.of(context);
await kit.setUserId('user-123');
```

On a client you built yourself, call `resolveUserId` before the first write. `votes.vote`, `votes.unvote`, and `events.track` throw `ValidationError` when the id is still empty. They do not wait.

```dart
final client = FeedbackKit.configure(apiKey: 'your-api-key');
final userId = await client.resolveUserId();
```

Use a stable id. Regenerating it every launch splits one person's votes across ids. `clearStorage` drops the stored id. The next `resolveUserId` mints a new `local_` id.

Register revenue for that id when you have it. `email` and `name` arguments still compile and are not sent. The body is `user_id` and, when you pass it, `mrr`.

```dart
final user = await kit.client.users.register(
  const RegisterUserRequest(
    userId: 'user-123',
    mrr: 9.99,
  ),
);
```

The widgets never send `mrr`. Only this call does, and only when you pass it.

## Feedback list

`FeedbackList` loads when the user id is ready. The default Showcase style draws Material 3 cards under a search field and a Sort & Filter button. Pass `listStyle: FeedbackListStyle.classic`, on the list or on `FeedbackKitProvider`, to keep the 1.x layout, where each row is a `FeedbackCard` with a status badge, a category badge, and a vote button. The README lists the Showcase options.

```dart
FeedbackList(
  onFeedbackTap: (feedback) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FeedbackDetailPage(feedback: feedback),
      ),
    );
  },
  onVoteChange: (feedback, response) {
    FeedbackKitProvider.of(context).feedbackList.updateFeedback(
          feedback.copyWith(
            voteCount: response.voteCount,
            hasVoted: response.hasVoted,
          ),
        );
  },
)
```

The vote button updates itself immediately, then reconciles with the server. A Showcase card also writes the result into the shared list, and rolls back with a snackbar if the call fails. A classic card does not, so under the classic style write the response back with `updateFeedback`. Skip that and the count reverts when the user leaves and returns. The write-back above is harmless under Showcase.

`emptyBuilder`, `errorBuilder`, `loadingBuilder`, and `autoLoad` (default `true`) replace the built-in states. A custom `emptyBuilder` that ignores errors makes a rejected API key look like an empty board. The error state is separate. `AuthenticationError` is the 401.

The loaded list is a `ListView` only when it has rows. Loading, error, and empty states are not scrollables, so a `RefreshIndicator` wrapped around `FeedbackList` does not fire in those states. Refresh from the notifier:

```dart
await FeedbackKitProvider.of(context).feedbackList.refresh();
```

The Showcase search, sort and filters live on a `FeedbackListController` and run on the device. The notifier filters below are separate: they narrow what is fetched from the server, for both styles.

```dart
final kit = FeedbackKitProvider.of(context);
await kit.feedbackList.setStatusFilter(FeedbackStatus.inProgress);
await kit.feedbackList.setCategoryFilter(FeedbackCategory.bugReport);
await kit.feedbackList.clearFilters();
```

The widget does not page. For a page, call the client. `page` is 1-based.

```dart
final page = await kit.client.feedback.list(
  const ListFeedbackOptions(
    status: FeedbackStatus.approved,
    category: FeedbackCategory.featureRequest,
    page: 1,
    perPage: 20,
  ),
);
```

A row whose `status` or `category` this version does not know is dropped from the list. A malformed row still throws.

`FeedbackItem.userId` and `userEmail` are nullable. `isHiddenOverLimit` is set when the Free cap hid the row. The creator still receives their own hidden rows, because the list request sends their user id.

## Submit

`SubmitFeedbackView` is a form: category, title, description, and an optional email. When the email is non-empty, the form shows a mailing-list opt-in and operational / marketing checkboxes. Those fields are sent. pub.dev 1.0.1 has the email field and does not send it under the key the server reads, and it has no mailing-list controls.

The form has no scaffold of its own. Pop the route yourself.

```dart
Future<void> openSubmitSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: 0.9,
      child: SubmitFeedbackView(
        initialCategory: FeedbackCategory.featureRequest,
        onSubmitted: (feedback) {
          Navigator.of(sheetContext).pop();
          FeedbackKitProvider.of(context).feedbackList.refresh();
        },
        onCancel: () => Navigator.of(sheetContext).pop(),
      ),
    ),
  );
}
```

The same request from the client. There is no `userId` parameter. The configured id is added as `user_id`. `email` is sent as `user_email`.

```dart
final created = await kit.client.feedback.create(
  const CreateFeedbackRequest(
    title: 'Add dark mode',
    description: 'A system-matching dark theme.',
    category: FeedbackCategory.featureRequest,
    email: 'user@example.com',
    subscribeToMailingList: true,
    mailingListEmailTypes: ['operational', 'marketing'],
  ),
);
```

A new item is created with one vote, the creator's, and status `pending`.

## Vote

`VoteButton` toggles a vote with an optimistic count. It does not take an email and it does not opt into status mail. Completed and rejected items disable the button. The server also rejects those votes with 403 (`ForbiddenError`).

To opt into status-change email, call the client. The server stores `notifyStatusChange` only together with an email. The JSON keys are `notify_status_change` and `email`.

```dart
final response = await kit.client.votes.vote(
  feedbackId,
  email: 'user@example.com',
  notifyStatusChange: true,
);
```

`notifyOnStatusChange` still compiles. It is a deprecated alias and it sends `notify_status_change`. On 1.0.1 that argument was the only one, and it sent `notify_on_status_change`, which does not set the flag.

Remove a vote with `unvote`. The user id goes in the JSON body (`user_id`). 1.0.1 put it on the query string, which the route ignores, so removal never landed.

```dart
final removed = await kit.client.votes.unvote(feedbackId);
```

Voting twice for the same user is 409 (`ConflictError`).

`kit.votes` is a `VoteNotifier` with the same `email` and `notifyStatusChange` parameters. It returns null when a vote for that id is already in flight or the call failed. The button uses `toggle` without those parameters.

## Comments

`FeedbackDetailView` loads and posts comments. The field is a text field with its own focus node.

From the client:

```dart
final comments = await kit.client.comments.list(feedbackId);
final comment = await kit.client.comments.create(
  feedbackId,
  const CreateCommentRequest(
    content: 'This would help our team too.',
    userId: 'user-123',
  ),
);
```

`userId` on the request is optional. When you omit it, the configured id is sent. The JSON key is `userId`, not `user_id`. 1.0.1, 1.1.1 and 1.2.0 sent only `content`, and the server requires the id in the body, so create returned 400.

`Comment.feedbackId` is null on a normal list response. The server does not echo it. `isTeamMember` is read from `is_admin`.

## Events

Nothing in the widgets calls `events.track`. A screen does not record `feedback_list`, `feedback_detail`, or `submit_feedback` unless you do.

```dart
await kit.client.events.trackEvent(
  PredefinedEventNames.feedbackList,
  properties: {'filter': 'feature_request'},
);
```

`trackEvent` and `track` return `Future<void>`. There is no `TrackEventRequest` type. Build a `TrackedEvent` if you already have one.

The body is `event_name`, `user_id`, and string `properties`. Numbers and booleans are written as strings. A missing user id, an empty name, or any other property type throws `ValidationError` before the request. 1.0.1 sent `name` and `timestamp` and omitted `user_id`, so the server rejected the payload, and decoding a stored event crashed.

`PredefinedEventNames.all` is `feedback_list`, `feedback_detail`, and `submit_feedback`. The spellings are case-sensitive. `FeedbackList` is a different, custom event.

`events.track` is accepted on every plan, including Free. Custom events are stored immediately. Reading them back is the part that depends on the plan.

## Widgets

| Widget | Role |
| --- | --- |
| `FeedbackList` | Scrollable list. Waits for the user id. Does not page or pull to refresh |
| `FeedbackCard` | One row: badges, title, vote button |
| `FeedbackDetailView` | Detail plus comments |
| `SubmitFeedbackView` | Create form, including mailing-list opt-in when an email is entered |
| `VoteButton` | Optimistic toggle. No email and no `notifyStatusChange` |
| `StatusBadge` | `FeedbackStatus` |
| `CategoryBadge` | `FeedbackCategory` |

`StatusBadge(status: FeedbackStatus.approved)` and `CategoryBadge(category: FeedbackCategory.bugReport)` read colors from the theme.

Catalog locales: `en`, `es`, `fr`, `de`, `ja`, `zh-Hans`, `pt-BR`, `ko`, `it`, `ar`, `ru`. Arabic lays out right to left. Any other tag falls back to English. Override one string with `translations:` on the provider, or call `FeedbackKitLocalizations.setLocale`.

## Errors and plan limits

```dart
try {
  await kit.client.feedback.create(
    const CreateFeedbackRequest(
      title: 'Add dark mode',
      description: 'A system-matching dark theme.',
      category: FeedbackCategory.featureRequest,
    ),
  );
} on AuthenticationError {
  // 401. The API key was rejected.
} on ValidationError {
  // 400. A missing user id on vote or track, or a body the server refused.
} on ForbiddenError {
  // 403. Voting on completed or rejected feedback, or a Bearer-only metric.
} on ConflictError {
  // 409. This user has already voted.
} on NotFoundError {
  // 404.
} on PaymentRequiredError catch (error) {
  // 402. Not the Free feedback cap. See below.
  if (error.code == 'METRICS_CUSTOM_EVENTS_REQUIRE_PRO') {
    // Custom-event reads that have no narrower answer.
  }
} on RateLimitError catch (error) {
  // 429. error.retryAfterSeconds when the server sent Retry-After.
} on NetworkError {
  // Offline, timeout, or a cleartext base URL rejected before the request.
} on FeedbackKitError catch (error) {
  // error.message, error.code, error.field.
}
```

`FeedbackKitError.code` is the server's token when the response used the detailed envelope (`code`, `message`, `field`). The shared middleware envelope carries no code. Then `code` is the class default (`UNAUTHORIZED`, `PAYMENT_REQUIRED`, `FORBIDDEN`, `NOT_FOUND`, `CONFLICT`, `VALIDATION_ERROR`, `RATE_LIMITED`, `NETWORK_ERROR`, `SERVER_ERROR`) and `field` is null.

### Free feedback cap

The Free plan keeps 10 feedback rows visible per project. The create call still returns success. The row is stored with `isHiddenOverLimit: true`. The creator sees it. Everyone else does not. That is not a 402, and catching `PaymentRequiredError` around `feedback.create` will not tell you it happened. Read `isHiddenOverLimit` on the created item.

### Metrics

`kit.client.metrics` has `summary`, `timeseries`, `breakdown`, and `events`. Every plan can call them. A clamped or scoped read is **200**. Do not treat it as an error. The SDK sends these calls to whatever `baseUrl` you configured. On 25 August 2026 testflight and production answered 404 for `/metrics/summary`, while the development API served them. That host check was not repeated for this guide.

- Below Pro, a read counts only `PredefinedEventNames.all`. Your own event names are kept and become readable on upgrade with no re-tracking. `meta.eventScope` is `MetricEventScope.predefinedOnly`.
- A window wider than the plan allows is clamped. `meta.retentionClamped` is true and `meta.retentionWindowDays` is the allowance: Free 30, Pro 90, Team 365. Read that number. Do not hardcode it. Asking again for the already-clamped window returns `retentionClamped: false`.
- Three requests have no narrower answer and return 402 `METRICS_CUSTOM_EVENTS_REQUIRE_PRO`: `dimension: MetricDimension.eventName`, a custom `eventName` filter, and the raw event feed.
- SDK-user and MRR measures (`sdkUserCount`, `mrrSum`, `mrrAverage`, `usersWithMrr`) are not on the API-key surface. The server returns 403 `METRICS_MEASURE_REQUIRES_BEARER`. That is not an upsell to Pro.
- The API-key metrics surface allows 60 requests per 60 seconds. This SDK does not retry, back off, or follow pages. `perPage` is clamped in the client to 1...200. The server rejects an out-of-range value with 400 instead of clamping.
- `MetricSeriesPoint.bucket` is a string in `meta.timezone`. Do not pass it to `DateTime.parse`.
- Empty timeseries buckets are present and zero-valued. `series.isEmpty` does not mean a quiet project.
- `measure` returns `double?`. A breakdown overflow row omits `unique_event_users`.

```dart
final summary = await kit.client.metrics.summary(
  MetricSummaryOptions(
    measures: [MetricMeasure.eventCount],
    days: 365,
  ),
);

if (summary.meta.eventScope == MetricEventScope.predefinedOnly) {
  // Upsell from the 200, not from a caught exception.
}
if (summary.meta.retentionClamped) {
  final days = summary.meta.retentionWindowDays;
  // The response covers `days`, not the 365 you asked for.
}
```

The event feed has two meta objects. `feed.meta` is pagination (`total`, `page`, `perPage`, `totalPages`). `feed.metrics` is the metrics meta.

```dart
DateTime? lastSyncedAt;
final dateTo = DateTime.now().toUtc();
var page = 1;
while (true) {
  final feed = await kit.client.metrics.events(
    MetricEventsOptions(
      dateFrom: lastSyncedAt,
      dateTo: dateTo,
      page: page,
    ),
  );
  if (page >= feed.meta.totalPages) break;
  page++;
}
lastSyncedAt = dateTo;
```

Pin `dateTo` while you page. The SDK does not cancel an older request if you change the window. Drop stale responses yourself.

## Example

```bash
cd example
flutter pub get
flutter run
```

Replace `your-api-key-here` in `example/lib/main.dart`. The file depends on this package with `path: ../`.
