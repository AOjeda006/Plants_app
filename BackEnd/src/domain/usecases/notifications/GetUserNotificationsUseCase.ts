/**
 * @file GetUserNotificationsUseCase.ts
 * @description Caso de uso para obtener las notificaciones in-app del usuario autenticado.
 * @module Reminders
 * @layer Domain
 *
 * @implements {IGetUserNotificationsUseCase}
 * @injectable
 * @dependencies INotificationRepository, INotificationMapper
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { IGetUserNotificationsUseCase } from '../../interfaces/usecases/notifications/IGetUserNotificationsUseCase.js';
import type { INotificationRepository } from '../../repositories/INotificationRepository.js';
import type { INotificationMapper } from '../../../data/IMappers/INotificationMapper.js';
import type { NotificationResponseDTO } from '../../dtos/notifications/notification-response.dto.js';

/**
 * Devuelve las notificaciones in-app del usuario ordenadas por fecha descendente.
 *
 * @implements {IGetUserNotificationsUseCase}
 * @injectable
 * @dependencies INotificationRepository, INotificationMapper
 */
@injectable()
export class GetUserNotificationsUseCase implements IGetUserNotificationsUseCase {
  constructor(
    @inject(TYPES.INotificationRepository) private readonly notifRepo: INotificationRepository,
    @inject(TYPES.INotificationMapper)     private readonly mapper: INotificationMapper,
  ) {}

  /**
   * Ejecuta la consulta de notificaciones del usuario.
   *
   * @param userId — Id del usuario autenticado.
   * @returns Lista de NotificationResponseDTO.
   */
  async execute(userId: string): Promise<NotificationResponseDTO[]> {
    const notifications = await this.notifRepo.findByUserId(userId);
    return notifications.map((n) => this.mapper.toResponseDTO(n));
  }
}
