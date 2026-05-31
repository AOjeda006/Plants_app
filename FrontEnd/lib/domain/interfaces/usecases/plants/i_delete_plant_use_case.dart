/// @file i_delete_plant_use_case.dart
/// @description Interfaz del caso de uso para eliminar una planta (soft-delete).
/// @module Plants
/// @layer Domain
library;
abstract interface class IDeletePlantUseCase {
  /// Elimina (soft-delete) la planta con [plantId].
  Future<void> execute(String plantId);
}
