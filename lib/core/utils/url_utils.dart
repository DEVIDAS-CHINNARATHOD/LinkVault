// lib/core/utils/url_utils.dart

class UrlUtils {
  /// Validates and normalizes a URL string
  static String? normalize(String url) {
    String cleaned = url.trim();
    if (cleaned.isEmpty) return null;
    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      cleaned = 'https://$cleaned';
    }
    try {
      final uri = Uri.parse(cleaned);
      if (!uri.hasScheme || uri.host.isEmpty) return null;
      return cleaned;
    } catch (_) {
      return null;
    }
  }

  /// Extracts the domain from a URL for display
  static String extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      String host = uri.host;
      if (host.startsWith('www.')) host = host.substring(4);
      return host;
    } catch (_) {
      return url;
    }
  }

  /// Returns favicon URL for a given domain
  static String getFaviconUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return 'https://www.google.com/s2/favicons?domain=${uri.host}&sz=64';
    } catch (_) {
      return '';
    }
  }

  /// Suggests a group name based on URL keywords
  static String? suggestGroup(String url, Map<String, String> keywordMap) {
    final lowerUrl = url.toLowerCase();
    for (final entry in keywordMap.entries) {
      if (lowerUrl.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }
}

// lib/core/utils/date_utils.dart
extension AppDateUtils on DateTime {
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(this);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }
}
