/// How a Showcase card renders its vote count.
///
/// One resolver decides every case, so a test can pin each row of the
/// FEEDBACK01 §6.4 table.
enum VotePresentation {
  /// `showVoteCount` is false: nothing is drawn.
  hidden,

  /// Loading placeholder: a grey capsule, disabled and hidden from
  /// accessibility.
  skeleton,

  /// The request is completed or rejected: the count as plain text, never a
  /// button.
  closed,

  /// Open and not voted: a tonal button that votes.
  votable,

  /// Open and voted, undo allowed: a filled button that removes the vote.
  voted,

  /// Open and voted, undo not allowed: a filled button that does nothing.
  votedLocked;

  /// Resolves the presentation for one card.
  static VotePresentation resolve({
    required bool showVoteCount,
    required bool isSkeleton,
    required bool canVote,
    required bool hasVoted,
    required bool allowUndoVote,
  }) {
    if (!showVoteCount) return VotePresentation.hidden;
    if (isSkeleton) return VotePresentation.skeleton;
    if (!canVote) return VotePresentation.closed;
    if (!hasVoted) return VotePresentation.votable;
    return allowUndoVote ? VotePresentation.voted : VotePresentation.votedLocked;
  }

  /// Whether this renders a button. A closed request never does.
  bool get isButton =>
      this == VotePresentation.votable ||
      this == VotePresentation.voted ||
      this == VotePresentation.votedLocked;

  /// Whether tapping changes the vote.
  bool get isInteractive =>
      this == VotePresentation.votable || this == VotePresentation.voted;

  /// Whether the button is the filled, prominent variant.
  bool get isFilled =>
      this == VotePresentation.voted || this == VotePresentation.votedLocked;

  /// Catalog key for the accessibility value, or null when the count is not
  /// exposed to accessibility.
  String? get semanticsValueKey {
    switch (this) {
      case VotePresentation.hidden:
      case VotePresentation.skeleton:
        return null;
      case VotePresentation.closed:
        return 'accessibility.voting.closed';
      case VotePresentation.votable:
        return 'accessibility.notVoted';
      case VotePresentation.voted:
      case VotePresentation.votedLocked:
        return 'accessibility.voted';
    }
  }

  /// Catalog key for the full spoken hint, as VoiceOver reads it.
  String? get hintKey {
    switch (this) {
      case VotePresentation.votable:
        return 'accessibility.vote.hint';
      case VotePresentation.voted:
        return 'accessibility.unvote.hint';
      case VotePresentation.votedLocked:
        return 'accessibility.voted.locked';
      case VotePresentation.hidden:
      case VotePresentation.skeleton:
      case VotePresentation.closed:
        return null;
    }
  }

  /// Catalog key for TalkBack's tap hint, which TalkBack prefixes with
  /// "Double tap to". Null when the control has no tap action.
  String? get tapHintKey {
    switch (this) {
      case VotePresentation.votable:
        return 'accessibility.vote.tapHint';
      case VotePresentation.voted:
        return 'accessibility.unvote.tapHint';
      case VotePresentation.votedLocked:
      case VotePresentation.hidden:
      case VotePresentation.skeleton:
      case VotePresentation.closed:
        return null;
    }
  }
}
