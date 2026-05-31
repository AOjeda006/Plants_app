/// @file get_current_weather_use_case.dart
/// @description Caso de uso para obtener el clima actual de una ubicación.
/// Delega en IWeatherRepository — sin lógica de negocio adicional más allá
/// de delegar la orquestación de caché y red al repositorio.
/// @module Weather
/// @layer Domain
library;

import '../../entities/weather_data.dart';
import '../../interfaces/usecases/weather/i_get_current_weather_use_case.dart';
import '../../repositories/i_weather_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// GET CURRENT WEATHER USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Caso de uso que obtiene el clima actual para una ubicación dada.
///
/// Devuelve [WeatherData] con temperatura, condición, humedad y viento.
/// El caché y el modo mock son responsabilidad del repositorio.
///
/// [implements] IGetCurrentWeatherUseCase
/// [injectable] registrar en container.dart como lazySingleton.
/// [dependencies] IWeatherRepository.
class GetCurrentWeatherUseCase implements IGetCurrentWeatherUseCase {
  final IWeatherRepository _repository;

  const GetCurrentWeatherUseCase({required IWeatherRepository repository})
      : _repository = repository;

  /// Obtiene el clima actual para [location].
  ///
  /// [location] — nombre de ciudad o coordenadas aceptadas por WeatherAPI.com.
  /// [returns]  — [WeatherData] con los datos meteorológicos actuales.
  /// [throws]   AppError.network si no hay conexión y no hay caché válido.
  @override
  Future<WeatherData> execute(String location) {
    return _repository.getCurrentWeather(location);
  }
}
