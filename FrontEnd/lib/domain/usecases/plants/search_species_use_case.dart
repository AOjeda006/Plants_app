/// @file search_species_use_case.dart
/// @description Implementación del caso de uso para buscar especies del catálogo.
/// @module Plants
/// @layer Domain
library;

import '../../entities/plant_species.dart';
import '../../interfaces/usecases/plants/i_search_species_use_case.dart';
import '../../repositories/i_plant_repository.dart';

/// [implements] ISearchSpeciesUseCase
/// [dependencies] IPlantRepository
class SearchSpeciesUseCase implements ISearchSpeciesUseCase {
  final IPlantRepository _repository;
  const SearchSpeciesUseCase({required IPlantRepository repository})
      : _repository = repository;

  @override
  Future<List<PlantSpecies>> execute(String query, {int limit = 20}) =>
      _repository.searchSpecies(query, limit: limit);
}
