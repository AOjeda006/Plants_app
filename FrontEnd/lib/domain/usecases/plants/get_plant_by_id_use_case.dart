/// @file get_plant_by_id_use_case.dart
/// @description Implementación del caso de uso para obtener una planta por ID.
/// @module Plants
/// @layer Domain
library;

import '../../entities/plant.dart';
import '../../interfaces/usecases/plants/i_get_plant_by_id_use_case.dart';
import '../../repositories/i_plant_repository.dart';

/// [implements] IGetPlantByIdUseCase
/// [dependencies] IPlantRepository
class GetPlantByIdUseCase implements IGetPlantByIdUseCase {
  final IPlantRepository _repository;
  const GetPlantByIdUseCase({required IPlantRepository repository})
      : _repository = repository;

  @override
  Future<Plant> execute(String plantId) => _repository.getPlantById(plantId);
}
