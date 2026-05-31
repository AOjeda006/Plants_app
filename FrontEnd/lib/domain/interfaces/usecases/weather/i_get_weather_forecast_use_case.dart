/// @file i_get_weather_forecast_use_case.dart
/// @description Interfaz del caso de uso para obtener la previsión meteorológica.
/// @module Weather
/// @layer Domain
library;

import '../../../../domain/entities/weather_data.dart';

abstract interface class IGetWeatherForecastUseCase {
  /// Devuelve la previsión de [days] días para [location].
  ///
  /// [returns] [WeatherData] con el campo forecast poblado.
  /// [throws]  AppError.network si no hay conexión y no hay caché válido.
  Future<WeatherData> execute(String location, {int days = 7});
}
