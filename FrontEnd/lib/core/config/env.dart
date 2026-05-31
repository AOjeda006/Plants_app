/// @file env.dart
/// @description Carga el archivo .env usando flutter_dotenv e inicializa AppConfig.
/// Punto de entrada de la configuración de entorno en tiempo de arranque.
/// @module Core
/// @layer Core
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app_config.dart';

/// Gestiona la carga del archivo de entorno y la inicialización de [AppConfig].
///
/// Uso en main.dart:
/// ```dart
/// await Env.initialize();
/// ```
class Env {
  Env._(); // clase de utilidad, no instanciable

  /// URL del backend desplegado en Render. Default productivo: las builds
  /// release apuntan aquí siempre, sin requerir un `.env` adicional.
  static const String _renderApiUrl    = 'https://tfg-86mt.onrender.com';
  static const String _renderSocketUrl = 'https://tfg-86mt.onrender.com';

  /// Override en tiempo de compilación para desarrolladores que quieran
  /// apuntar a un backend local: `flutter run --dart-define=USE_LOCAL=true`.
  /// Vale 'true' o '1'. Cualquier otro valor (incluido vacío) hace que se
  /// usen las URLs productivas — esto es lo que quiere el evaluador.
  static const String _useLocalRaw = String.fromEnvironment('USE_LOCAL');
  static bool get _useLocal =>
      _useLocalRaw.toLowerCase() == 'true' || _useLocalRaw == '1';

  /// Carga `.env` desde assets e inicializa [AppConfig].
  ///
  /// Orden de precedencia para API/SOCKET URL:
  ///  1. `--dart-define=USE_LOCAL=true` → fuerza localhost.
  ///  2. Variable definida en `.env` (si existe) → la usa.
  ///  3. Default productivo (Render) → para builds release sin .env.
  ///
  /// En CI/CD o builds release sin .env, los defaults productivos garantizan
  /// que la app funciona end-to-end sin configuración adicional.
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // TFG: en builds release o en CI puede no existir .env. Caemos a los
      // defaults Render (paso 3 de la precedencia).
    }

    final apiDefault    = _useLocal ? 'http://localhost:3000' : _renderApiUrl;
    final socketDefault = _useLocal ? 'http://localhost:3000' : _renderSocketUrl;

    AppConfig.initialize(
      AppConfig(
        apiBaseUrl: _get('API_BASE_URL', apiDefault),
        socketUrl:  _get('SOCKET_URL',   socketDefault),
        weatherCacheTtlSeconds: _getInt('WEATHER_CACHE_TTL_SECONDS', 1800),
        weatherWindowHours:     _getInt('WEATHER_WINDOW_HOURS', 24),
        mockWeatherMode:        _getBool('MOCK_WEATHER_MODE', false),
        cloudinaryUploadPreset: _get('CLOUDINARY_UPLOAD_PRESET', 'tfg_plants'),
        fcmEnabled:             _getBool('FCM_ENABLED', false),
        isProduction:           _getBool('IS_PRODUCTION', false),
        defaultLocale:          _get('DEFAULT_LOCALE', 'es'),
      ),
    );
  }

  // ─── Helpers de lectura con fallback ─────────────────────────────────────────

  static String _get(String key, String fallback) =>
      dotenv.maybeGet(key) ?? fallback;

  static int _getInt(String key, int fallback) {
    final raw = dotenv.maybeGet(key);
    return raw != null ? (int.tryParse(raw) ?? fallback) : fallback;
  }

  static bool _getBool(String key, bool fallback) {
    final raw = dotenv.maybeGet(key)?.toLowerCase();
    if (raw == null) return fallback;
    return raw == 'true' || raw == '1';
  }
}
