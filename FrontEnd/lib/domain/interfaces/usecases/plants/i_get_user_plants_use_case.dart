/// @file i_get_user_plants_use_case.dart
/// @description Interfaz del caso de uso para obtener las plantas del usuario.
/// @module Plants
/// @layer Domain
library;

import '../../../entities/plant.dart';

abstract interface class IGetUserPlantsUseCase {
  /// Devuelve la lista de plantas activas del usuario autenticado.
  Future<List<Plant>> execute();
}
