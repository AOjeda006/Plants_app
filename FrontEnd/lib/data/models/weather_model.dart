/// @file weather_model.dart
/// @description Modelo de serialización de datos meteorológicos para la capa de datos.
/// Parsea dos formatos JSON:
///   1) Respuesta RAW del proxy backend (/weather) en formato WeatherAPI.com.
///   2) Formato plano cacheado (clave 'locationName' presente) generado por toJson().
/// SIN lógica de negocio. La conversión WeatherModel ↔ WeatherData la realiza WeatherMapper.
/// @module Weather
/// @layer Data
library;

// ═══════════════════════════════════════════════════════════════════════════════
// WEATHER MODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// Modelo de serialización de los datos meteorológicos. Refleja la estructura
/// que devuelve el proxy /weather del backend (compatible con WeatherAPI.com).
///
/// Regla estricta: NO contiene lógica de negocio, validaciones ni referencias
/// a entidades de dominio. Solo fromJson y toJson.
class WeatherModel {
  const WeatherModel({
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

  final String   locationName;
  final String   region;
  final String   country;
  final double   tempC;
  final double   tempF;
  final double   feelsLikeC;
  final double   feelsLikeF;
  final String   conditionText;
  final String   conditionIcon;
  final int      humidity;
  final double   windKph;
  final double   windMph;
  final double   uv;
  final bool     isDay;
  /// ISO 8601 timestamp del momento en que se obtuvieron los datos.
  final String   fetchedAt;
  final List<ForecastDayModel> forecast;

  // ─── Deserialización ─────────────────────────────────────────────────────────

  /// Construye el modelo desde JSON.
  ///
  /// Soporta dos formatos:
  ///   - **Formato RAW** de WeatherAPI.com (con claves anidadas `location`, `current`).
  ///   - **Formato plano cacheado** (con clave `locationName`) generado por [toJson].
  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    // Detectar formato por la presencia de claves específicas de cada origen.
    if (json.containsKey('locationName')) {
      // Formato plano cacheado (generado por toJson).
      return WeatherModel._fromCached(json);
    }
    if (json.containsKey('temperature')) {
      // Formato DTO plano del backend (WeatherResponseDTO).
      return WeatherModel._fromBackendDto(json);
    }
    // Formato RAW de WeatherAPI.com (con claves anidadas location/current).
    return WeatherModel._fromRawApi(json);
  }

  /// Parsea el formato DTO plano del backend (WeatherResponseDTO).
  /// Campos: locationKey, temperature, feelsLike, humidity, windSpeed,
  /// condition, icon, rainProbability, fetchedAt.
  factory WeatherModel._fromBackendDto(Map<String, dynamic> json) {
    // locationKey es "lat,lon" — no tenemos nombre de ciudad desde el DTO plano.
    final locationKey = json['locationKey'] as String? ?? '';
    return WeatherModel(
      locationName:  locationKey,
      region:        '',
      country:       '',
      tempC:         (json['temperature']     as num?)?.toDouble() ?? 0.0,
      feelsLikeC:    (json['feelsLike']       as num?)?.toDouble() ?? 0.0,
      conditionText: json['condition']        as String? ?? '',
      conditionIcon: json['icon']             as String? ?? '',
      humidity:      (json['humidity']        as num?)?.toInt() ?? 0,
      windKph:       (json['windSpeed']       as num?)?.toDouble() ?? 0.0,
      uv:            0.0,
      isDay:         true,
      fetchedAt:     json['fetchedAt']        as String? ?? DateTime.now().toUtc().toIso8601String(),
    );
  }

  /// Parsea el formato RAW de WeatherAPI.com tal como lo proxea el backend.
  factory WeatherModel._fromRawApi(Map<String, dynamic> json) {
    final location  = json['location'] as Map<String, dynamic>? ?? {};
    final current   = json['current']  as Map<String, dynamic>? ?? {};
    final condition = current['condition'] as Map<String, dynamic>? ?? {};

    // Parsear previsión si existe (forecast.forecastday).
    final List<ForecastDayModel> forecast = [];
    if (json['forecast'] != null) {
      final forecastMap  = json['forecast'] as Map<String, dynamic>;
      final forecastDays = forecastMap['forecastday'] as List<dynamic>?;
      if (forecastDays != null) {
        forecast.addAll(
          forecastDays
              .cast<Map<String, dynamic>>()
              .map(ForecastDayModel.fromJson),
        );
      }
    }

    return WeatherModel(
      locationName:  location['name']        as String? ?? '',
      region:        location['region']      as String? ?? '',
      country:       location['country']     as String? ?? '',
      tempC:         (current['temp_c']       as num?)?.toDouble() ?? 0.0,
      tempF:         (current['temp_f']       as num?)?.toDouble() ?? 0.0,
      feelsLikeC:    (current['feelslike_c']  as num?)?.toDouble() ?? 0.0,
      feelsLikeF:    (current['feelslike_f']  as num?)?.toDouble() ?? 0.0,
      conditionText: condition['text']        as String? ?? '',
      conditionIcon: condition['icon']        as String? ?? '',
      humidity:      (current['humidity']     as num?)?.toInt() ?? 0,
      windKph:       (current['wind_kph']     as num?)?.toDouble() ?? 0.0,
      windMph:       (current['wind_mph']     as num?)?.toDouble() ?? 0.0,
      uv:            (current['uv']           as num?)?.toDouble() ?? 0.0,
      isDay:         (current['is_day']       as num?)?.toInt() == 1,
      // Anotar el momento de obtención para calcular expiración de entidad.
      fetchedAt:     DateTime.now().toUtc().toIso8601String(),
      forecast:      forecast,
    );
  }

  /// Parsea el formato plano cacheado generado por [toJson].
  factory WeatherModel._fromCached(Map<String, dynamic> json) {
    final forecastRaw = json['forecast'] as List<dynamic>? ?? [];
    return WeatherModel(
      locationName:  json['locationName']  as String,
      region:        json['region']        as String,
      country:       json['country']       as String,
      tempC:         (json['tempC']        as num).toDouble(),
      tempF:         (json['tempF']        as num? ?? 0).toDouble(),
      feelsLikeC:    (json['feelsLikeC']   as num).toDouble(),
      feelsLikeF:    (json['feelsLikeF']   as num? ?? 0).toDouble(),
      conditionText: json['conditionText'] as String,
      conditionIcon: json['conditionIcon'] as String,
      humidity:      json['humidity']      as int,
      windKph:       (json['windKph']      as num).toDouble(),
      windMph:       (json['windMph']      as num? ?? 0).toDouble(),
      uv:            (json['uv']           as num).toDouble(),
      isDay:         json['isDay']         as bool,
      fetchedAt:     json['fetchedAt']     as String,
      forecast:      forecastRaw
          .cast<Map<String, dynamic>>()
          .map(ForecastDayModel.fromCachedJson)
          .toList(),
    );
  }

  // ─── Serialización ────────────────────────────────────────────────────────────

  /// Serializa a formato plano para almacenamiento en [CacheLocalDataSource].
  Map<String, dynamic> toJson() => {
    'locationName':  locationName,
    'region':        region,
    'country':       country,
    'tempC':         tempC,
    'tempF':         tempF,
    'feelsLikeC':    feelsLikeC,
    'feelsLikeF':    feelsLikeF,
    'conditionText': conditionText,
    'conditionIcon': conditionIcon,
    'humidity':      humidity,
    'windKph':       windKph,
    'windMph':       windMph,
    'uv':            uv,
    'isDay':         isDay,
    'fetchedAt':     fetchedAt,
    'forecast':      forecast.map((d) => d.toJson()).toList(),
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// FORECAST DAY MODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// Modelo de serialización de la previsión de un día.
class ForecastDayModel {
  const ForecastDayModel({
    required this.date,
    required this.maxTempC,
    required this.minTempC,
    required this.conditionText,
    required this.chanceOfRain,
    this.maxTempF = 0.0,
    this.minTempF = 0.0,
  });

  final String date;          // YYYY-MM-DD
  final double maxTempC;
  final double minTempC;
  final double maxTempF;
  final double minTempF;
  final String conditionText;
  final int    chanceOfRain;

  /// Parsea el formato RAW de WeatherAPI.com (forecastday item).
  factory ForecastDayModel.fromJson(Map<String, dynamic> json) {
    final day       = json['day']       as Map<String, dynamic>? ?? {};
    final condition = day['condition']  as Map<String, dynamic>? ?? {};
    return ForecastDayModel(
      date:          json['date']                                   as String? ?? '',
      maxTempC:      (day['maxtemp_c']            as num?)?.toDouble() ?? 0.0,
      minTempC:      (day['mintemp_c']            as num?)?.toDouble() ?? 0.0,
      maxTempF:      (day['maxtemp_f']            as num?)?.toDouble() ?? 0.0,
      minTempF:      (day['mintemp_f']            as num?)?.toDouble() ?? 0.0,
      conditionText: condition['text']                              as String? ?? '',
      chanceOfRain:  (day['daily_chance_of_rain'] as num?)?.toInt() ?? 0,
    );
  }

  /// Parsea el formato plano cacheado generado por [toJson].
  factory ForecastDayModel.fromCachedJson(Map<String, dynamic> json) =>
      ForecastDayModel(
        date:          json['date']          as String,
        maxTempC:      (json['maxTempC']     as num).toDouble(),
        minTempC:      (json['minTempC']     as num).toDouble(),
        maxTempF:      (json['maxTempF']     as num? ?? 0).toDouble(),
        minTempF:      (json['minTempF']     as num? ?? 0).toDouble(),
        conditionText: json['conditionText'] as String,
        chanceOfRain:  json['chanceOfRain']  as int,
      );

  Map<String, dynamic> toJson() => {
    'date':          date,
    'maxTempC':      maxTempC,
    'minTempC':      minTempC,
    'maxTempF':      maxTempF,
    'minTempF':      minTempF,
    'conditionText': conditionText,
    'chanceOfRain':  chanceOfRain,
  };
}
