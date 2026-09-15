/// Stub for non-web platforms.
/// This file is never used on web (web_utils_web.dart is used instead).
String getCurrentUrl() {
  throw UnsupportedError('getCurrentUrl is only supported on web');
}
