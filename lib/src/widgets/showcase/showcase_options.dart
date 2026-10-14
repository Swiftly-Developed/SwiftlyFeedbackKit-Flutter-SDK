/// The configuration flags a Showcase list honours, gathered from
/// `FeedbackList` so each widget reads one value.
class ShowcaseOptions {
  /// Show the search bar and the Sort & Filter button above the cards.
  final bool showToolbar;

  /// Show the status eyebrow on each card.
  final bool showStatusBadge;

  /// Show the category fact in each card's footer.
  final bool showCategoryBadge;

  /// Show the comment count in each card's footer when it is above zero.
  final bool showCommentCount;

  /// Show the vote control, or the plain count on a closed request.
  final bool showVoteCount;

  /// Let a reader remove a vote they gave.
  final bool allowUndoVote;

  /// Offer the Status filter in the Sort & Filter sheet.
  final bool showStatusFilter;

  /// Offer the Category filter in the Sort & Filter sheet.
  final bool showCategoryFilter;

  const ShowcaseOptions({
    this.showToolbar = true,
    this.showStatusBadge = true,
    this.showCategoryBadge = true,
    this.showCommentCount = true,
    this.showVoteCount = true,
    this.allowUndoVote = true,
    this.showStatusFilter = true,
    this.showCategoryFilter = true,
  });
}
