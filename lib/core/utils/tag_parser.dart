/// Parses #hashtags from transaction notes.
///
/// A tag is any word starting with `#` followed by one or more
/// alphanumeric/underscore characters.  The trailing space requirement
/// from the spec is honoured — the last word in the string also counts
/// as a tag if it starts with `#`.
abstract final class TagParser {
  // Regex: # followed by at least one word-character (letters/digits/underscore)
  static final RegExp _tagRegex = RegExp(r'#(\w+)');

  /// Extracts all tags from [text].  Returns an empty list when no tags exist.
  static List<String> extractTags(String text) {
    final matches = _tagRegex.allMatches(text);
    return matches.map((m) => m.group(1)!.toLowerCase()).toList();
  }

  /// Returns `true` when [text] contains any `#tag`.
  static bool hasTags(String text) => _tagRegex.hasMatch(text);

  /// Returns the display string with all `#tag` tokens removed (trimmed).
  static String stripTags(String text) =>
      text.replaceAll(_tagRegex, '').replaceAll(RegExp(r'\s+'), ' ').trim();
}
