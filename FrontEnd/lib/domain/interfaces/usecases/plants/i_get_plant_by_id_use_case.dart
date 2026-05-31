/// @file i_get_plant_by_id_use_case.dart
/// @description Interfaz del caso de uso para obtener una planta por ID.
/// @module Plants
/// @layer Domain
library;

import '../../../entities/plant.dart';

abstract interface class IGetPlantByIdUseCase {
  /// Devuelve la planta con [plantId] o lanza AppError.notFound.
  Future<Plant> execute(String plantId);
}
