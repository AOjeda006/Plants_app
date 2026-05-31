/**
 * @file PlantSpecies.ts
 * @description Entidad de dominio que representa una especie de planta (catálogo compartido).
 * Puede ser creada por usuarios (propuesta) y aprobada por admins para ser pública.
 * @module Plants
 * @layer Domain
 */

import type { LightNeed } from './Plant.js';

/**
 * Rango de temperatura óptima para la especie.
 */
export interface TemperatureRange {
  /** Temperatura mínima en grados Celsius */
  min: number;
  /** Temperatura máxima en grados Celsius */
  max: number;
}

/**
 * Ajuste estacional de la frecuencia de riego de la especie.
 * Los valores son multiplicadores sobre wateringFrequency:
 *   < 1.0 → regar más frecuentemente (p.ej. 0.7 = 30% más frecuente)
 *   > 1.0 → regar menos frecuentemente (p.ej. 1.5 = 50% menos frecuente)
 * Primavera y otoño no se ajustan (factor = 1.0).
 */
export interface SeasonalWateringAdjustment {
  /** Multiplicador de riego en verano (jun–ago en hemisferio norte). */
  summer?: number;
  /** Multiplicador de riego en invierno (dic–feb en hemisferio norte). */
  winter?: number;
}

/**
 * Requisitos de cuidado base de la especie.
 * Sirven como valores por defecto cuando el usuario crea una planta de esta especie.
 */
export interface CareRequirements {
  /** Frecuencia de riego recomendada en días */
  wateringDays: number;
  /** Necesidad de luz */
  lightNeed: LightNeed;
  /** Rango de temperatura óptima (opcional) */
  temperatureRange?: TemperatureRange;
}

/**
 * Entrada del historial de auditoría de cambios en la especie.
 */
export interface AuditEntry {
  /** Fecha del cambio */
  date: Date;
  /** Id del usuario que realizó el cambio */
  userId: string;
  /** Descripción resumida de los cambios */
  changes: string;
}

/**
 * Entidad de dominio PlantSpecies.
 * Representa una especie del catálogo compartido de la aplicación.
 */
export class PlantSpecies {
  /** Identificador único */
  readonly id: string;

  /** Nombre común de la especie */
  readonly name: string;

  /** Nombre científico (binomial) */
  readonly scientificName: string;

  /** URL de la imagen representativa en Cloudinary (nullable — puede no tener imagen asignada) */
  readonly image?: string;

  /** Requisitos de cuidado base */
  readonly careRequirements: CareRequirements;

  /** Climas con los que es compatible (ej: "Mediterráneo", "Tropical", "Árido") */
  readonly climateCompatibility: string[];

  /** Consejos de cuidado */
  readonly tips: string[];

  /** Id del usuario que propuso la especie (undefined si es del sistema) */
  readonly createdBy?: string;

  /** Si true, la especie es visible para todos los usuarios */
  readonly isPublic: boolean;

  /** Indica si la especie requiere poda anual */
  readonly requiresPruning?: boolean;

  /** Meses recomendados de poda (1 = enero, 12 = diciembre). Solo aplica si requiresPruning es true */
  readonly pruningMonths?: number[];

  /** Indica si la especie produce frutos o cosecha */
  readonly produceFruit?: boolean;

  /** Meses del año en los que se puede cosechar (1 = enero, 12 = diciembre). Solo aplica si produceFruit es true */
  readonly harvestMonths?: number[];

  /** Ajuste estacional de la frecuencia de riego (opcional). */
  readonly seasonalWateringAdjustment?: SeasonalWateringAdjustment;

  /** Precipitación mínima en mm para considerar la planta regada por lluvia (opcional). Default efectivo: 5mm. */
  readonly minRainfallMm?: number;

  /** Cantidad de agua en litros que necesita la planta en cada riego (opcional, informativo). */
  readonly waterLitersPerWatering?: number;

  /** Historial de cambios realizados por admins */
  readonly auditHistory: AuditEntry[];

  /** Fecha de creación */
  readonly createdAt: Date;

  /** Fecha de última modificación */
  readonly updatedAt: Date;

  /** Fecha de borrado lógico */
  readonly deletedAt?: Date | null;

  constructor(params: {
    id: string;
    name: string;
    scientificName: string;
    image?: string;
    careRequirements: CareRequirements;
    climateCompatibility: string[];
    tips: string[];
    createdBy?: string;
    isPublic: boolean;
    requiresPruning?: boolean;
    pruningMonths?: number[];
    produceFruit?: boolean;
    harvestMonths?: number[];
    seasonalWateringAdjustment?: SeasonalWateringAdjustment;
    minRainfallMm?: number;
    waterLitersPerWatering?: number;
    auditHistory: AuditEntry[];
    createdAt: Date;
    updatedAt: Date;
    deletedAt?: Date | null;
  }) {
    this.id = params.id;
    this.name = params.name;
    this.scientificName = params.scientificName;
    this.image = params.image;
    this.careRequirements = params.careRequirements;
    this.climateCompatibility = params.climateCompatibility;
    this.tips = params.tips;
    this.createdBy = params.createdBy;
    this.isPublic = params.isPublic;
    this.requiresPruning = params.requiresPruning;
    this.pruningMonths = params.pruningMonths;
    this.produceFruit = params.produceFruit;
    this.harvestMonths = params.harvestMonths;
    this.seasonalWateringAdjustment = params.seasonalWateringAdjustment;
    this.minRainfallMm = params.minRainfallMm;
    this.waterLitersPerWatering = params.waterLitersPerWatering;
    this.auditHistory = params.auditHistory;
    this.createdAt = params.createdAt;
    this.updatedAt = params.updatedAt;
    this.deletedAt = params.deletedAt;
  }

  /**
   * Compara esta especie con otra y devuelve los campos que difieren.
   * Útil para el panel de revisión de propuestas de nuevas especies.
   *
   * @param other — Especie a comparar.
   * @returns Objeto con los campos que tienen valores distintos.
   */
  diffWith(other: PlantSpecies): Partial<Record<keyof PlantSpecies, { current: unknown; proposed: unknown }>> {
    const diff: Partial<Record<keyof PlantSpecies, { current: unknown; proposed: unknown }>> = {};

    const fields: Array<keyof PlantSpecies> = [
      'name', 'scientificName', 'image', 'careRequirements',
      'climateCompatibility', 'tips', 'isPublic',
    ];

    for (const field of fields) {
      const a = JSON.stringify(this[field]);
      const b = JSON.stringify(other[field]);
      if (a !== b) {
        diff[field] = { current: this[field], proposed: other[field] };
      }
    }

    return diff;
  }

  /**
   * Indica si la especie es una propuesta pendiente de aprobación.
   */
  get isPendingApproval(): boolean {
    return !this.isPublic && !!this.createdBy;
  }
}
