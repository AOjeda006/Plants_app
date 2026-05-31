/**
 * @file Plant.ts
 * @description Entidad de dominio que representa una planta del usuario.
 * Contiene lógica de negocio pura para cálculo de próximo riego y ajustes de override.
 * @module Plants
 * @layer Domain
 */

/**
 * Ubicación física de la planta.
 */
export type PlantLocation = 'Interior' | 'Exterior';

/**
 * Necesidad de luz de la planta.
 */
export type LightNeed = 'Low' | 'Medium' | 'High';

/**
 * Estado de un reset de nextWatering provocado por una previsión de lluvia.
 * Se rellena cuando _processWeather aplica un reset por previsión, y se
 * consume al día siguiente en _processYesterdayRain:
 *   - Si la lluvia se confirmó (history >= minRainfallMm) → limpiar y notificar.
 *   - Si NO se confirmó → restaurar previousNextWatering, limpiar y notificar.
 */
export interface PendingRainAdjustment {
  /** Fecha en la que se aplicó el reset por previsión */
  resetAt: Date;
  /** Valor de `nextWatering` ANTES del reset (null si la planta no tenía) */
  previousNextWatering: Date | null;
  /** Probabilidad/precipitación esperada que motivó el reset (informativo) */
  expectedMm: number;
  /** Coordenadas usadas para consultar history al día siguiente */
  locationLat: number;
  locationLon: number;
}

/**
 * Override puntual para alterar la frecuencia de riego en un rango de fechas.
 * Permite que condiciones climáticas o del usuario ajusten el comportamiento sin
 * modificar la configuración base de la planta.
 */
export interface PlantOverride {
  /** Fecha de inicio del override (inclusive) */
  fromDate: Date;
  /** Fecha de fin del override (inclusive) */
  toDate: Date;
  /** Frecuencia de riego ajustada en días */
  wateringFrequencyDays: number;
  /** Motivo del override (ej: "Período de lluvias", "Vacaciones") */
  reason?: string;
}

/**
 * Entidad de dominio Plant.
 * Representa el estado válido de una planta dentro del sistema.
 * Los mappers convierten entre esta entidad y los documentos de MongoDB.
 */
export class Plant {
  /** Identificador único (ObjectId de MongoDB serializado como string) */
  readonly id: string;

  /** Id del usuario propietario */
  readonly userId: string;

  /** Nombre personalizado de la planta */
  readonly name: string;

  /** Id de la especie asociada (opcional) */
  readonly speciesId?: string;

  /** URL de la foto en Cloudinary */
  readonly photo?: string;

  /** Ubicación de la planta */
  readonly location: PlantLocation;

  /** Ciudad/municipio donde se encuentra la planta (catálogo SPAIN_LOCATIONS) */
  readonly plantLocation?: string;

  /** Latitud geográfica de la ubicación de la planta */
  readonly plantLocationLat?: number;

  /** Longitud geográfica de la ubicación de la planta */
  readonly plantLocationLon?: number;

  /** Frecuencia base de riego en días */
  readonly wateringFrequency: number;

  /** Necesidad de luz */
  readonly lightNeed: LightNeed;

  /** Frecuencia de poda en días (opcional) */
  readonly pruningFrequency?: number;

  /** Notas libres del usuario */
  readonly notes?: string;

  /** Próxima fecha de riego calculada */
  readonly nextWatering?: Date;

  /** Próxima fecha de poda calculada */
  readonly nextPruning?: Date;

  /** Si true, el cálculo de riego considera datos meteorológicos */
  readonly considerWeatherForWatering: boolean;

  /** Overrides puntuales de frecuencia de riego */
  readonly overrides?: PlantOverride[];

  /** Reset de nextWatering pendiente de confirmación por history */
  readonly pendingRainAdjustment?: PendingRainAdjustment;

  /** Fecha de creación */
  readonly createdAt: Date;

  /** Fecha de última modificación */
  readonly updatedAt: Date;

  /** Fecha de borrado lógico. Si está definida, la planta está eliminada */
  readonly deletedAt?: Date | null;

  constructor(params: {
    id: string;
    userId: string;
    name: string;
    speciesId?: string;
    photo?: string;
    location: PlantLocation;
    plantLocation?: string;
    plantLocationLat?: number;
    plantLocationLon?: number;
    wateringFrequency: number;
    lightNeed: LightNeed;
    pruningFrequency?: number;
    notes?: string;
    nextWatering?: Date;
    nextPruning?: Date;
    considerWeatherForWatering: boolean;
    overrides?: PlantOverride[];
    pendingRainAdjustment?: PendingRainAdjustment;
    createdAt: Date;
    updatedAt: Date;
    deletedAt?: Date | null;
  }) {
    this.id = params.id;
    this.userId = params.userId;
    this.name = params.name;
    this.speciesId = params.speciesId;
    this.photo            = params.photo;
    this.location         = params.location;
    this.plantLocation    = params.plantLocation;
    this.plantLocationLat = params.plantLocationLat;
    this.plantLocationLon = params.plantLocationLon;
    this.wateringFrequency = params.wateringFrequency;
    this.lightNeed = params.lightNeed;
    this.pruningFrequency = params.pruningFrequency;
    this.notes = params.notes;
    this.nextWatering = params.nextWatering;
    this.nextPruning = params.nextPruning;
    this.considerWeatherForWatering = params.considerWeatherForWatering;
    this.overrides = params.overrides;
    this.pendingRainAdjustment = params.pendingRainAdjustment;
    this.createdAt = params.createdAt;
    this.updatedAt = params.updatedAt;
    this.deletedAt = params.deletedAt;
  }

  /**
   * Calcula la próxima fecha de riego a partir de una fecha de referencia.
   * Si hay un override activo en esa fecha, usa su frecuencia ajustada.
   *
   * @param now — Fecha de referencia (por defecto: ahora).
   * @returns Fecha del próximo riego.
   */
  calculateNextWatering(now: Date = new Date()): Date {
    const activeOverride = this.overrides?.find(
      (o) => o.fromDate <= now && o.toDate >= now,
    );

    const frequencyDays = activeOverride
      ? activeOverride.wateringFrequencyDays
      : this.wateringFrequency;

    const next = new Date(now);
    next.setDate(next.getDate() + frequencyDays);
    return next;
  }

  /**
   * Calcula la próxima fecha de poda a partir de una fecha de referencia.
   * Devuelve undefined si la planta no tiene frecuencia de poda configurada.
   *
   * @param now — Fecha de referencia (por defecto: ahora).
   * @returns Fecha del próximo poda o undefined.
   */
  calculateNextPruning(now: Date = new Date()): Date | undefined {
    if (!this.pruningFrequency) return undefined;
    const next = new Date(now);
    next.setDate(next.getDate() + this.pruningFrequency);
    return next;
  }

  /**
   * Determina si hay un override activo en una fecha dada.
   * Útil para que el ReminderService ajuste la frecuencia antes de enviar recordatorios.
   *
   * @param date — Fecha a comprobar.
   * @returns El override activo o undefined.
   */
  getActiveOverride(date: Date = new Date()): PlantOverride | undefined {
    return this.overrides?.find((o) => o.fromDate <= date && o.toDate >= date);
  }

  /**
   * Indica si la planta necesita riego hoy (nextWatering <= now).
   */
  get needsWateringToday(): boolean {
    if (!this.nextWatering) return false;
    return this.nextWatering <= new Date();
  }
}
