/// @file i_weather_mapper.dart
/// @description Interfaz del mapper de datos meteorológicos. Contrato WeatherModel ↔ WeatherData.
/// @module Weather
/// @layer Data
library;

import '../../domain/entities/weather_data.dart';
import '../models/weather_model.dart';

/// Contrato de conversión entre el modelo de serialización y la entidad de dominio.
///
/// [injectable] registrar en container.dart como singleton.
abstract interface class IWeatherMapper {
  /// Convierte un modelo de serialización a entidad de dominio.
  WeatherData toEntity(WeatherModel model);

  /// Convierte una entidad de dominio a modelo de serialización.
  WeatherModel toModel(WeatherData entity);
}
