/// @file update_plant_request_dto.dart
/// @description DTO de solicitud de actualización de planta.
/// Todos los campos son opcionales — solo se envían los que cambian.
/// @module Plants
/// @layer Domain
library;

/// DTO para actualizar una planta existente. Todos los campos son opcionales.
class UpdatePlantRequestDto {
  const UpdatePlantRequestDto({
    this.name,
    this.photo,
    this.location,
    this.plantLocation,
    this.plantLocationLat,
    this.plantLocationLon,
    this.notes,
    this.wateringFrequencyDays,
    this.lightNeed,
    this.pruningFrequency,
    this.considerWeatherForWatering,
    this.lastWatered,
  });

  /// Nuevo nombre visible de la planta.
  final String? name;

  /// Nueva URL de foto (Cloudinary, obtenida previamente via /upload/image).
  final String? photo;

  /// Nueva ubicación física de la planta.
  final String? location;

  /// Nueva ciudad/municipio de la planta.
  final String? plantLocation;

  /// Nueva latitud geográfica.
  final double? plantLocationLat;

  /// Nueva longitud geográfica.
  final double? plantLocationLon;

  /// Nuevas notas del usuario.
  final String? notes;

  /// Nueva frecuencia de riego en días.
  final int?    wateringFrequencyDays;

  /// Nueva necesidad de luz: 'Low' | 'Medium' | 'High'.
  final String? lightNeed;

  /// Nueva frecuencia de poda en días.
  final int?    pruningFrequency;

  /// Si el riego debe considerar el pronóstico del tiempo.
  final bool?   considerWeatherForWatering;

  /// ISO-8601 del último riego (usado por el endpoint POST /plants/:id/water).
  final String? lastWatered;

  /// Serializa el DTO a Map — solo incluye los campos no nulos.
  Map<String, dynamic> toJson() => {
    if (name                         != null) 'name':              name,
    if (photo                        != null) 'photo':             photo,
    if (location                     != null) 'location':          location,
    if (plantLocation                != null) 'plantLocation':     plantLocation,
    if (plantLocationLat             != null) 'plantLocationLat':  plantLocationLat,
    if (plantLocationLon             != null) 'plantLocationLon':  plantLocationLon,
    if (notes                        != null) 'notes':             notes,
    if (wateringFrequencyDays        != null) 'wateringFrequency': wateringFrequencyDays,
    if (lightNeed                    != null) 'lightNeed':         lightNeed,
    if (pruningFrequency             != null) 'pruningFrequency':  pruningFrequency,
    if (considerWeatherForWatering   != null) 'considerWeatherForWatering': considerWeatherForWatering,
    if (lastWatered                  != null) 'lastWatered':       lastWatered,
  };
}
