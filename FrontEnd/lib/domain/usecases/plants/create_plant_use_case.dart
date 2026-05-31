/// @file create_plant_use_case.dart
/// @description Implementación del caso de uso para crear una planta.
/// @module Plants
/// @layer Domain
library;

import '../../dtos/plants/create_plant_request_dto.dart';
import '../../entities/plant.dart';
import '../../interfaces/usecases/plants/i_create_plant_use_case.dart';
import '../../repositories/i_plant_repository.dart';

/// [implements] ICreatePlantUseCase
/// [dependencies] IPlantRepository
class CreatePlantUseCase implements ICreatePlantUseCase {
  final IPlantRepository _repository;
  const CreatePlantUseCase({required IPlantRepository repository})
      : _repository = repository;

  @override
  Future<Plant> execute(CreatePlantRequestDto dto) =>
      _repository.createPlant(dto);
}
