/**
 * @file Notification.ts
 * @description Entidad de dominio que representa una notificación in-app generada
 * por el cron de recordatorios. Persiste en MongoDB y es consumida por el frontend.
 * @module Reminders
 * @layer Domain
 */

/** Tipos de notificación soportados (aligned con ReminderType + pruning + harvest + weather + admin) */
export type NotificationType = 'watering' | 'pruning' | 'fertilizing' | 'repotting' | 'custom' | 'harvest' | 'weather_rain' | 'weather_storm' | 'admin_warning' | 'info';

/**
 * Entidad Notification.
 * Representa una notificación generada automáticamente cuando un recordatorio se procesa.
 */
export class Notification {
  readonly id:        string;
  /** Id del usuario destinatario */
  readonly userId:    string;
  /** Tipo de cuidado asociado */
  readonly type:      NotificationType;
  /** Mensaje legible de la notificación */
  readonly message:   string;
  /** Id del recordatorio que originó esta notificación (undefined para notificaciones de cosecha) */
  readonly reminderId?: string;
  /** Id de la planta asociada (undefined para notificaciones sin planta, ej. custom o admin) */
  readonly plantId?:  string;
  /** true si el usuario ya la ha visto / marcado como leída */
  readonly isRead:    boolean;
  readonly createdAt: Date;

  constructor(params: {
    id:         string;
    userId:     string;
    type:       NotificationType;
    message:    string;
    reminderId?: string;
    plantId?:   string;
    isRead:     boolean;
    createdAt:  Date;
  }) {
    this.id         = params.id;
    this.userId     = params.userId;
    this.type       = params.type;
    this.message    = params.message;
    this.reminderId = params.reminderId;
    this.plantId    = params.plantId;
    this.isRead     = params.isRead;
    this.createdAt  = params.createdAt;
  }
}
