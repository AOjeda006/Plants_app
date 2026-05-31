/// @file i_update_plant_use_case.dart
/// @description Interfaz del caso de uso para actualizar una planta.
/// @module Plants
/// @layer Domain
library;

import '../../../dtos/plants/update_plant_request_dto.dart';
import '../../../entities/plant.dart';

abstract interface class IUpdatePlantUseCase {
  /// Actualiza la planta con [plantId] con los datos de [dto].
  Future<Plant> execute(String plantId, UpdatePlantRequestDto dto);
}
