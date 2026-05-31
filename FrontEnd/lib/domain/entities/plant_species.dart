/// @file plant_species.dart
/// @description Entidad de dominio PlantSpecies. Representa una especie del catálogo.
/// Objeto puro de Dart, sin dependencias de Flutter ni paquetes externos.
/// Los mappers convierten PlantSpeciesModel ↔ PlantSpecies.
/// @module Plants
/// @layer Domain
library;

// ═══════════════════════════════════════════════════════════════════════════════
// PLANT SPECIES ENTITY
// ═══════════════════════════════════════════════════════════════════════════════

/// Entidad de dominio que representa una especie de planta del catálogo.
///
/// Todos los campos son inmutables (final). Usar [copyWith] para actualizaciones.
class PlantSpecies {
  const PlantSpecies({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.image,
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

  /// Identificador único de la especie (MongoDB ObjectId como String).
  final String id;

  /// Nombre común de la especie (p.ej. "Monstera").
  final String name;

  /// Nombre científico (p.ej. "Monstera deliciosa").
  final String scientificName;

  /// URL de la imagen representativa de la especie, o null si no tiene imagen asignada.
  final String? image;

  /// Requisitos de cuidado estándar de la especie.
  final SpeciesCareRequirements careRequirements;

  /// Climas compatibles con la especie (p.ej. ['tropical', 'subtropical']).
  final List<String> climateCompatibility;

  /// Consejos de cuidado y curiosidades.
  final List<String> tips;

  /// true si la especie está aprobada y visible en el catálogo público.
  final bool isPublic;

  /// ID del usuario que propuso la especie.
  final String createdBy;

  /// Fecha de creación del registro.
  final DateTime createdAt;

  /// Fecha de última actualización.
  final DateTime updatedAt;

  /// Indica si la especie requiere poda anual.
  final bool? requiresPruning;

  /// Meses recomendados de poda (1 = enero, 12 = diciembre). Solo aplica si [requiresPruning] es true.
  final List<int>? pruningMonths;

  /// Indica si la especie produce frutos o cosecha.
  final bool? produceFruit;

  /// Meses del año en los que se puede cosechar (1 = enero, 12 = diciembre). Solo aplica si [produceFruit] es true.
  final List<int>? harvestMonths;

  /// Ajuste estacional de la frecuencia de riego (opcional).
  final SeasonalWateringAdjustment? seasonalWateringAdjustment;

  /// Precipitación mínima en mm para considerar la planta regada por lluvia (opcional).
  final double? minRainfallMm;

  /// Cantidad de agua en litros por riego (opcional, informativo).
  final double? waterLitersPerWatering;

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// true si la especie está pendiente de aprobación.
  bool get isPendingApproval => !isPublic;

  /// Frecuencia de riego estándar de la especie en días.
  int get standardWateringDays => careRequirements.wateringDays;

  // ─── copyWith ────────────────────────────────────────────────────────────────

  PlantSpecies copyWith({
    String?                  id,
    String?                  name,
    String?                  scientificName,
    String?                  image,  // null preserva el valor actual; no fuerza null explícito
    SpeciesCareRequirements? careRequirements,
    List<String>?            climateCompatibility,
    List<String>?            tips,
    bool?                    isPublic,
    String?                  createdBy,
    DateTime?                createdAt,
    DateTime?                updatedAt,
    bool?                         requiresPruning,
    List<int>?                    pruningMonths,
    bool?                         produceFruit,
    List<int>?                    harvestMonths,
    SeasonalWateringAdjustment?   seasonalWateringAdjustment,
    double?                       minRainfallMm,
    double?                       waterLitersPerWatering,
  }) {
    return PlantSpecies(
      id:                          id                          ?? this.id,
      name:                        name                        ?? this.name,
      scientificName:              scientificName              ?? this.scientificName,
      image:                       image                       ?? this.image,
      careRequirements:            careRequirements            ?? this.careRequirements,
      climateCompatibility:        climateCompatibility        ?? this.climateCompatibility,
      tips:                        tips                        ?? this.tips,
      isPublic:                    isPublic                    ?? this.isPublic,
      createdBy:                   createdBy                   ?? this.createdBy,
      createdAt:                   createdAt                   ?? this.createdAt,
      updatedAt:                   updatedAt                   ?? this.updatedAt,
      requiresPruning:             requiresPruning             ?? this.requiresPruning,
      pruningMonths:                pruningMonths                ?? this.pruningMonths,
      produceFruit:                produceFruit                ?? this.produceFruit,
      harvestMonths:               harvestMonths               ?? this.harvestMonths,
      seasonalWateringAdjustment:  seasonalWateringAdjustment  ?? this.seasonalWateringAdjustment,
      minRainfallMm:               minRainfallMm               ?? this.minRainfallMm,
      waterLitersPerWatering:      waterLitersPerWatering      ?? this.waterLitersPerWatering,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PlantSpecies && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PlantSpecies(id: $id, name: $name)';
}

// ═══════════════════════════════════════════════════════════════════════════════
// SPECIES CARE REQUIREMENTS
// ═══════════════════════════════════════════════════════════════════════════════

/// Requisitos de cuidado estándar definidos en el catálogo para una especie.
class SpeciesCareRequirements {
  const SpeciesCareRequirements({
    required this.wateringDays,
    required this.lightNeed,
    this.temperatureRange,
  });

  /// Frecuencia de riego estándar en días (p.ej. 7 = semanal).
  final int wateringDays;

  /// Necesidad de luz: 'Low', 'Medium' o 'High'.
  final String lightNeed;

  /// Rango de temperatura óptima (°C), o null si no está especificado.
  final SpeciesTemperatureRange? temperatureRange;
}

// ═══════════════════════════════════════════════════════════════════════════════
// SPECIES TEMPERATURE RANGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Rango de temperatura óptima para la especie (en °C).
class SpeciesTemperatureRange {
  const SpeciesTemperatureRange({required this.min, required this.max});

  /// Temperatura mínima óptima en °C.
  final double min;

  /// Temperatura máxima óptima en °C.
  final double max;
}

// ═══════════════════════════════════════════════════════════════════════════════
// SEASONAL WATERING ADJUSTMENT
// ═══════════════════════════════════════════════════════════════════════════════

/// Ajuste estacional de la frecuencia de riego de la especie.
///
/// Los valores son multiplicadores sobre [careRequirements.wateringDays]:
///   < 1.0 → regar más frecuentemente (p.ej. 0.7 = 30% más frecuente en verano)
///   > 1.0 → regar menos frecuentemente (p.ej. 1.5 = 50% menos en invierno)
/// Primavera y otoño no se ajustan (factor = 1.0).
class SeasonalWateringAdjustment {
  const SeasonalWateringAdjustment({this.summer, this.winter});

  /// Multiplicador de riego en verano (jun–ago). Null = sin ajuste.
  final double? summer;

  /// Multiplicador de riego en invierno (dic–feb). Null = sin ajuste.
  final double? winter;
}
