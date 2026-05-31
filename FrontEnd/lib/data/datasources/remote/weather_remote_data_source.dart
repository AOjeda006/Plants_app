/// @file weather_remote_data_source.dart
/// @description Fuente de datos remota para el módulo de clima.
/// Encapsula las llamadas HTTP al proxy meteorológico del backend (/weather).
/// El backend actúa como intermediario con WeatherAPI.com y gestiona el caché
/// y el modo mock server-side (MOCK_WEATHER_MODE).
/// Devuelve Maps crudos — el repositorio delega en WeatherMapper para las entidades.
/// @module Weather
/// @layer Data
library;

import '../../../core/network/api_client.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// WEATHER REMOTE DATA SOURCE
// ═══════════════════════════════════════════════════════════════════════════════

/// Datasource remoto para las consultas meteorológicas.
///
/// Endpoints cubiertos:
///  - GET /weather?location=...          → getCurrentWeather
///  - GET /weather/forecast?location=...&days=... → getForecast
///
/// El backend proxea WeatherAPI.com y puede responder con datos cacheados
/// o datos mock si MOCK_WEATHER_MODE está activo en el servidor.
///
/// [injectable] registrar en container.dart como singleton.
/// [dependencies] ApiClient.
class WeatherRemoteDataSource {
  final ApiClient _apiClient;

  const WeatherRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  // ─── Get current weather ──────────────────────────────────────────────────────

  /// Obtiene el clima actual para [location] (nombre de ciudad o coordenadas).
  ///
  /// [location] — cadena libre aceptada por WeatherAPI.com (p.ej. "Madrid",
  ///              "40.4168,-3.7038", "Balcón norte, Madrid").
  /// [returns]  — Map con la respuesta RAW del proxy (formato WeatherAPI.com).
  /// [throws]   AppError.network si no hay conexión con el backend.
  /// [throws]   AppError.server si el proxy falla con error 5xx.
  Future<Map<String, dynamic>> getCurrentWeather(String location) async {
    return _apiClient.get<Map<String, dynamic>>(
      '/weather',
      queryParameters: {'location': location},
    );
  }

  // ─── Get forecast ─────────────────────────────────────────────────────────────

  /// Obtiene la previsión meteorológica de [days] días para [location].
  ///
  /// [location] — misma semántica que en [getCurrentWeather].
  /// [days]     — número de días de previsión (1–14, por defecto 7).
  /// [returns]  — Map con la respuesta RAW del proxy (incluye current + forecast).
  /// [throws]   AppError.network si no hay conexión con el backend.
  Future<Map<String, dynamic>> getForecast(
    String location, {
    int days = 7,
  }) async {
    return _apiClient.get<Map<String, dynamic>>(
      '/weather/forecast',
      queryParameters: {'location': location, 'days': days},
    );
  }
}
