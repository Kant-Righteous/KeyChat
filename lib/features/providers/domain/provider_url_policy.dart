class ProviderUrlPolicy {
  static bool isHttps(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return false;
    return uri.scheme == 'https';
  }

  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Base URL is required';
    }
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme) {
      return 'Enter a valid URL';
    }
    // Only allow HTTPS
    if (uri.scheme != 'https') {
      return 'Only HTTPS URLs are supported to protect your API key and messages';
    }
    // Check for user info (username:password in URL)
    if (uri.userInfo.isNotEmpty) {
      return 'URL must not contain username or password';
    }
    // Check for missing host
    if (uri.host.isEmpty) {
      return 'URL must have a valid host';
    }
    return null;
  }

  static bool isAllowedForRequest(String url) {
    return isHttps(url);
  }
}
