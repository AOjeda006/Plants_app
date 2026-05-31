/**
 * @file IMarkNotificationsReadUseCase.ts
 * @description Interfaz del caso de uso para marcar todas las notificaciones del usuario como leídas.
 * @module Reminders
 * @layer Domain
 */

export interface IMarkNotificationsReadUseCase {
  /**
   * Marca notificaciones del usuario como leídas.
   * Si se proporcionan ids, solo marca esas; si no, marca todas.
   *
   * @param userId — Id del usuario autenticado.
   * @param ids — Ids de notificaciones específicas (opcional).
   */
  execute(userId: string, ids?: string[]): Promise<void>;
}
