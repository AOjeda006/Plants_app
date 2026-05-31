/**
 * @file ReminderHistory.ts
 * @description Entidad de dominio que representa el historial de ejecución de un recordatorio.
 * Cada entrada registra un intento de procesamiento del cron job.
 * La idempotencyKey previene procesamiento duplicado en caso de reintento del cron.
 * @module Reminders
 * @layer Domain
 */

/** Resultado del procesamiento del recordatorio */
export type ReminderResult = 'success' | 'skipped' | 'error';

/**
 * Entidad ReminderHistory.
 * Registro inmutable de un procesamiento de recordatorio.
 */
export class ReminderHistory {
  readonly id:             string;
  /** Id del recordatorio procesado */
  readonly reminderId:     string;
  /** Momento en que se procesó */
  readonly processedAt:    Date;
  /** Resultado del procesamiento */
  readonly result:         ReminderResult;
  /** Detalle adicional: razón de skip, mensaje de error, etc. */
  readonly details?:       string;
  /**
   * Clave de idempotencia para evitar procesar el mismo recordatorio
   * más de una vez por ejecución del cron (formato: reminderId_YYYY-MM-DD).
   */
  readonly idempotencyKey: string;

  constructor(params: {
    id:             string;
    reminderId:     string;
    processedAt:    Date;
    result:         ReminderResult;
    details?:       string;
    idempotencyKey: string;
  }) {
    this.id             = params.id;
    this.reminderId     = params.reminderId;
    this.processedAt    = params.processedAt;
    this.result         = params.result;
    this.details        = params.details;
    this.idempotencyKey = params.idempotencyKey;
  }
}
