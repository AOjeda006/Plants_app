/**
 * @file IGetUserNotificationsUseCase.ts
 * @description Interfaz del caso de uso para obtener las notificaciones in-app del usuario.
 * @module Reminders
 * @layer Domain
 */

import type { NotificationResponseDTO } from '../../../dtos/notifications/notification-response.dto.js';

export interface IGetUserNotificationsUseCase {
  /**
   * Devuelve las notificaciones del usuario autenticado.
   *
   * @param userId — Id del usuario.
   * @returns Lista de NotificationResponseDTO ordenada por fecha descendente.
   */
  execute(userId: string): Promise<NotificationResponseDTO[]>;
}
