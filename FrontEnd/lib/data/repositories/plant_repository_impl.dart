/// @file plant_repository_impl.dart
/// @description Implementación del repositorio de plantas y especies.
/// Coordina PlantRemoteDataSource (API) y CacheLocalDataSource (caché con TTL).
/// Los errores de red se propagan al ViewModel/UI que los muestra con
/// Snackbar — no se encolan acciones offline.
/// @module Plants
/// @layer Data
library;

import '../../core/storage/cache_local_data_source.dart';
import '../../domain/dtos/plants/create_plant_request_dto.dart';
import '../../domain/dtos/plants/update_plant_request_dto.dart';
import '../../domain/entities/plant.dart';
import '../../domain/entities/plant_species.dart';
import '../../domain/repositories/i_plant_repository.dart';
import '../datasources/remote/plant_remote_data_source.dart';
import '../i_mappers/i_plant_mapper.dart';
import '../i_mappers/i_plant_species_mapper.dart';
import '../models/plant_model.dart';
import '../models/plant_species_model.dart';

// ─── Constantes de caché ──────────────────────────────────────────────────────

const String _kPlantsListKey  = 'plants_list';
const Duration _kPlantsTtl   = Duration(minutes: 5);
String _kPlantKey(String id)  => 'plant_$id';

// ═══════════════════════════════════════════════════════════════════════════════
// PLANT REPOSITORY IMPL
// ═══════════════════════════════════════════════════════════════════════════════

/// Implementación concreta de [IPlantRepository].
///
/// Estrategia de caché:
///  - GET: cache-first → miss → API → guarda en caché.
///  - Mutaciones (POST/PUT/DELETE): API → invalida caché → si AppError.network,
///    el error se propaga al ViewModel/UI para mostrarse con Snackbar.
///
/// [implements] IPlantRepository
/// [injectable] registrar en container.dart.
/// [dependencies] PlantRemoteDataSource, CacheLocalDataSource,
///               IPlantMapper, IPlantSpeciesMapper.
class PlantRepositoryImpl implements IPlantRepository {
  final PlantRemoteDataSource _remote;
  final CacheLocalDataSource  _cache;
  final IPlantMapper          _plantMapper;
  final IPlantSpeciesMapper   _speciesMapper;

  const PlantRepositoryImpl({
    required PlantRemoteDataSource remote,
    required CacheLocalDataSource  cache,
    required IPlantMapper          plantMapper,
    required IPlantSpeciesMapper   speciesMapper,
  })  : _remote       = remote,
        _cache        = cache,
        _plantMapper  = plantMapper,
        _speciesMapper = speciesMapper;

  // ─── Get user plants ──────────────────────────────────────────────────────────

  @override
  Future<List<Plant>> getUserPlants() async {
    // Cache-first: si hay datos frescos, devolverlos directamente.
    final cached = await _cache.get<List<dynamic>>(_kPlantsListKey);
    if (cached != null) {
      return cached
          .cast<Map<String, dynamic>>()
          .map((json) => _plantMapper.toEntity(PlantModel.fromJson(json)))
          .toList();
    }

    // Cache miss: llamar a la API y guardar resultado en caché.
    final rawList = await _remote.getUserPlants();
    await _cache.set(_kPlantsListKey, rawList, ttl: _kPlantsTtl);
    return rawList
        .map((json) => _plantMapper.toEntity(PlantModel.fromJson(json)))
        .toList();
  }

  // ─── Get plant by ID ──────────────────────────────────────────────────────────

  @override
  Future<Plant> getPlantById(String plantId) async {
    final key    = _kPlantKey(plantId);
    final cached = await _cache.get<Map<String, dynamic>>(key);
    if (cached != null) {
      return _plantMapper.toEntity(PlantModel.fromJson(cached));
    }

    final raw = await _remote.getPlantById(plantId);
    await _cache.set(key, raw, ttl: _kPlantsTtl);
    return _plantMapper.toEntity(PlantModel.fromJson(raw));
  }

  // ─── Create plant ─────────────────────────────────────────────────────────────

  @override
  Future<Plant> createPlant(CreatePlantRequestDto dto) async {
    // Los errores de red propagan al ViewModel/UI.
    final raw = await _remote.createPlant(dto.toJson());
    await _cache.invalidate(_kPlantsListKey); // Invalidar lista al crear.
    return _plantMapper.toEntity(PlantModel.fromJson(raw));
  }

  // ─── Update plant ─────────────────────────────────────────────────────────────

  @override
  Future<Plant> updatePlant(String plantId, UpdatePlantRequestDto dto) async {
    final raw = await _remote.updatePlant(plantId, dto.toJson());
    // Invalidar entradas de caché afectadas.
    await _cache.invalidate(_kPlantsListKey);
    await _cache.invalidate(_kPlantKey(plantId));
    return _plantMapper.toEntity(PlantModel.fromJson(raw));
  }

  // ─── Delete plant ─────────────────────────────────────────────────────────────

  @override
  Future<void> deletePlant(String plantId) async {
    await _remote.deletePlant(plantId);
    await _cache.invalidate(_kPlantsListKey);
    await _cache.invalidate(_kPlantKey(plantId));
  }

  // ─── Search species ───────────────────────────────────────────────────────────

  @override
  Future<List<PlantSpecies>> searchSpecies(String query, {int limit = 20}) async {
    // Las búsquedas no se cachean: siempre frescas y dependientes del query.
    final rawList = await _remote.searchSpecies(query, limit: limit);
    return rawList
        .map((json) => _speciesMapper.toEntity(PlantSpeciesModel.fromJson(json)))
        .toList();
  }
}
