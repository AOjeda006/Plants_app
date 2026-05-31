/// @file i_create_plant_use_case.dart
/// @description Interfaz del caso de uso para crear una planta.
/// @module Plants
/// @layer Domain
library;

import '../../../dtos/plants/create_plant_request_dto.dart';
import '../../../entities/plant.dart';

abstract interface class ICreatePlantUseCase {
  /// Crea una nueva planta y la devuelve con su ID asignado.
  Future<Plant> execute(CreatePlantRequestDto dto);
}
