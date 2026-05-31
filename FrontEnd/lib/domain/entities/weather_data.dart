/// @file weather_data.dart
/// @description Entidad de dominio WeatherData. Encapsula los datos meteorológicos
/// actuales y la previsión para una ubicación dada.
/// Objeto puro de Dart, sin dependencias de Flutter ni paquetes externos.
/// Los mappers convierten WeatherModel ↔ WeatherData.
/// @module Weather
/// @layer Domain
library;

// ═══════════════════════════════════════════════════════════════════════════════
// WEATHER DATA ENTITY
// ═══════════════════════════════════════════════════════════════════════════════

/// Entidad de dominio que representa los datos meteorológicos actuales
/// y la previsión de días futuros para una ubicación concreta.
///
/// Todos los campos son inmutables (final).
/// [fetchedAt] se usa para determinar si los datos están obsoletos con [isExpired].
class WeatherData {
  const WeatherData({
    required this.locationName,
    required this.region,
    required this.country,
    required this.tempC,
    required this.feelsLikeC,
    required this.conditionText,
    required this.conditionIcon,
    required this.humidity,
    required this.windKph,
    required this.uv,
    required this.isDay,
    required this.fetchedAt,
    this.tempF      = 0.0,
    this.feelsLikeF = 0.0,
    this.windMph    = 0.0,
    this.forecast = const [],
  });

  /// Nombre de la ciudad o localidad (p.ej. "Madrid").
  final String locationName;

  /// Región o comunidad autónoma (p.ej. "Community of Madrid").
  final String region;

  /// País (p.ej. "Spain").
  final String country;

  /// Temperatura actual en grados Celsius.
  final double tempC;

  /// Temperatura actual en grados Fahrenheit.
  final double tempF;

  /// Sensación térmica en grados Celsius.
  final double feelsLikeC;

  /// Sensación térmica en grados Fahrenheit.
  final double feelsLikeF;

  /// Descripción textual de la condición (p.ej. "Sunny", "Partly cloudy").
  final String conditionText;

  /// URL del icono de la condición meteorológica (WeatherAPI.com CDN).
  final String conditionIcon;

  /// Humedad relativa en porcentaje (0–100).
  final int humidity;

  /// Velocidad del viento en km/h.
  final double windKph;

  /// Velocidad del viento en mph.
  final double windMph;

  /// Índice UV (0 = mínimo).
  final double uv;

  /// true si es de día en la ubicación consultada.
  final bool isDay;

  /// Momento en que se obtuvieron estos datos (UTC).
  /// Usado por [isExpired] para invalidar el caché de entidad.
  final DateTime fetchedAt;

  /// Previsión meteorológica por días (lista vacía si solo se pidió el actual).
  final List<ForecastDay> forecast;

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// Devuelve true si los datos han superado el [ttl] desde su obtención.
  ///
  /// [ttl] por defecto es 1 hora, coherente con [AppConfig.weatherCacheTtlSeconds].
  bool isExpired({Duration ttl = const Duration(hours: 1)}) =>
      DateTime.now().isAfter(fetchedAt.add(ttl));

  @override
  String toString() =>
      'WeatherData(location: $locationName, temp: ${tempC.toStringAsFixed(1)}°C, '
      'condition: $conditionText)';
}

// ═══════════════════════════════════════════════════════════════════════════════
// FORECAST DAY
// ═══════════════════════════════════════════════════════════════════════════════

/// Previsión meteorológica para un día concreto.
class ForecastDay {
  const ForecastDay({
    required this.date,
    required this.maxTempC,
    required this.minTempC,
    required this.conditionText,
    required this.chanceOfRain,
    this.maxTempF = 0.0,
    this.minTempF = 0.0,
  });

  /// Fecha del día de previsión (hora normalizada a medianoche UTC).
  final DateTime date;

  /// Temperatura máxima del día en °C.
  final double maxTempC;

  /// Temperatura mínima del día en °C.
  final double minTempC;

  /// Temperatura máxima del día en °F.
  final double maxTempF;

  /// Temperatura mínima del día en °F.
  final double minTempF;

  /// Descripción textual de la condición dominante del día.
  final String conditionText;

  /// Probabilidad de precipitación en porcentaje (0–100).
  final int chanceOfRain;

  @override
  String toString() =>
      'ForecastDay(${date.toIso8601String().substring(0, 10)}, '
      'max: ${maxTempC.toStringAsFixed(1)}°C, rain: $chanceOfRain%)';
}
