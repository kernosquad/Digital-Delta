/// Environment configuration for the Digital Delta app.
///
/// This class manages environment-specific settings such as API base URLs,
/// feature flags, and other configurable values.
class EnvironmentConfig {
  EnvironmentConfig._();

  /// The current environment mode.
  static Environment _currentEnvironment = Environment.development;

  /// Get the current environment.
  static Environment get environment => _currentEnvironment;

  /// Set the environment (should be called at app startup).
  static void setEnvironment(Environment env) {
    _currentEnvironment = env;
  }

  /// Get the API base URL for the current environment.
  static String get apiBaseUrl {
    switch (_currentEnvironment) {
      case Environment.development:
        return const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue:
              'https://falsifiable-jerry-nonremuneratively.ngrok-free.dev/api',
        );
      case Environment.staging:
        return const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://staging-api.digitaldelta.com/api',
        );
      case Environment.production:
        return const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://api.digitaldelta.com/api',
        );
    }
  }

  /// Connection timeout in seconds.
  static const int connectionTimeout = 30;

  /// Receive timeout in seconds.
  static const int receiveTimeout = 30;

  /// Whether to enable debug logging.
  static bool get enableDebugLogging =>
      _currentEnvironment != Environment.production;

  /// Whether to enable offline mode by default.
  static const bool enableOfflineMode = true;

  /// Sync retry delay in seconds.
  static const int syncRetryDelaySeconds = 5;

  /// Maximum pending actions to queue.
  static const int maxPendingActions = 100;
}

/// Available environments.
enum Environment { development, staging, production }
