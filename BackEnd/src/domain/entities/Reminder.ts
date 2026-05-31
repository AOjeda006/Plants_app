/**
 * @file Reminder.ts
 * @description Entidad de dominio que representa un recordatorio de cuidado de planta.
 * Los recordatorios de tipo watering/pruning se reprograman automáticamente tras procesarse.
 * Los de tipo custom son de uso único y se marcan como completados tras el primer envío.
 * @module Reminders
 * @layer Domain
 */

/** Tipo de recordatorio */
export type ReminderType = 'watering' | 'pruning' | 'custom';

/**
 * Entidad Reminder.
 * Representa una tarea programada de cuidado asociada a una planta y usuario.
 */
export class Reminder {
  readonly id:            string;
  /** Id de la planta a la que pertenece este recordatorio */
  readonly plantId:       string;
  /** Id del usuario propietario */
  readonly userId:        string;
  /** Tipo de cuidado: riego, poda o personalizado */
  readonly type:          ReminderType;
  /** Fecha/hora en que el recordatorio debe procesarse */
  readonly scheduledDate: Date;
  /** Mensaje de la notificación push */
  readonly message:       string;
  /** true si se ha completado definitivamente (reminders de tipo custom) */
  readonly isCompleted:   boolean;
  /** true si se ha suspendido temporalmente (ej.: por lluvia prevista) */
  readonly suspended:     boolean;
  /** Número de veces que se ha intentado enviar la notificación */
  readonly attempts:      number;
  readonly createdAt:     Date;

  constructor(params: {
    id:            string;
    plantId:       string;
    userId:        string;
    type:          ReminderType;
    scheduledDate: Date;
    message:       string;
    isCompleted:   boolean;
    suspended:     boolean;
    attempts:      number;
    createdAt:     Date;
  }) {
    this.id            = params.id;
    this.plantId       = params.plantId;
    this.userId        = params.userId;
    this.type          = params.type;
    this.scheduledDate = params.scheduledDate;
    this.message       = params.message;
    this.isCompleted   = params.isCompleted;
    this.suspended     = params.suspended;
    this.attempts      = params.attempts;
    this.createdAt     = params.createdAt;
  }

  /**
   * true si el recordatorio está pendiente de procesar (vencido, no completado, no suspendido).
   */
  get isPending(): boolean {
    return !this.isCompleted && !this.suspended && this.scheduledDate <= new Date();
  }
}
