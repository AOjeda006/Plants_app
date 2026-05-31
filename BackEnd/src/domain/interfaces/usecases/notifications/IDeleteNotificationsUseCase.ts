/**
 * @file IDeleteNotificationsUseCase.ts
 * @description Interfaz del caso de uso para eliminar todas las notificaciones del usuario.
 * @module Reminders
 * @layer Domain
 */

export interface IDeleteNotificationsUseCase {
  /**
   * Elimina notificaciones del usuario autenticado.
   * Si se proporcionan ids, solo elimina esas; si no, elimina todas.
   *
   * @param userId — Id del usuario autenticado.
   * @param ids — Ids de notificaciones específicas (opcional).
   */
  execute(userId: string, ids?: string[]): Promise<void>;
}
