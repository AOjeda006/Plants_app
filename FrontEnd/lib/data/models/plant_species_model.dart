/// @file plant_species_model.dart
/// @description Modelo de serialización de especie de planta para la capa de datos.
/// Solo fromJson/toJson. SIN lógica de negocio ni mapeo a entidad.
/// La conversión PlantSpeciesModel ↔ PlantSpecies la realiza PlantSpeciesMapper.
/// @module Plants
/// @layer Data
library;

// ═══════════════════════════════════════════════════════════════════════════════
// PLANT SPECIES MODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// Modelo de serialización de especie. Refleja la estructura JSON de la API.
class PlantSpeciesModel {
  const PlantSpeciesModel({
    required this.id,
    required this.name,
    required this.scientificName,
    this.image,
    required this.careRequirements,
    required this.climateCompatibility,
    required this.tips,
    required this.isPublic,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.requiresPruning,
    this.pruningMonths,
    this.produceFruit,
    this.harvestMonths,
    this.seasonalWateringAdjustment,
    this.minRainfallMm,
    this.waterLitersPerWatering,
  });

  final String                        id;
  final String                        name;
  final String                        scientificName;
  final String?                       image;
  final SpeciesCareRequirementsModel  careRequirements;
  final List<String>                  climateCompatibility;
  final List<String>                  tips;
  final bool                          isPublic;
  final String                        createdBy;
  final String                        createdAt;
  final String                        updatedAt;
  final bool?                                requiresPruning;
  final List<int>?                           pruningMonths;
  final bool?                                produceFruit;
  final List<int>?                           harvestMonths;
  final SeasonalWateringAdjustmentModel?     seasonalWateringAdjustment;
  final double?                              minRainfallMm;
  final double?                              waterLitersPerWatering;

  // ─── Deserialización ─────────────────────────────────────────────────────────

  factory PlantSpeciesModel.fromJson(Map<String, dynamic> json) => PlantSpeciesModel(
    id:             json['_id']            as String? ?? json['id'] as String,
    name:           json['name']           as String,
    scientificName: json['scientificName'] as String,
    image:          json['image']          as String?,
    isPublic:        json['isPublic']        as bool? ?? false,
    createdBy:       json['createdBy']       as String? ?? '',
    createdAt:       json['createdAt']       as String? ?? '',
    updatedAt:       json['updatedAt']       as String? ?? '',
    requiresPruning: json['requiresPruning'] as bool?,
    pruningMonths:   (json['pruningMonths'] as List<dynamic>?)
        ?.map((e) => e as int)
        .toList(),
    produceFruit:    json['produceFruit']    as bool?,
    harvestMonths:   (json['harvestMonths'] as List<dynamic>?)
        ?.map((e) => e as int)
        .toList(),
    seasonalWateringAdjustment: json['seasonalWateringAdjustment'] != null
        ? SeasonalWateringAdjustmentModel.fromJson(
            json['seasonalWateringAdjustment'] as Map<String, dynamic>,
          )
        : null,
    minRainfallMm:          (json['minRainfallMm']          as num?)?.toDouble(),
    waterLitersPerWatering: (json['waterLitersPerWatering'] as num?)?.toDouble(),
    climateCompatibility:
        (json['climateCompatibility'] as List<dynamic>? ?? []).cast<String>(),
    tips: (json['tips'] as List<dynamic>? ?? []).cast<String>(),
    careRequirements: SpeciesCareRequirementsModel.fromJson(
      json['careRequirements'] as Map<String, dynamic>,
    ),
  );

  // ─── Serialización ────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id':                   id,
    'name':                 name,
    'scientificName':       scientificName,
    'image':                image,
    'careRequirements':     careRequirements.toJson(),
    'climateCompatibility': climateCompatibility,
    'tips':                 tips,
    'isPublic':             isPublic,
    'createdBy':            createdBy,
    'createdAt':            createdAt,
    'updatedAt':            updatedAt,
    if (requiresPruning            != null) 'requiresPruning':            requiresPruning,
    if (pruningMonths              != null) 'pruningMonths':              pruningMonths,
    if (produceFruit               != null) 'produceFruit':               produceFruit,
    if (harvestMonths              != null) 'harvestMonths':              harvestMonths,
    if (seasonalWateringAdjustment != null) 'seasonalWateringAdjustment': seasonalWateringAdjustment!.toJson(),
    if (minRainfallMm              != null) 'minRainfallMm':              minRainfallMm,
    if (waterLitersPerWatering     != null) 'waterLitersPerWatering':     waterLitersPerWatering,
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// SEASONAL WATERING ADJUSTMENT MODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// Modelo de serialización del ajuste estacional de riego.
class SeasonalWateringAdjustmentModel {
  const SeasonalWateringAdjustmentModel({this.summer, this.winter});

  final double? summer;
  final double? winter;

  factory SeasonalWateringAdjustmentModel.fromJson(Map<String, dynamic> json) =>
      SeasonalWateringAdjustmentModel(
        summer: (json['summer'] as num?)?.toDouble(),
        winter: (json['winter'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
    if (summer != null) 'summer': summer,
    if (winter != null) 'winter': winter,
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// SPECIES CARE REQUIREMENTS MODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// Modelo de serialización de requisitos de cuidado de la especie.
class SpeciesCareRequirementsModel {
  const SpeciesCareRequirementsModel({
    required this.wateringDays,
    required this.lightNeed,
    this.temperatureRange,
  });

  final int     wateringDays;
  final String  lightNeed;
  final SpeciesTemperatureRangeModel? temperatureRange;

  factory SpeciesCareRequirementsModel.fromJson(Map<String, dynamic> json) =>
      SpeciesCareRequirementsModel(
        wateringDays: json['wateringDays'] as int,
        lightNeed:    json['lightNeed']    as String,
        temperatureRange: json['temperatureRange'] != null
            ? SpeciesTemperatureRangeModel.fromJson(
                json['temperatureRange'] as Map<String, dynamic>,
              )
            : null,
      );

  Map<String, dynamic> toJson() => {
    'wateringDays': wateringDays,
    'lightNeed':    lightNeed,
    if (temperatureRange != null) 'temperatureRange': temperatureRange!.toJson(),
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// SPECIES TEMPERATURE RANGE MODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// Modelo de serialización del rango de temperatura óptima.
class SpeciesTemperatureRangeModel {
  const SpeciesTemperatureRangeModel({required this.min, required this.max});

  final double min;
  final double max;

  factory SpeciesTemperatureRangeModel.fromJson(Map<String, dynamic> json) =>
      SpeciesTemperatureRangeModel(
        min: ((json['min'] as num?) ?? 0).toDouble(),
        max: ((json['max'] as num?) ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {'min': min, 'max': max};
}
