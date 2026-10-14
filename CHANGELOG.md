# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[1.2.0]: https://github.com/Swiftly-Developed/SwiftlyFeedbackKit-Flutter-SDK/releases/tag/1.2.0
[1.1.1]: https://github.com/Swiftly-Developed/SwiftlyFeedbackKit-Flutter-SDK/releases/tag/1.1.1
[1.1.0]: https://github.com/Swiftly-Developed/SwiftlyFeedbackKit-Flutter-SDK/releases/tag/1.1.0
[1.0.1]: https://github.com/Swiftly-Developed/SwiftlyFeedbackKit-Flutter-SDK/releases/tag/1.0.1
[1.0.0]: https://github.com/Swiftly-Developed/SwiftlyFeedbackKit-Flutter-SDK/releases/tag/1.0.0
