/// @file i_get_current_weather_use_case.dart
/// @description Interfaz del caso de uso para obtener el clima actual.
/// @module Weather
/// @layer Domain
library;

import '../../../../domain/entities/weather_data.dart';

abstract interface class IGetCurrentWeatherUseCase {
  /// Devuelve el clima actual para [location] (ciudad o coordenadas).
  ///
  /// [throws] AppError.network si no hay conexión y no hay caché válido.
  Future<WeatherData> execute(String location);
}
