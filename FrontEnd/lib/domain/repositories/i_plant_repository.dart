/// @file i_plant_repository.dart
/// @description Interfaz del repositorio de plantas y especies.
/// Define el contrato que los use cases usan para acceder a los datos.
/// La implementación concreta (PlantRepositoryImpl) vive en data/.
/// @module Plants
/// @layer Domain
library;

import '../dtos/plants/create_plant_request_dto.dart';
import '../dtos/plants/update_plant_request_dto.dart';
import '../entities/plant.dart';
import '../entities/plant_species.dart';

/// Contrato del repositorio de plantas y especies.
///
/// Los use cases dependen de esta interfaz, nunca de la implementación concreta.
abstract interface class IPlantRepository {
  // ─── Plants ───────────────────────────────────────────────────────────────────

  /// Devuelve la lista de plantas activas del usuario autenticado.
  ///
  /// [throws] AppError si hay error de red o el token es inválido.
  Future<List<Plant>> getUserPlants();

  /// Devuelve la planta con [plantId].
  ///
  /// [throws] AppError.notFound si la planta no existe o no pertenece al usuario.
  Future<Plant> getPlantById(String plantId);

  /// Crea una nueva planta con los datos del [dto].
  ///
  /// [throws] AppError.validation si los datos no son válidos.
  /// [throws] AppError.network si no hay conexión (encola offline).
  Future<Plant> createPlant(CreatePlantRequestDto dto);

  /// Actualiza la planta con [plantId] con los datos del [dto].
  ///
  /// [throws] AppError.notFound si la planta no existe o no pertenece al usuario.
  /// [throws] AppError.network si no hay conexión (encola offline).
  Future<Plant> updatePlant(String plantId, UpdatePlantRequestDto dto);

  /// Elimina (soft-delete) la planta con [plantId].
  ///
  /// [throws] AppError.notFound si la planta no existe o no pertenece al usuario.
  /// [throws] AppError.network si no hay conexión (encola offline).
  Future<void> deletePlant(String plantId);

  // ─── Species ──────────────────────────────────────────────────────────────────

  /// Busca especies del catálogo público por [query].
  ///
  /// Devuelve lista vacía si no hay resultados. No lanza error.
  Future<List<PlantSpecies>> searchSpecies(String query, {int limit = 20});
}
