/// @file get_user_plants_use_case.dart
/// @description Implementación del caso de uso para obtener las plantas del usuario.
/// @module Plants
/// @layer Domain
library;

import '../../entities/plant.dart';
import '../../interfaces/usecases/plants/i_get_user_plants_use_case.dart';
import '../../repositories/i_plant_repository.dart';

/// [implements] IGetUserPlantsUseCase
/// [dependencies] IPlantRepository
class GetUserPlantsUseCase implements IGetUserPlantsUseCase {
  final IPlantRepository _repository;
  const GetUserPlantsUseCase({required IPlantRepository repository})
      : _repository = repository;

  @override
  Future<List<Plant>> execute() => _repository.getUserPlants();
}
