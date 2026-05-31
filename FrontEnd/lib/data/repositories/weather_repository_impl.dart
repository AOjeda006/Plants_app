/// @file weather_repository_impl.dart
/// @description Implementación del repositorio de clima.
/// Coordina WeatherRemoteDataSource (proxy backend) y CacheLocalDataSource (TTL).
/// Incluye fallback a datos mock cuando mockWeatherMode está activo en AppConfig
/// o cuando el backend es inalcanzable — útil para demos del TFG sin conexión.
/// @module Weather
/// @layer Data
library;

import '../../core/config/app_config.dart';
import '../../core/errors/app_error.dart';
import '../../core/storage/cache_local_data_source.dart';
import '../../domain/entities/weather_data.dart';
import '../../domain/repositories/i_weather_repository.dart';
import '../datasources/remote/weather_remote_data_source.dart';
import '../i_mappers/i_weather_mapper.dart';
import '../models/weather_model.dart';

// ─── Constantes de caché ──────────────────────────────────────────────────────

String _kCurrentKey(String location) =>
    'weather_current_${location.toLowerCase().replaceAll(' ', '_')}';
String _kForecastKey(String location) =>
    'weather_forecast_${location.toLowerCase().replaceAll(' ', '_')}';

// ═══════════════════════════════════════════════════════════════════════════════
// WEATHER REPOSITORY IMPL
// ═══════════════════════════════════════════════════════════════════════════════

/// Implementación concreta de [IWeatherRepository].
///
/// Estrategia de caché:
///  - cache-first con TTL derivado de [AppConfig.weatherCacheTtlSeconds].
///  - En miss: llama al backend, guarda resultado en caché en formato plano.
///  - En AppError.network: si mockWeatherMode, devuelve [WeatherData] mock.
///    De lo contrario relanza el error para que el ViewModel muestre el banner.
///
/// [implements] IWeatherRepository
/// [injectable] registrar en container.dart.
/// [dependencies] WeatherRemoteDataSource, CacheLocalDataSource, IWeatherMapper.
class WeatherRepositoryImpl implements IWeatherRepository {
  final WeatherRemoteDataSource _remote;
  final CacheLocalDataSource    _cache;
  final IWeatherMapper          _mapper;

  const WeatherRepositoryImpl({
    required WeatherRemoteDataSource remote,
    required CacheLocalDataSource    cache,
    required IWeatherMapper          mapper,
  })  : _remote = remote,
        _cache  = cache,
        _mapper = mapper;

  // ─── Get current weather ──────────────────────────────────────────────────────

  @override
  Future<WeatherData> getCurrentWeather(String location) async {
    final key    = _kCurrentKey(location);
    final ttl    = _weatherTtl;

    // Cache-first: si hay datos frescos, devolverlos sin llamar a la API.
    final cached = await _cache.get<Map<String, dynamic>>(key);
    if (cached != null) {
      return _mapper.toEntity(WeatherModel.fromJson(cached));
    }

    try {
      final raw = await _remote.getCurrentWeather(location);
      // Guardar en formato plano (toJson) para permitir reconstrucción coherente.
      final model = WeatherModel.fromJson(raw);
      await _cache.set(key, model.toJson(), ttl: ttl);
      return _mapper.toEntity(model);
    } on AppError catch (e) {
      if (e.code == ErrorCode.network && AppConfig.instance.mockWeatherMode) {
        // TFG: si no hay conexión y mockWeatherMode está activo, datos demo.
        return _mockCurrentWeather(location);
      }
      rethrow;
    }
  }

  // ─── Get forecast ─────────────────────────────────────────────────────────────

  @override
  Future<WeatherData> getForecast(String location, {int days = 7}) async {
    final key = _kForecastKey(location);
    final ttl = _weatherTtl;

    final cached = await _cache.get<Map<String, dynamic>>(key);
    if (cached != null) {
      return _mapper.toEntity(WeatherModel.fromJson(cached));
    }

    try {
      final raw   = await _remote.getForecast(location, days: days);
      final model = WeatherModel.fromJson(raw);
      await _cache.set(key, model.toJson(), ttl: ttl);
      return _mapper.toEntity(model);
    } on AppError catch (e) {
      if (e.code == ErrorCode.network && AppConfig.instance.mockWeatherMode) {
        return _mockForecastWeather(location, days);
      }
      rethrow;
    }
  }

  // ─── Privados ─────────────────────────────────────────────────────────────────

  /// TTL del caché calculado desde la configuración centralizada.
  Duration get _weatherTtl =>
      Duration(seconds: AppConfig.instance.weatherCacheTtlSeconds);

  /// Datos mock de clima actual usados en demos sin conexión (mockWeatherMode).
  WeatherData _mockCurrentWeather(String location) {
    return WeatherData(
      locationName:  location,
      region:        'Demo',
      country:       'ES',
      tempC:         22.0,
      feelsLikeC:    21.0,
      conditionText: 'Sunny (Demo)',
      conditionIcon: '',
      humidity:      55,
      windKph:       12.0,
      uv:            4.0,
      isDay:         true,
      fetchedAt:     DateTime.now().toUtc(),
    );
  }

  /// Datos mock de previsión usados en demos sin conexión (mockWeatherMode).
  WeatherData _mockForecastWeather(String location, int days) {
    final today = DateTime.now().toUtc();
    final forecast = List.generate(
      days,
      (i) => ForecastDay(
        date:          DateTime.utc(today.year, today.month, today.day + i),
        maxTempC:      22.0 + i.toDouble(),
        minTempC:      14.0 + i.toDouble(),
        conditionText: 'Partly cloudy (Demo)',
        chanceOfRain:  20,
      ),
    );
    return WeatherData(
      locationName:  location,
      region:        'Demo',
      country:       'ES',
      tempC:         22.0,
      feelsLikeC:    21.0,
      conditionText: 'Partly cloudy (Demo)',
      conditionIcon: '',
      humidity:      55,
      windKph:       12.0,
      uv:            4.0,
      isDay:         true,
      fetchedAt:     DateTime.now().toUtc(),
      forecast:      forecast,
    );
  }
}
