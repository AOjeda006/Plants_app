/// @file location_remote_data_source.dart
/// @description Fuente de datos remota para el catálogo de ubicaciones.
/// Encapsula la llamada a GET /locations/search?q=... del backend.
/// @module User
/// @layer Data
library;

import '../../../core/network/api_client.dart';
import '../../../domain/entities/location.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// LOCATION REMOTE DATA SOURCE
// ═══════════════════════════════════════════════════════════════════════════════

/// Datasource remoto para el catálogo de capitales de provincia españolas.
///
/// [injectable] registrar en container.dart como singleton.
/// [dependencies] ApiClient.
class LocationRemoteDataSource {
  final ApiClient _apiClient;

  const LocationRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  /// Busca capitales de provincia por nombre (parcial, case-insensitive).
  /// Si [query] está vacío, devuelve todas las 52 capitales.
  ///
  /// [returns] Lista de [Location] que coinciden con la búsqueda.
  Future<List<Location>> search(String query) async {
    final results = await _apiClient.get<List<dynamic>>(
      '/locations/search',
      queryParameters: {'q': query},
    );
    return results
        .map((e) => Location.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
