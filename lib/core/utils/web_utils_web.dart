import 'dart:html' as html;

/// Gets the current browser URL on web platforms.
/// This is a web-only function, so it's kept in a separate file
/// to avoid compilation errors on mobile platforms.
String getCurrentUrl() {
  return html.window.location.href;
}
