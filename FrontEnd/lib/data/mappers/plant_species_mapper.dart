/// @file plant_species_mapper.dart
/// @description Implementación del mapper de especies de plantas.
/// Convierte PlantSpeciesModel ↔ PlantSpecies normalizando tipos y valores.
/// @module Plants
/// @layer Data
library;

import '../../core/utils/date_utils.dart';
import '../../domain/entities/plant_species.dart';
import '../i_mappers/i_plant_species_mapper.dart';
import '../models/plant_species_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PLANT SPECIES MAPPER
// ═══════════════════════════════════════════════════════════════════════════════

/// Implementación de [IPlantSpeciesMapper].
///
/// [implements] IPlantSpeciesMapper
/// [injectable] registrar en container.dart como singleton.
class PlantSpeciesMapper implements IPlantSpeciesMapper {

  // ─── PlantSpeciesModel → PlantSpecies ─────────────────────────────────────────

  @override
  PlantSpecies toEntity(PlantSpeciesModel model) {
    return PlantSpecies(
      id:                   model.id,
      name:                 model.name,
      scientificName:       model.scientificName,
      image:                model.image,
      climateCompatibility: List.unmodifiable(model.climateCompatibility),
      tips:                 List.unmodifiable(model.tips),
      isPublic:             model.isPublic,
      createdBy:            model.createdBy,
      createdAt:            PlantDateUtils.parseUtc(model.createdAt) ?? DateTime.now().toUtc(),
      updatedAt:            PlantDateUtils.parseUtc(model.updatedAt) ?? DateTime.now().toUtc(),
      careRequirements:     _toCareRequirements(model.careRequirements),
      requiresPruning:             model.requiresPruning,
      pruningMonths:               model.pruningMonths != null
          ? List.unmodifiable(model.pruningMonths!)
          : null,
      produceFruit:                model.produceFruit,
      harvestMonths:               model.harvestMonths != null
          ? List.unmodifiable(model.harvestMonths!)
          : null,
      seasonalWateringAdjustment:  model.seasonalWateringAdjustment != null
          ? SeasonalWateringAdjustment(
              summer: model.seasonalWateringAdjustment!.summer,
              winter: model.seasonalWateringAdjustment!.winter,
            )
          : null,
      minRainfallMm:               model.minRainfallMm,
      waterLitersPerWatering:      model.waterLitersPerWatering,
    );
  }

  // ─── PlantSpecies → PlantSpeciesModel ─────────────────────────────────────────

  @override
  PlantSpeciesModel toModel(PlantSpecies entity) {
    return PlantSpeciesModel(
      id:                   entity.id,
      name:                 entity.name,
      scientificName:       entity.scientificName,
      image:                entity.image,
      climateCompatibility: entity.climateCompatibility,
      tips:                 entity.tips,
      isPublic:             entity.isPublic,
      createdBy:            entity.createdBy,
      createdAt:            PlantDateUtils.toIso8601(entity.createdAt),
      updatedAt:            PlantDateUtils.toIso8601(entity.updatedAt),
      careRequirements:     _toCareRequirementsModel(entity.careRequirements),
      requiresPruning:             entity.requiresPruning,
      pruningMonths:               entity.pruningMonths,
      produceFruit:                entity.produceFruit,
      harvestMonths:               entity.harvestMonths,
      seasonalWateringAdjustment:  entity.seasonalWateringAdjustment != null
          ? SeasonalWateringAdjustmentModel(
              summer: entity.seasonalWateringAdjustment!.summer,
              winter: entity.seasonalWateringAdjustment!.winter,
            )
          : null,
      minRainfallMm:               entity.minRainfallMm,
      waterLitersPerWatering:      entity.waterLitersPerWatering,
    );
  }

  // ─── Helpers de careRequirements ──────────────────────────────────────────────

  SpeciesCareRequirements _toCareRequirements(SpeciesCareRequirementsModel model) {
    return SpeciesCareRequirements(
      wateringDays:     model.wateringDays,
      lightNeed:        model.lightNeed,
      temperatureRange: model.temperatureRange != null
          ? SpeciesTemperatureRange(
              min: model.temperatureRange!.min,
              max: model.temperatureRange!.max,
            )
          : null,
    );
  }

  SpeciesCareRequirementsModel _toCareRequirementsModel(SpeciesCareRequirements reqs) {
    return SpeciesCareRequirementsModel(
      wateringDays:     reqs.wateringDays,
      lightNeed:        reqs.lightNeed,
      temperatureRange: reqs.temperatureRange != null
          ? SpeciesTemperatureRangeModel(
              min: reqs.temperatureRange!.min,
              max: reqs.temperatureRange!.max,
            )
          : null,
    );
  }
}
