/// @file plant_mapper.dart
/// @description Implementación del mapper de plantas.
/// Convierte PlantModel ↔ Plant normalizando tipos y valores por defecto.
/// Toda la lógica de transformación vive aquí, nunca en el Model ni en la entidad.
/// @module Plants
/// @layer Data
library;

import '../../core/utils/date_utils.dart';
import '../../domain/entities/plant.dart';
import '../i_mappers/i_plant_mapper.dart';
import '../models/plant_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PLANT MAPPER
// ═══════════════════════════════════════════════════════════════════════════════

/// Implementación de [IPlantMapper].
///
/// [implements] IPlantMapper
/// [injectable] registrar en container.dart como singleton.
class PlantMapper implements IPlantMapper {

  // ─── PlantModel → Plant ───────────────────────────────────────────────────────

  @override
  Plant toEntity(PlantModel model) {
    return Plant(
      id:                    model.id,
      userId:                model.userId,
      name:                  model.name,
      speciesId:             model.speciesId,
      photo:                 model.photo,
      location:              model.location,
      plantLocation:         model.plantLocation,
      plantLocationLat:      model.plantLocationLat,
      plantLocationLon:      model.plantLocationLon,
      notes:                 model.notes,
      wateringFrequencyDays: model.wateringFrequencyDays,
      lightNeed:             model.lightNeed,
      pruningFrequency:      model.pruningFrequency,
      nextPruning:           PlantDateUtils.parseUtc(model.nextPruning),
      considerWeatherForWatering: model.considerWeatherForWatering,
      lastWatered:           PlantDateUtils.parseUtc(model.lastWatered),
      nextWatering:          PlantDateUtils.parseUtc(model.nextWatering),
      isActive:              model.isActive,
      createdAt:             PlantDateUtils.parseUtc(model.createdAt) ?? DateTime.now().toUtc(),
      updatedAt:             PlantDateUtils.parseUtc(model.updatedAt) ?? DateTime.now().toUtc(),
      careOverrides:         model.careOverrides != null
          ? _toOverrides(model.careOverrides!)
          : null,
    );
  }

  // ─── Plant → PlantModel ───────────────────────────────────────────────────────

  @override
  PlantModel toModel(Plant entity) {
    return PlantModel(
      id:                    entity.id,
      userId:                entity.userId,
      name:                  entity.name,
      speciesId:             entity.speciesId,
      photo:                 entity.photo,
      location:              entity.location,
      plantLocation:         entity.plantLocation,
      plantLocationLat:      entity.plantLocationLat,
      plantLocationLon:      entity.plantLocationLon,
      notes:                 entity.notes,
      wateringFrequencyDays: entity.wateringFrequencyDays,
      lightNeed:             entity.lightNeed,
      pruningFrequency:      entity.pruningFrequency,
      nextPruning:           entity.nextPruning != null
          ? PlantDateUtils.toIso8601(entity.nextPruning!)
          : null,
      considerWeatherForWatering: entity.considerWeatherForWatering,
      lastWatered:           entity.lastWatered != null
          ? PlantDateUtils.toIso8601(entity.lastWatered!)
          : null,
      nextWatering:          entity.nextWatering != null
          ? PlantDateUtils.toIso8601(entity.nextWatering!)
          : null,
      isActive:              entity.isActive,
      createdAt:             PlantDateUtils.toIso8601(entity.createdAt),
      updatedAt:             PlantDateUtils.toIso8601(entity.updatedAt),
      careOverrides:         entity.careOverrides != null
          ? _toOverridesModel(entity.careOverrides!)
          : null,
    );
  }

  // ─── Helpers de careOverrides ─────────────────────────────────────────────────

  PlantCareOverrides _toOverrides(PlantCareOverridesModel model) {
    return PlantCareOverrides(
      wateringFrequencyDays: model.wateringFrequencyDays,
      lightNeed:             model.lightNeed,
    );
  }

  PlantCareOverridesModel _toOverridesModel(PlantCareOverrides overrides) {
    return PlantCareOverridesModel(
      wateringFrequencyDays: overrides.wateringFrequencyDays,
      lightNeed:             overrides.lightNeed,
    );
  }
}
