/// @file plant_model.dart
/// @description Modelo de serialización de planta para la capa de datos.
/// Solo fromJson/toJson. SIN lógica de negocio ni mapeo a entidad.
/// La conversión PlantModel ↔ Plant la realiza PlantMapper.
/// @module Plants
/// @layer Data
library;

// ═══════════════════════════════════════════════════════════════════════════════
// PLANT MODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// Modelo de serialización de planta. Refleja la estructura JSON de la API.
///
/// Regla estricta: NO contiene lógica de negocio, validaciones ni referencias
/// a entidades de dominio. Solo fromJson y toJson.
class PlantModel {
  const PlantModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.wateringFrequencyDays,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.speciesId,
    this.photo,
    this.location,
    this.plantLocation,
    this.plantLocationLat,
    this.plantLocationLon,
    this.notes,
    this.lightNeed,
    this.pruningFrequency,
    this.nextPruning,
    this.considerWeatherForWatering = false,
    this.lastWatered,
    this.nextWatering,
    this.careOverrides,
  });

  final String  id;
  final String  userId;
  final String  name;
  final String? speciesId;
  final String? photo;
  final String? location;
  final String? plantLocation;
  final double? plantLocationLat;
  final double? plantLocationLon;
  final String? notes;
  final int     wateringFrequencyDays;
  final String? lightNeed;     // 'Low' | 'Medium' | 'High'
  final int?    pruningFrequency;
  final String? nextPruning;   // ISO 8601 string tal como llega del servidor.
  final bool    considerWeatherForWatering;
  final String? lastWatered;   // ISO 8601 string tal como llega del servidor.
  final String? nextWatering;  // ISO 8601 string tal como llega del servidor.
  final bool    isActive;
  final PlantCareOverridesModel? careOverrides;
  final String  createdAt;     // ISO 8601 string.
  final String  updatedAt;     // ISO 8601 string.

  // ─── Deserialización ─────────────────────────────────────────────────────────

  factory PlantModel.fromJson(Map<String, dynamic> json) => PlantModel(
    id:                    json['_id']                    as String? ?? json['id'] as String,
    userId:                json['userId']                 as String,
    name:                  json['name']                   as String,
    speciesId:             json['speciesId']              as String?,
    photo:                 json['photo']                  as String?,
    location:              json['location']               as String?,
    plantLocation:         json['plantLocation']          as String?,
    plantLocationLat:      (json['plantLocationLat']      as num?)?.toDouble(),
    plantLocationLon:      (json['plantLocationLon']      as num?)?.toDouble(),
    notes:                 json['notes']                  as String?,
    wateringFrequencyDays: ((json['wateringFrequency'] ?? json['wateringFrequencyDays']) as int?) ?? 7,
    lightNeed:             json['lightNeed']              as String?,
    pruningFrequency:      json['pruningFrequency']       as int?,
    nextPruning:           json['nextPruning']            as String?,
    considerWeatherForWatering: json['considerWeatherForWatering'] as bool? ?? false,
    lastWatered:           json['lastWatered']            as String?,
    nextWatering:          json['nextWatering']           as String?,
    isActive:              json['isActive']               as bool? ?? true,
    createdAt:             json['createdAt']              as String,
    updatedAt:             json['updatedAt']              as String,
    careOverrides:         json['careOverrides'] != null
        ? PlantCareOverridesModel.fromJson(
            json['careOverrides'] as Map<String, dynamic>,
          )
        : null,
  );

  // ─── Serialización ────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id':                    id,
    'userId':                userId,
    'name':                  name,
    if (speciesId    != null) 'speciesId':    speciesId,
    if (photo        != null) 'photo':        photo,
    if (location         != null) 'location':         location,
    if (plantLocation    != null) 'plantLocation':    plantLocation,
    if (plantLocationLat != null) 'plantLocationLat': plantLocationLat,
    if (plantLocationLon != null) 'plantLocationLon': plantLocationLon,
    if (notes            != null) 'notes':            notes,
    'wateringFrequencyDays': wateringFrequencyDays,
    if (lightNeed        != null) 'lightNeed':        lightNeed,
    if (pruningFrequency != null) 'pruningFrequency': pruningFrequency,
    if (nextPruning      != null) 'nextPruning':      nextPruning,
    'considerWeatherForWatering': considerWeatherForWatering,
    if (lastWatered  != null) 'lastWatered':  lastWatered,
    if (nextWatering != null) 'nextWatering': nextWatering,
    'isActive':              isActive,
    if (careOverrides != null) 'careOverrides': careOverrides!.toJson(),
    'createdAt':             createdAt,
    'updatedAt':             updatedAt,
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// PLANT CARE OVERRIDES MODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// Modelo de serialización de las anulaciones de cuidado.
class PlantCareOverridesModel {
  const PlantCareOverridesModel({
    this.wateringFrequencyDays,
    this.lightNeed,
  });

  final int?    wateringFrequencyDays;
  final String? lightNeed;

  factory PlantCareOverridesModel.fromJson(Map<String, dynamic> json) =>
      PlantCareOverridesModel(
        wateringFrequencyDays: json['wateringFrequencyDays'] as int?,
        lightNeed:             json['lightNeed']             as String?,
      );

  Map<String, dynamic> toJson() => {
    if (wateringFrequencyDays != null) 'wateringFrequencyDays': wateringFrequencyDays,
    if (lightNeed             != null) 'lightNeed':             lightNeed,
  };
}
