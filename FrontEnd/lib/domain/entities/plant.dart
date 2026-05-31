/// @file plant.dart
/// @description Entidad de dominio Plant. Representa una planta del usuario.
/// Objeto puro de Dart, sin dependencias de Flutter ni paquetes externos.
/// Los mappers convierten PlantModel ↔ Plant.
/// @module Plants
/// @layer Domain
library;

// ═══════════════════════════════════════════════════════════════════════════════
// PLANT ENTITY
// ═══════════════════════════════════════════════════════════════════════════════

/// Entidad de dominio que representa una planta del usuario.
///
/// Todos los campos son inmutables (final). Usar [copyWith] para actualizaciones.
/// Sin lógica de serialización — eso pertenece a PlantModel (data layer).
class Plant {
  const Plant({
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

  /// Identificador único de la planta (MongoDB ObjectId como String).
  final String id;

  /// ID del usuario propietario.
  final String userId;

  /// Nombre visible de la planta.
  final String name;

  /// ID de la especie asociada, o null si no tiene especie asignada.
  final String? speciesId;

  /// URL de la foto (Cloudinary), o null si no tiene.
  final String? photo;

  /// Ubicación física de la planta (p.ej. "Balcón sur"), o null.
  final String? location;

  /// Ciudad/municipio donde se encuentra la planta (del catálogo de capitales), o null.
  final String? plantLocation;

  /// Latitud geográfica de la ubicación de la planta, o null.
  final double? plantLocationLat;

  /// Longitud geográfica de la ubicación de la planta, o null.
  final double? plantLocationLon;

  /// Notas libres del usuario, o null.
  final String? notes;

  /// Frecuencia de riego en días (p.ej. 7 = semanal).
  final int wateringFrequencyDays;

  /// Necesidad de luz de la planta ('Low', 'Medium', 'High'), o null.
  final String? lightNeed;

  /// Frecuencia de poda en días, o null si no aplica.
  final int? pruningFrequency;

  /// Fecha UTC de la próxima poda calculada, o null si no aplica.
  final DateTime? nextPruning;

  /// true si el riego debe considerar el pronóstico del tiempo.
  final bool considerWeatherForWatering;

  /// Fecha UTC del último riego registrado, o null si nunca se ha regado.
  final DateTime? lastWatered;

  /// Fecha UTC del próximo riego calculado, o null si no aplica.
  final DateTime? nextWatering;

  /// true si la planta está activa (no eliminada lógicamente).
  final bool isActive;

  /// Anulaciones manuales de los parámetros de cuidado de la especie, o null.
  final PlantCareOverrides? careOverrides;

  /// Fecha de creación del registro.
  final DateTime createdAt;

  /// Fecha de última actualización del registro.
  final DateTime updatedAt;

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// true si la planta necesita riego hoy o ya estaba atrasada.
  bool get needsWatering {
    if (nextWatering == null) return false;
    final today = DateTime.utc(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    return !nextWatering!.isAfter(today);
  }

  /// Días restantes hasta el próximo riego. Negativo = ya debería haberse regado.
  int get daysUntilNextWatering {
    if (nextWatering == null) return 0;
    final today = DateTime.utc(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    return nextWatering!.difference(today).inDays;
  }

  /// true si la planta tiene una especie asignada.
  bool get hasSpecies => speciesId != null && speciesId!.isNotEmpty;

  /// true si la planta tiene foto.
  bool get hasPhoto => photo != null && photo!.isNotEmpty;

  // ─── copyWith ────────────────────────────────────────────────────────────────

  /// Devuelve una copia de la planta con los campos indicados modificados.
  Plant copyWith({
    String?             id,
    String?             userId,
    String?             name,
    String?             speciesId,
    String?             photo,
    String?             location,
    String?             plantLocation,
    double?             plantLocationLat,
    double?             plantLocationLon,
    String?             notes,
    int?                wateringFrequencyDays,
    String?             lightNeed,
    int?                pruningFrequency,
    DateTime?           nextPruning,
    bool?               considerWeatherForWatering,
    DateTime?           lastWatered,
    DateTime?           nextWatering,
    bool?               isActive,
    PlantCareOverrides? careOverrides,
    DateTime?           createdAt,
    DateTime?           updatedAt,
  }) {
    return Plant(
      id:                    id                    ?? this.id,
      userId:                userId                ?? this.userId,
      name:                  name                  ?? this.name,
      speciesId:             speciesId             ?? this.speciesId,
      photo:                 photo                 ?? this.photo,
      location:              location              ?? this.location,
      plantLocation:         plantLocation         ?? this.plantLocation,
      plantLocationLat:      plantLocationLat      ?? this.plantLocationLat,
      plantLocationLon:      plantLocationLon      ?? this.plantLocationLon,
      notes:                 notes                 ?? this.notes,
      wateringFrequencyDays: wateringFrequencyDays ?? this.wateringFrequencyDays,
      lightNeed:             lightNeed             ?? this.lightNeed,
      pruningFrequency:      pruningFrequency      ?? this.pruningFrequency,
      nextPruning:           nextPruning           ?? this.nextPruning,
      considerWeatherForWatering: considerWeatherForWatering ?? this.considerWeatherForWatering,
      lastWatered:           lastWatered           ?? this.lastWatered,
      nextWatering:          nextWatering          ?? this.nextWatering,
      isActive:              isActive              ?? this.isActive,
      careOverrides:         careOverrides         ?? this.careOverrides,
      createdAt:             createdAt             ?? this.createdAt,
      updatedAt:             updatedAt             ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Plant && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Plant(id: $id, name: $name, userId: $userId)';
}

// ═══════════════════════════════════════════════════════════════════════════════
// PLANT CARE OVERRIDES
// ═══════════════════════════════════════════════════════════════════════════════

/// Anulación manual de los parámetros de cuidado heredados de la especie.
/// El usuario puede ajustar la frecuencia de riego o la necesidad de luz.
class PlantCareOverrides {
  const PlantCareOverrides({
    this.wateringFrequencyDays,
    this.lightNeed,
  });

  /// Frecuencia de riego personalizada en días, o null si usa la de la especie.
  final int?    wateringFrequencyDays;

  /// Necesidad de luz personalizada ('Low', 'Medium', 'High'), o null.
  final String? lightNeed;

  PlantCareOverrides copyWith({
    int?    wateringFrequencyDays,
    String? lightNeed,
  }) {
    return PlantCareOverrides(
      wateringFrequencyDays: wateringFrequencyDays ?? this.wateringFrequencyDays,
      lightNeed:             lightNeed             ?? this.lightNeed,
    );
  }
}
