/// @file plants_list_viewmodel.dart
/// @description ViewModel de la lista de plantas del usuario.
/// Gestiona el estado de la lista, búsqueda de especies y eliminación de plantas.
/// Depende SOLO de interfaces de use cases — nunca de implementaciones concretas.
/// @module Plants
/// @layer Presentation
library;

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../domain/entities/plant.dart';
import '../../../domain/entities/plant_species.dart';
import '../../../domain/interfaces/usecases/plants/i_delete_plant_use_case.dart';
import '../../../domain/interfaces/usecases/plants/i_get_user_plants_use_case.dart';
import '../../../domain/interfaces/usecases/plants/i_search_species_use_case.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PLANTS LIST VIEWMODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// ViewModel de la pantalla de lista de plantas. Extiende [ChangeNotifier] para Provider.
///
/// Estado gestionado:
///  - [plants]            — lista de plantas del usuario.
///  - [isLoading]         — true mientras se carga la lista inicial.
///  - [isDeleting]        — true mientras se procesa una eliminación.
///  - [error]             — último error ocurrido (null si no hay error).
///  - [searchResults]     — resultados de búsqueda de especies (vacío si no hay búsqueda).
///  - [isSearching]       — true mientras se busca en el catálogo de especies.
///  - [availableSpecies]  — especies cargadas para el filtro desplegable.
///  - [filterSpeciesId]   — ID de especie activo como filtro (null = sin filtro).
///
/// [injectable] registrar en container.dart como factory.
/// [dependencies] IGetUserPlantsUseCase, IDeletePlantUseCase, ISearchSpeciesUseCase.
class PlantsListViewModel extends ChangeNotifier {
  final IGetUserPlantsUseCase _getUserPlants;
  final IDeletePlantUseCase   _deletePlant;
  final ISearchSpeciesUseCase _searchSpecies;

  PlantsListViewModel({
    required IGetUserPlantsUseCase getUserPlantsUseCase,
    required IDeletePlantUseCase   deletePlantUseCase,
    required ISearchSpeciesUseCase searchSpeciesUseCase,
  })  : _getUserPlants = getUserPlantsUseCase,
        _deletePlant   = deletePlantUseCase,
        _searchSpecies = searchSpeciesUseCase;

  // ─── Estado ───────────────────────────────────────────────────────────────────

  List<Plant>        _plants           = [];
  bool               _isLoading        = false;
  bool               _isDeleting       = false;
  AppError?          _error;
  List<PlantSpecies> _searchResults    = [];
  bool               _isSearching      = false;
  String             _filterQuery      = '';
  String?            _filterSpeciesId;
  String?            _filterCity;
  List<PlantSpecies> _availableSpecies = [];

  List<Plant>        get plants            => _plants;
  bool               get isLoading         => _isLoading;
  bool               get isDeleting        => _isDeleting;
  AppError?          get error             => _error;
  List<PlantSpecies> get searchResults     => _searchResults;
  bool               get isSearching       => _isSearching;
  String             get filterQuery       => _filterQuery;
  String?            get filterSpeciesId   => _filterSpeciesId;
  String?            get filterCity        => _filterCity;
  List<PlantSpecies> get availableSpecies  => _availableSpecies;

  /// Ciudades únicas extraídas de las plantas del usuario (solo las que tienen plantLocation).
  List<String> get availableCities {
    final cities = _plants
        .where((p) => p.plantLocation != null && p.plantLocation!.isNotEmpty)
        .map((p) => p.plantLocation!)
        .toSet()
        .toList();
    cities.sort();
    return cities;
  }

