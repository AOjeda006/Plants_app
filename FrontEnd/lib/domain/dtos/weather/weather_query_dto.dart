/// @file weather_query_dto.dart
/// @description DTO de consulta de clima. Se completará en Fase 2.
/// @module Weather
/// @layer Domain
library;
class WeatherQueryDto {
  const WeatherQueryDto({required this.location, this.days = 7});
  final String location;
  final int    days;
}
