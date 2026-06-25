enum UrlValidationError {
  empty,
  invalidFormat,
  httpsOnly,
  userInfoNotAllowed,
  missingHost,
}

class ProviderUrlPolicy {
  static bool isHttps(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return false;
    return uri.scheme == 'https';
  }

  static UrlValidationError? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return UrlValidationError.empty;
    }
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme) {
      return UrlValidationError.invalidFormat;
    }
    // Only allow HTTPS
    if (uri.scheme != 'https') {
      return UrlValidationError.httpsOnly;
    }
    // Check for user info (username:password in URL)
    if (uri.userInfo.isNotEmpty) {
      return UrlValidationError.userInfoNotAllowed;
    }
    // Check for missing host
    if (uri.host.isEmpty) {
      return UrlValidationError.missingHost;
    }
    return null;
  }

  static bool isAllowedForRequest(String url) {
    return isHttps(url);
  }
}