  /// Plantas filtradas por [_filterQuery], [_filterSpeciesId] y/o [_filterCity].
  List<Plant> get filteredPlants {
    List<Plant> result = _plants;
    if (_filterQuery.isNotEmpty) {
      final q = _filterQuery.toLowerCase();
      result = result.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    if (_filterSpeciesId != null) {
      result = result.where((p) => p.speciesId == _filterSpeciesId).toList();
    }
    if (_filterCity != null) {
      result = result.where((p) => p.plantLocation == _filterCity).toList();
    }
    return result;
  }

  /// true si el usuario no tiene plantas activas.
  bool get isEmpty => !_isLoading && _plants.isEmpty && _error == null;

  /// true si hay plantas pero ninguna coincide con los filtros activos.
  bool get isFilteredEmpty =>
      !_isLoading && _plants.isNotEmpty && filteredPlants.isEmpty;

  /// Plantas que necesitan riego hoy o están atrasadas.
  List<Plant> get plantsNeedingWatering =>
      _plants.where((p) => p.needsWatering).toList();

  // ─── Cargar plantas ───────────────────────────────────────────────────────────

  /// Carga (o recarga) la lista de plantas del usuario autenticado.
  ///
  /// No muestra spinner si ya hay datos en caché (la UI los mantiene visibles).
  Future<void> loadPlants({bool showLoading = true}) async {
    if (showLoading) _startLoading();

    try {
      _plants = await _getUserPlants.execute();
      _error  = null;
    } on AppError catch (e) {
      _error = e;
    } finally {
      _stopLoading();
    }
  }

  /// Alias de [loadPlants] con spinner siempre visible (para pull-to-refresh).
  Future<void> refresh() => loadPlants(showLoading: true);

  // ─── Eliminar planta ──────────────────────────────────────────────────────────

  /// Elimina (soft-delete) la planta con [plantId].
  /// Actualiza optimistamente la lista local antes de confirmar con la API.
  ///
  /// [returns] true si la eliminación fue exitosa.
  Future<bool> deletePlant(String plantId) async {
    _isDeleting = true;
    _error      = null;
    notifyListeners();

    // Optimistic update: quitar de la lista local inmediatamente.
    final previousPlants = List<Plant>.from(_plants);
    _plants = _plants.where((p) => p.id != plantId).toList();
    notifyListeners();

    try {
      await _deletePlant.execute(plantId);
      return true;
    } on AppError catch (e) {
      // Revertir si la API falla.
      _plants = previousPlants;
      _error  = e;
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  // ─── Búsqueda de especies ─────────────────────────────────────────────────────

  /// Busca especies en el catálogo público por [query].
  /// Limpia los resultados si [query] está vacío.
  Future<void> searchSpecies(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _isSearching   = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      _searchResults = await _searchSpecies.execute(query.trim());
    } on AppError {
      _searchResults = []; // No bloquear UI en errores de búsqueda.
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Limpia los resultados de búsqueda de especies.
  void clearSearch() {
    _searchResults = [];
    _isSearching   = false;
    notifyListeners();
  }

  // ─── Filtrado local de plantas ────────────────────────────────────────────────

  /// Filtra la lista local de plantas por nombre (contiene, sin distinguir mayúsculas).
  /// Pasa [query] vacío para quitar el filtro.
  void filterPlants(String query) {
    _filterQuery = query.trim();
    notifyListeners();
  }

  /// Aplica un filtro de especie por [speciesId]; null elimina el filtro.
  void filterBySpecies(String? speciesId) {
    _filterSpeciesId = speciesId;
    notifyListeners();
  }

  /// Aplica un filtro de ciudad por [city]; null elimina el filtro.
  void filterByCity(String? city) {
    _filterCity = city;
    notifyListeners();
  }

  /// Limpia todos los filtros activos (nombre, especie y ciudad).
  void clearFilter() {
    _filterQuery     = '';
    _filterSpeciesId = null;
    _filterCity      = null;
    notifyListeners();
  }

  // ─── Carga de especies disponibles para filtro ────────────────────────────────

  /// Carga todas las especies públicas del catálogo para el selector de filtro.
  /// Solo realiza la petición si la lista aún no está cargada.
  Future<void> loadAvailableSpecies() async {
    if (_availableSpecies.isNotEmpty) return;
    try {
      _availableSpecies = await _searchSpecies.execute('');
      notifyListeners();
    } on AppError {
      // Fallo silencioso — el filtro de especie no estará disponible.
    }
  }

  // ─── Helpers de estado ────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _startLoading() {
    _isLoading = true;
    _error     = null;
    notifyListeners();
  }

  void _stopLoading() {
    _isLoading = false;
    notifyListeners();
  }
}
