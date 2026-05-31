/// @file i_search_species_use_case.dart
/// @description Interfaz del caso de uso para buscar especies de plantas.
/// @module Plants
/// @layer Domain
library;

import '../../../entities/plant_species.dart';

abstract interface class ISearchSpeciesUseCase {
  /// Busca especies por [query]. Devuelve lista vacía si no hay resultados.
  Future<List<PlantSpecies>> execute(String query, {int limit = 20});
}
