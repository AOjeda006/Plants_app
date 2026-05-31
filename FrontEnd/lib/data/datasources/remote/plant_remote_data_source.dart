/// @file plant_remote_data_source.dart
/// @description Fuente de datos remota para plantas y especies.
/// Encapsula todas las llamadas HTTP a los módulos /plants y /species de la API.
/// Devuelve Maps crudos (los mappers convierten a entidades en el repositorio).
/// Lanza AppError en caso de fallo — propagado desde ApiClient.
/// @module Plants
/// @layer Data
library;

import '../../../core/network/api_client.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PLANT REMOTE DATA SOURCE
// ═══════════════════════════════════════════════════════════════════════════════

/// Datasource remoto para las operaciones de plantas y búsqueda de especies.
///
/// Endpoints cubiertos:
///  - GET    /plants                → getUserPlants
///  - GET    /plants/:id            → getPlantById
///  - POST   /plants                → createPlant
///  - PUT    /plants/:id            → updatePlant
///  - DELETE /plants/:id            → deletePlant
///  - GET    /species/search?q=...  → searchSpecies
///
/// [injectable] registrar en container.dart.
/// [dependencies] ApiClient.
class PlantRemoteDataSource {
  final ApiClient _apiClient;

  const PlantRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  // ─── Get user plants ──────────────────────────────────────────────────────────

  /// Devuelve la lista de plantas del usuario autenticado.
  ///
  /// [returns] Lista de Maps con datos de planta tal como los devuelve la API.
  /// [throws] AppError.unauthorized si el token es inválido o ha expirado.
  Future<List<Map<String, dynamic>>> getUserPlants() async {
    final result = await _apiClient.get<List<dynamic>>('/plants');
    return result.cast<Map<String, dynamic>>();
  }

  // ─── Get plant by ID ──────────────────────────────────────────────────────────

  /// Devuelve una planta por su ID.
  ///
  /// [returns] Map con datos de la planta.
  /// [throws] AppError.notFound si la planta no existe o no pertenece al usuario.
  Future<Map<String, dynamic>> getPlantById(String plantId) async {
    return _apiClient.get<Map<String, dynamic>>('/plants/$plantId');
  }

  // ─── Create plant ─────────────────────────────────────────────────────────────

  /// Crea una nueva planta con los datos del [body].
  ///
  /// [returns] Map con los datos de la planta creada (incluye ID asignado).
  /// [throws] AppError.validation si los datos no superan la validación (422).
  Future<Map<String, dynamic>> createPlant(Map<String, dynamic> body) async {
    return _apiClient.post<Map<String, dynamic>>('/plants', data: body);
  }

  // ─── Update plant ─────────────────────────────────────────────────────────────

  /// Actualiza la planta con [plantId] con los datos del [body].
  ///
  /// [returns] Map con los datos de la planta actualizada.
  /// [throws] AppError.notFound si la planta no existe o no pertenece al usuario.
  Future<Map<String, dynamic>> updatePlant(
    String plantId,
    Map<String, dynamic> body,
  ) async {
    return _apiClient.put<Map<String, dynamic>>('/plants/$plantId', data: body);
  }

  // ─── Delete plant ─────────────────────────────────────────────────────────────

  /// Elimina (soft-delete) la planta con [plantId].
  ///
  /// [throws] AppError.notFound si la planta no existe o no pertenece al usuario.
  Future<void> deletePlant(String plantId) async {
    await _apiClient.delete<dynamic>('/plants/$plantId');
  }

  // ─── Search species ───────────────────────────────────────────────────────────

  /// Busca especies del catálogo público por nombre o nombre científico.
  ///
  /// [query]  — texto de búsqueda (mínimo 1 carácter).
  /// [limit]  — número máximo de resultados (por defecto 20).
  /// [returns] Lista de Maps con datos de especie.
  Future<List<Map<String, dynamic>>> searchSpecies(
    String query, {
    int limit = 20,
  }) async {
    final result = await _apiClient.get<List<dynamic>>(
      '/species/search',
      queryParameters: {'q': query, 'limit': limit},
    );
    return result.cast<Map<String, dynamic>>();
  }
}
