/// Runtime configuration — API endpoint + dev auth token.
///
/// Both values are injected at build time via `--dart-define` so no
/// environment-specific value is hardcoded in a release build:
///
///   flutter run \
///     --dart-define=INDIA_API_BASE_URL=http://95.111.241.97 \
///     --dart-define=INDIA_API_TOKEN=<owner token>
///
/// The static Bearer token is the Phase-1 owner-testing auth. Firebase
/// Phone Auth replaces it for subscribers once the Firebase project
/// exists — at that point the token define is dropped entirely.
library;

class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'INDIA_API_BASE_URL',
    defaultValue: 'http://95.111.241.97',
  );

  static const String apiToken = String.fromEnvironment('INDIA_API_TOKEN');

  /// Feed auto-refresh cadence while the app is open. Matches the
  /// engine's 30s scan interval — polling faster cannot surface new
  /// signals any sooner.
  static const Duration feedRefreshInterval = Duration(seconds: 30);
}
