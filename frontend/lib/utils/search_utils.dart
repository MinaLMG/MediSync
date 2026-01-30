import 'package:flutter/foundation.dart';

class SearchUtils {
  /// Matches a string against a search query using Regex.
  /// '*' is treated as a wildcard (any number of characters).
  static bool matches(String? target, String query) {
    if (target == null) return false;
    if (query.isEmpty) return true;

    try {
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

      // Replace '*' with '.*' for wildcard behavior
      String regexPattern = escapedQuery.replaceAll('*', '.*');

      // Create RegExp with case-insensitive flag
      final regExp = RegExp(regexPattern, caseSensitive: false);

      return regExp.hasMatch(target);
    } catch (e) {
      // Fallback to simple case-insensitive contains if regex fails
      if (kDebugMode) {}
      return target.toLowerCase().contains(query.toLowerCase());
    }
  }
}
