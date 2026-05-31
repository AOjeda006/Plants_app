/// @file i_plant_species_mapper.dart
/// @description Interfaz del mapper de especies. Contrato PlantSpeciesModel ↔ PlantSpecies.
/// @module Plants
/// @layer Data
library;

import '../../domain/entities/plant_species.dart';
import '../models/plant_species_model.dart';

/// Contrato de conversión entre el modelo de serialización y la entidad de dominio.
///
/// [injectable] registrar en container.dart como singleton.
abstract interface class IPlantSpeciesMapper {
  /// Convierte un modelo de serialización a entidad de dominio.
  PlantSpecies toEntity(PlantSpeciesModel model);

  /// Convierte una entidad de dominio a modelo de serialización.
  PlantSpeciesModel toModel(PlantSpecies entity);
}
