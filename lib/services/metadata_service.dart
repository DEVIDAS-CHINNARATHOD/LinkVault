// lib/services/metadata_service.dart
import 'dart:async';
import 'package:http/http.dart' as http;

class PageMetadata {
  final String? title;
  final String? description;
  final String? favicon;
  const PageMetadata({this.title, this.description, this.favicon});
}

/// Fetches Open Graph / meta tags from a URL to auto-fill link details.
class MetadataService {
  static Future<PageMetadata> fetch(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await http
          .get(uri, headers: {'User-Agent': 'LinkVault/1.0'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return const PageMetadata();

      final body = response.body;
      final title = _extractMeta(body, ['og:title', 'twitter:title']) ??
          _extractTitle(body);
      final description =
          _extractMeta(body, ['og:description', 'twitter:description', 'description']);
      final favicon = 'https://www.google.com/s2/favicons?domain=${uri.host}&sz=64';

      return PageMetadata(title: title, description: description, favicon: favicon);
    } catch (_) {
      return const PageMetadata();
    }
  }

  static String? _extractMeta(String html, List<String> names) {
    for (final name in names) {
      // property="og:title" content="..."
      final propertyReg = RegExp(
          r'<meta[^>]*property=["\']' + RegExp.escape(name) + r'["\'][^>]*content=["\']([^"\']+)["\']',
          caseSensitive: false);
      var match = propertyReg.firstMatch(html);
      if (match != null) return _decodeHtml(match.group(1)!);

      // name="description" content="..."
      final nameReg = RegExp(
          r'<meta[^>]*name=["\']' + RegExp.escape(name) + r'["\'][^>]*content=["\']([^"\']+)["\']',
          caseSensitive: false);
      match = nameReg.firstMatch(html);
      if (match != null) return _decodeHtml(match.group(1)!);
    }
    return null;
  }

  static String? _extractTitle(String html) {
    final reg = RegExp(r'<title[^>]*>([^<]+)</title>', caseSensitive: false);
    final match = reg.firstMatch(html);
    return match != null ? _decodeHtml(match.group(1)!) : null;
  }

  static String _decodeHtml(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .trim();
  }
}
