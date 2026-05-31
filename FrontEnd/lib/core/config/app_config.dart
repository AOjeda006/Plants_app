/// @file app_config.dart
/// @description Configuración central de la aplicación.
/// Singleton inicializado al arranque desde env.dart.
/// Centraliza todas las URLs, flags y parámetros de operación.
/// @module Core
/// @layer Core
library;

/// Configuración global de la aplicación.
///
/// Patrón singleton: se inicializa una sola vez en el arranque (desde env.dart)
/// y se accede mediante [AppConfig.instance] en cualquier punto de la app.
class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.socketUrl,
    required this.weatherCacheTtlSeconds,
    required this.weatherWindowHours,
    required this.mockWeatherMode,
    required this.cloudinaryUploadPreset,
    required this.fcmEnabled,
    required this.isProduction,
    required this.defaultLocale,
  });

  /// URL base de la API REST del backend (sin slash final).
  /// Ejemplo: http://localhost:3000
  final String apiBaseUrl;

  /// URL del servidor Socket.IO.
  /// Ejemplo: http://localhost:3000
  final String socketUrl;

  /// Tiempo de vida del caché meteorológico en segundos.
  final int weatherCacheTtlSeconds;

  /// Ventana temporal de previsión meteorológica en horas.
  final int weatherWindowHours;

  /// Si true, el módulo de weather usa datos simulados en lugar de la API real.
  /// Útil en entornos sin conexión o para demos del TFG.
  final bool mockWeatherMode;

  /// Preset de Cloudinary para subida directa de imágenes desde el frontend.
  final String cloudinaryUploadPreset;

  /// Si true, Firebase Cloud Messaging está habilitado para push notifications.
  /// En entornos sin google-services.json se debe poner a false.
  final bool fcmEnabled;

  /// true en producción, false en desarrollo/test.
  final bool isProduction;

  /// Locale por defecto de la aplicación (ej. 'es', 'en').
  final String defaultLocale;

  // ─── Singleton ───────────────────────────────────────────────────────────────

  static AppConfig? _instance;

  /// Instancia activa de la configuración.
  ///
  /// [throws] StateError si se accede antes de llamar a [initialize].
  static AppConfig get instance {
    if (_instance == null) {
      throw StateError(
        'AppConfig not initialized. Call AppConfig.initialize() before use.',
      );
    }
    return _instance!;
  }

  /// Inicializa el singleton con la configuración proporcionada.
  ///
  /// Debe llamarse una única vez durante el arranque de la app, antes
  /// de cualquier acceso a [AppConfig.instance].
  static void initialize(AppConfig config) {
    _instance = config;
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// Devuelve true si el modo de desarrollo está activo (no producción).
  bool get isDevelopment => !isProduction;

  @override
  String toString() =>
      'AppConfig(apiBaseUrl: $apiBaseUrl, socketUrl: $socketUrl, '
      'mockWeather: $mockWeatherMode, fcm: $fcmEnabled, prod: $isProduction)';
}
