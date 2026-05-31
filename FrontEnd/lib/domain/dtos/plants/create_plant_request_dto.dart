/// @file create_plant_request_dto.dart
/// @description DTO de solicitud de creación de planta.
/// Contiene los datos que el usuario envía al crear una nueva planta.
/// @module Plants
/// @layer Domain
library;

/// DTO para crear una nueva planta.
class CreatePlantRequestDto {
  const CreatePlantRequestDto({
    required this.name,
    required this.location,
    required this.plantLocation,
    required this.wateringFrequency,
    required this.lightNeed,
    this.plantLocationLat,
    this.plantLocationLon,
    this.speciesId,
    this.photo,
    this.notes,
  });

  /// Nombre visible de la planta (obligatorio).
  final String  name;

  /// Ubicación: 'Interior' o 'Exterior' (obligatorio).
  final String  location;

  /// Ciudad/municipio donde se encuentra la planta (obligatorio).
  final String  plantLocation;

  /// Frecuencia de riego en días (obligatorio).
  final int     wateringFrequency;

  /// Necesidad de luz: 'Low', 'Medium' o 'High' (obligatorio).
  final String  lightNeed;

  /// Latitud geográfica de la ubicación de la planta (opcional).
  final double? plantLocationLat;

  /// Longitud geográfica de la ubicación de la planta (opcional).
  final double? plantLocationLon;

  /// ID de la especie asociada (opcional).
  final String? speciesId;

  /// URL de la foto (Cloudinary, obtenida previamente via /upload/image).
  final String? photo;

  /// Notas libres del usuario.
  final String? notes;

  /// Serializa el DTO a Map para enviarlo en el cuerpo de la petición HTTP.
  Map<String, dynamic> toJson() => {
    'name':              name,
    'location':          location,
    'plantLocation':     plantLocation,
    'wateringFrequency': wateringFrequency,
    'lightNeed':         lightNeed,
    if (plantLocationLat != null) 'plantLocationLat': plantLocationLat,
    if (plantLocationLon != null) 'plantLocationLon': plantLocationLon,
    if (speciesId != null) 'speciesId': speciesId,
    if (photo     != null) 'photo':     photo,
    if (notes     != null) 'notes':     notes,
  };
}
