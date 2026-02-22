import 'package:flutter/foundation.dart';

class SearchUtils {
  /// Matches a string against a search query using Regex.
  /// '*' is treated as a wildcard (any number of characters).
  static bool matches(String? target, String query) {
    if (target == null) return false;
    if (query.isEmpty) return true;

    try {
      if (!query.contains('*')) {
        return target.toLowerCase().contains(query.toLowerCase());
      }

      // Escape special regex characters except '*'
      String escapedQuery = query
          .replaceAll(r'\', r'\\')
          .replaceAll(r'.', r'\.')
          .replaceAll(r'+', r'\+')
          .replaceAll(r'?', r'\?')
          .replaceAll(r'^', r'\^')
          .replaceAll(r'$', r'\$')
          .replaceAll(r'(', r'\(')
          .replaceAll(r')', r'\)')
          .replaceAll(r'[', r'\[')
          .replaceAll(r']', r'\]')
          .replaceAll(r'{', r'\{')
          .replaceAll(r'}', r'\}')
          .replaceAll(r'|', r'\|');

      // Replace '*' with '.*' and add .* at start and end for partial matching
      String regexPattern = '.*${escapedQuery.replaceAll('*', '.*')}.*';

      final regExp = RegExp(regexPattern, caseSensitive: false);
      return regExp.hasMatch(target);
    } catch (e) {
      if (kDebugMode) print('Search error: $e');
      return target.toLowerCase().contains(query.toLowerCase());
    }
  }
}
