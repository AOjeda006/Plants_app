/// @file plant_detail_viewmodel.dart
/// @description ViewModel de la pantalla de detalle de una planta.
/// Gestiona la carga de la planta y su eliminación.
/// Depende SOLO de interfaces de use cases — nunca de implementaciones concretas.
/// @module Plants
/// @layer Presentation
library;

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../domain/entities/plant.dart';
import '../../../domain/entities/plant_species.dart';
import '../../../domain/entities/weather_data.dart';
import '../../../domain/dtos/plants/update_plant_request_dto.dart';
import '../../../domain/interfaces/usecases/plants/i_delete_plant_use_case.dart';
import '../../../domain/interfaces/usecases/plants/i_get_plant_by_id_use_case.dart';
import '../../../domain/interfaces/usecases/plants/i_search_species_use_case.dart';
import '../../../domain/interfaces/usecases/plants/i_update_plant_use_case.dart';
import '../../../domain/interfaces/usecases/weather/i_get_current_weather_use_case.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PLANT DETAIL VIEWMODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// ViewModel de la pantalla de detalle de planta. Extiende [ChangeNotifier] para Provider.
///
/// Estado gestionado:
///  - [plant]            — planta cargada (null mientras se carga o si hay error).
///  - [species]          — especie de la planta (null si no tiene o mientras se carga).
///  - [isLoading]        — true mientras se carga la planta.
///  - [isDeleting]       — true mientras se procesa la eliminación.
///  - [error]            — último error ocurrido (null si no hay error).
///  - [weatherData]      — datos meteorológicos del perfil del usuario (null si no disponible).
///  - [isLoadingWeather] — true mientras se carga el clima.
///  - [weatherError]     — error del clima (null si no hay error).
///
/// [injectable] registrar en container.dart como factory.
/// [dependencies] IGetPlantByIdUseCase, IDeletePlantUseCase, ISearchSpeciesUseCase, IGetCurrentWeatherUseCase.
class PlantDetailViewModel extends ChangeNotifier {
  final IGetPlantByIdUseCase       _getPlantById;
  final IDeletePlantUseCase        _deletePlant;
  final IUpdatePlantUseCase        _updatePlant;
  final ISearchSpeciesUseCase      _searchSpecies;
  final IGetCurrentWeatherUseCase  _getWeather;

  PlantDetailViewModel({
    required IGetPlantByIdUseCase      getPlantByIdUseCase,
    required IDeletePlantUseCase       deletePlantUseCase,
    required IUpdatePlantUseCase       updatePlantUseCase,
    required ISearchSpeciesUseCase     searchSpeciesUseCase,
    required IGetCurrentWeatherUseCase getWeatherUseCase,
  })  : _getPlantById  = getPlantByIdUseCase,
        _deletePlant   = deletePlantUseCase,
        _updatePlant   = updatePlantUseCase,
        _searchSpecies = searchSpeciesUseCase,
        _getWeather    = getWeatherUseCase;

  // ─── Estado ───────────────────────────────────────────────────────────────────

  Plant?        _plant;
  PlantSpecies? _species;
  bool          _isLoading        = false;
  bool          _isDeleting       = false;
  bool          _isWatering       = false;
  AppError?     _error;

  WeatherData?  _weatherData;
  bool          _isLoadingWeather  = false;
  AppError?     _weatherError;
  String        _weatherLocation   = '';

  Plant?        get plant            => _plant;
  /// Especie de la planta; null si no tiene especie o aún se está cargando.
  PlantSpecies? get species          => _species;
  bool          get isLoading        => _isLoading;
  bool          get isDeleting       => _isDeleting;
  bool          get isWatering       => _isWatering;
  AppError?     get error            => _error;
  WeatherData?  get weatherData      => _weatherData;
  bool          get isLoadingWeather => _isLoadingWeather;
  AppError?     get weatherError     => _weatherError;

  /// true si la planta necesita riego hoy.
  bool get showWateringAlert => _plant?.needsWatering ?? false;

  // ─── Cargar planta ────────────────────────────────────────────────────────────

  /// Carga la planta con [plantId] y, si tiene especie, carga sus datos.
  ///
  /// [userLocation] — ubicación del perfil del usuario (p.ej. "Sevilla").
  /// Si se proporciona, también carga el clima para esa localización.
  Future<void> loadPlant(String plantId, {String? userLocation}) async {
    _isLoading = true;
    _error     = null;
    _plant     = null;
    _species   = null;
    notifyListeners();

    try {
      _plant = await _getPlantById.execute(plantId);
      if (_plant!.hasSpecies) await _loadSpecies(_plant!.speciesId!);
    } on AppError catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Cargar clima en paralelo, sin bloquear la UI de la planta.
    if (userLocation != null && userLocation.trim().isNotEmpty) {
      await _loadWeather(userLocation.trim());
    }
  }

  /// Carga la especie cuyo id coincide con [speciesId].
  /// Obtiene todas las especies públicas y busca por ID (catálogo pequeño: ~10 especies).
  Future<void> _loadSpecies(String speciesId) async {
    try {
      final all     = await _searchSpecies.execute('');
      final matches = all.where((s) => s.id == speciesId);
      if (matches.isNotEmpty) _species = matches.first;
      // Si no hay coincidencia, _species permanece null — la UI lo gestiona.
    } on AppError {
      // Error no crítico: la planta sigue siendo visible aunque no cargue la especie.
    }
  }

  // ─── Eliminar planta ──────────────────────────────────────────────────────────

  /// Elimina la planta actual. Devuelve true si la eliminación fue exitosa.
  ///
  /// [returns] true si la operación fue exitosa; false si hubo error.
  Future<bool> deletePlant() async {
    if (_plant == null) return false;

    _isDeleting = true;
    _error      = null;
    notifyListeners();

    try {
      await _deletePlant.execute(_plant!.id);
      return true;
    } on AppError catch (e) {
      _error = e;
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  // ─── Riego manual ────────────────────────────────────────────────────────────

  /// Registra un riego manual: actualiza nextWatering y lastWatered en el backend.
  ///
  /// Usa la frecuencia de riego actual para calcular la próxima fecha server-side.
  /// Actualiza [_plant] con la respuesta del servidor.
  ///
  /// [returns] true si el riego fue registrado correctamente; false si hubo error.
  Future<bool> waterPlant() async {
    if (_plant == null || _isWatering) return false;

    _isWatering = true;
    _error      = null;
    notifyListeners();

    try {
      final updated = await _updatePlant.execute(
        _plant!.id,
        UpdatePlantRequestDto(
          wateringFrequencyDays: _plant!.wateringFrequencyDays,
          lastWatered: DateTime.now().toUtc().toIso8601String(),
        ),
      );
      _plant = updated;
      return true;
    } on AppError catch (e) {
      _error = e;
      return false;
    } finally {
      _isWatering = false;
      notifyListeners();
    }
  }

  // ─── Cargar clima ─────────────────────────────────────────────────────────────

  /// Carga el clima para [location] desde el use case.
  Future<void> _loadWeather(String location) async {
    _weatherLocation  = location;
    _isLoadingWeather = true;
    _weatherError     = null;
    notifyListeners();

    try {
      _weatherData = await _getWeather.execute(location);
    } on AppError catch (e) {
      _weatherError = e;
    } finally {
      _isLoadingWeather = false;
      notifyListeners();
    }
  }

  /// Recarga el clima manualmente (p.ej. al pulsar el botón de reintentar).
  Future<void> refreshWeather() async {
    if (_weatherLocation.isEmpty) return;
    await _loadWeather(_weatherLocation);
  }

  // ─── Helpers de estado ────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
