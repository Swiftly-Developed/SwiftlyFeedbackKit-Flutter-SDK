/// The look of [FeedbackList].
///
/// Set it per list with `FeedbackList(listStyle:)`, or for every list under a
/// provider with `FeedbackKitProvider(listStyle:)`. The list's own value wins.
enum FeedbackListStyle {
  /// One Material 3 card per request: a status eyebrow, the full title and
  /// description, the category and comment count, and a vote button. A search
  /// bar and a Sort & Filter sheet sit above the cards. The default since the
  /// FEEDBACK01 release.
  showcase,

  /// The 1.x list, unchanged: bordered cards with badges, a truncated
  /// description, and the small vote button. Choose this to keep the previous
  /// look after upgrading.
  classic,
}
