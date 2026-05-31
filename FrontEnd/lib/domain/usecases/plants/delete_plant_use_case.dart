/// @file delete_plant_use_case.dart
/// @description Implementación del caso de uso para eliminar (soft-delete) una planta.
/// @module Plants
/// @layer Domain
library;

import '../../interfaces/usecases/plants/i_delete_plant_use_case.dart';
import '../../repositories/i_plant_repository.dart';

/// [implements] IDeletePlantUseCase
/// [dependencies] IPlantRepository
class DeletePlantUseCase implements IDeletePlantUseCase {
  final IPlantRepository _repository;
  const DeletePlantUseCase({required IPlantRepository repository})
      : _repository = repository;

  @override
  Future<void> execute(String plantId) => _repository.deletePlant(plantId);
}
