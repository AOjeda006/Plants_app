/// @file update_plant_use_case.dart
/// @description Implementación del caso de uso para actualizar una planta.
/// @module Plants
/// @layer Domain
library;

import '../../dtos/plants/update_plant_request_dto.dart';
import '../../entities/plant.dart';
import '../../interfaces/usecases/plants/i_update_plant_use_case.dart';
import '../../repositories/i_plant_repository.dart';

/// [implements] IUpdatePlantUseCase
/// [dependencies] IPlantRepository
class UpdatePlantUseCase implements IUpdatePlantUseCase {
  final IPlantRepository _repository;
  const UpdatePlantUseCase({required IPlantRepository repository})
      : _repository = repository;

  @override
  Future<Plant> execute(String plantId, UpdatePlantRequestDto dto) =>
      _repository.updatePlant(plantId, dto);
}
