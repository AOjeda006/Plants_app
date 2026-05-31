/// @file weather_mapper.dart
/// @description Implementación del mapper de datos meteorológicos.
/// Convierte WeatherModel (serialización) ↔ WeatherData (entidad de dominio).
/// @module Weather
/// @layer Data
library;

import '../../domain/entities/weather_data.dart';
import '../i_mappers/i_weather_mapper.dart';
import '../models/weather_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// WEATHER MAPPER
// ═══════════════════════════════════════════════════════════════════════════════

/// Implementación concreta de [IWeatherMapper].
///
/// Convierte entre el modelo de serialización [WeatherModel] y la entidad de
/// dominio [WeatherData], incluyendo la lista de previsión [ForecastDay].
///
/// [implements] IWeatherMapper
/// [injectable] registrar en container.dart como singleton.
class WeatherMapper implements IWeatherMapper {
  const WeatherMapper();

  // ─── Model → Entity ───────────────────────────────────────────────────────────

  @override
  WeatherData toEntity(WeatherModel model) {
    return WeatherData(
      locationName:  model.locationName,
      region:        model.region,
      country:       model.country,
      tempC:         model.tempC,
      tempF:         model.tempF,
      feelsLikeC:    model.feelsLikeC,
      feelsLikeF:    model.feelsLikeF,
      conditionText: model.conditionText,
      conditionIcon: model.conditionIcon,
      humidity:      model.humidity,
      windKph:       model.windKph,
      windMph:       model.windMph,
      uv:            model.uv,
      isDay:         model.isDay,
      fetchedAt:     DateTime.parse(model.fetchedAt).toUtc(),
      forecast:      model.forecast.map(_forecastDayToEntity).toList(),
    );
  }

  // ─── Entity → Model ───────────────────────────────────────────────────────────

  @override
  WeatherModel toModel(WeatherData entity) {
    return WeatherModel(
      locationName:  entity.locationName,
      region:        entity.region,
      country:       entity.country,
      tempC:         entity.tempC,
      tempF:         entity.tempF,
      feelsLikeC:    entity.feelsLikeC,
      feelsLikeF:    entity.feelsLikeF,
      conditionText: entity.conditionText,
      conditionIcon: entity.conditionIcon,
      humidity:      entity.humidity,
      windKph:       entity.windKph,
      windMph:       entity.windMph,
      uv:            entity.uv,
      isDay:         entity.isDay,
      fetchedAt:     entity.fetchedAt.toUtc().toIso8601String(),
      forecast:      entity.forecast.map(_forecastDayToModel).toList(),
    );
  }

  // ─── Privados ─────────────────────────────────────────────────────────────────

  ForecastDay _forecastDayToEntity(ForecastDayModel model) => ForecastDay(
    // Normalizar a medianoche UTC para facilitar comparaciones de fecha.
    date:          DateTime.utc(
      int.parse(model.date.substring(0, 4)),
      int.parse(model.date.substring(5, 7)),
      int.parse(model.date.substring(8, 10)),
    ),
    maxTempC:      model.maxTempC,
    minTempC:      model.minTempC,
    maxTempF:      model.maxTempF,
    minTempF:      model.minTempF,
    conditionText: model.conditionText,
    chanceOfRain:  model.chanceOfRain,
  );

  ForecastDayModel _forecastDayToModel(ForecastDay entity) => ForecastDayModel(
    date:          entity.date.toIso8601String().substring(0, 10),
    maxTempC:      entity.maxTempC,
    minTempC:      entity.minTempC,
    maxTempF:      entity.maxTempF,
    minTempF:      entity.minTempF,
    conditionText: entity.conditionText,
    chanceOfRain:  entity.chanceOfRain,
  );
}
