/// Thrown when a server-fed enum field carries a token this SDK version does not
/// know — for example a seventh feedback status added to the server after this
/// client shipped.
///
/// This exception is the seam for the tolerant element-drop contract
/// (`AGENTS.md`: a `[Model]` list decode drops only the rows whose failure is an
/// unknown enum value, while a genuinely malformed row — missing required key,
/// type mismatch — still throws). Until 2026-08-15 the enums instead coerced every
/// unknown token to a sentinel case (`FeedbackStatus.pending` /
/// `FeedbackCategory.other`, finding F6): a seventh server status rendered as
/// "Pending", `canVote` returned true for it, and the round trip was lossy.
class UnknownEnumValueException implements Exception {
  /// The enum that could not parse the token, e.g. `'FeedbackStatus'`.
  final String enumName;

  /// The unrecognised wire token.
  final String value;

  const UnknownEnumValueException(this.enumName, this.value);

  @override
  String toString() => "UnknownEnumValueException: unknown $enumName value '$value'";
}
