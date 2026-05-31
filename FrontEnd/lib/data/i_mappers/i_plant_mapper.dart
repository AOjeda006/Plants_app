/// @file i_plant_mapper.dart
/// @description Interfaz del mapper de plantas. Contrato PlantModel ↔ Plant.
/// @module Plants
/// @layer Data
library;

import '../../domain/entities/plant.dart';
import '../models/plant_model.dart';

/// Contrato de conversión entre el modelo de serialización y la entidad de dominio.
///
/// [injectable] registrar en container.dart como singleton.
abstract interface class IPlantMapper {
  /// Convierte un modelo de serialización a entidad de dominio.
  Plant toEntity(PlantModel model);

  /// Convierte una entidad de dominio a modelo de serialización.
  PlantModel toModel(Plant entity);
}
