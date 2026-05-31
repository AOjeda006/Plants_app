/// @file i_weather_repository.dart
/// @description Interfaz del repositorio de clima. Define el contrato para
/// obtener datos meteorológicos actuales y previsiones.
/// @module Weather
/// @layer Domain
library;

import '../entities/weather_data.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// I WEATHER REPOSITORY
// ═══════════════════════════════════════════════════════════════════════════════

/// Contrato de acceso a datos meteorológicos.
///
/// Las implementaciones deben gestionar caché con TTL y fallback a datos mock
/// cuando el backend no es alcanzable (útil en demos del TFG).
abstract interface class IWeatherRepository {
  /// Obtiene el clima actual para [location].
  ///
  /// [location] — nombre de ciudad o coordenadas ("Madrid", "40.4168,-3.7038").
  /// [returns]  — [WeatherData] con temperatura, condición, humedad, etc.
  /// [throws]   AppError.network si no hay conexión y no hay caché válido.
  Future<WeatherData> getCurrentWeather(String location);

  /// Obtiene la previsión meteorológica de [days] días para [location].
  ///
  /// [location] — misma semántica que [getCurrentWeather].
  /// [days]     — número de días (1–14, por defecto 7).
  /// [returns]  — [WeatherData] con datos actuales + [WeatherData.forecast] poblado.
  /// [throws]   AppError.network si no hay conexión y no hay caché válido.
  Future<WeatherData> getForecast(String location, {int days = 7});
}
