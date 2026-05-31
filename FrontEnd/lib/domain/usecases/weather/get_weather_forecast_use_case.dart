/// @file get_weather_forecast_use_case.dart
/// @description Caso de uso para obtener la previsión meteorológica de N días.
/// Delega en IWeatherRepository la orquestación de caché y llamada al proxy.
/// @module Weather
/// @layer Domain
library;

import '../../entities/weather_data.dart';
import '../../interfaces/usecases/weather/i_get_weather_forecast_use_case.dart';
import '../../repositories/i_weather_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// GET WEATHER FORECAST USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Caso de uso que obtiene la previsión meteorológica para una ubicación.
///
/// Devuelve [WeatherData] con el campo [WeatherData.forecast] poblado.
/// La granularidad de la previsión (días) se controla con el parámetro [days].
///
/// [implements] IGetWeatherForecastUseCase
/// [injectable] registrar en container.dart como lazySingleton.
/// [dependencies] IWeatherRepository.
class GetWeatherForecastUseCase implements IGetWeatherForecastUseCase {
  final IWeatherRepository _repository;

  const GetWeatherForecastUseCase({required IWeatherRepository repository})
      : _repository = repository;

  /// Obtiene la previsión de [days] días para [location].
  ///
  /// [location] — nombre de ciudad o coordenadas aceptadas por WeatherAPI.com.
  /// [days]     — número de días de previsión (1–14, por defecto 7).
  /// [returns]  — [WeatherData] con datos actuales + lista de previsión.
  /// [throws]   AppError.network si no hay conexión y no hay caché válido.
  @override
  Future<WeatherData> execute(String location, {int days = 7}) {
    return _repository.getForecast(location, days: days);
  }
}
