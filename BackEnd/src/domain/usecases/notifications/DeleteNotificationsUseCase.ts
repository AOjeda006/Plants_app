/**
 * @file DeleteNotificationsUseCase.ts
 * @description Caso de uso para eliminar todas las notificaciones del usuario autenticado.
 * @module Reminders
 * @layer Domain
 *
 * @implements {IDeleteNotificationsUseCase}
 * @injectable
 * @dependencies INotificationRepository
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { IDeleteNotificationsUseCase } from '../../interfaces/usecases/notifications/IDeleteNotificationsUseCase.js';
import type { INotificationRepository } from '../../repositories/INotificationRepository.js';

/**
 * Elimina todas las notificaciones del usuario.
 *
 * @implements {IDeleteNotificationsUseCase}
 * @injectable
 * @dependencies INotificationRepository
 */
@injectable()
export class DeleteNotificationsUseCase implements IDeleteNotificationsUseCase {
  constructor(
    @inject(TYPES.INotificationRepository) private readonly notifRepo: INotificationRepository,
  ) {}

  /**
   * Elimina notificaciones del usuario autenticado.
   * Si se proporcionan ids, solo elimina esas; si no, elimina todas.
   *
   * @param userId — Id del usuario autenticado.
   * @param ids — Ids de notificaciones específicas (opcional).
   */
  async execute(userId: string, ids?: string[]): Promise<void> {
    if (ids && ids.length > 0) {
      await this.notifRepo.deleteByIds(userId, ids);
    } else {
      await this.notifRepo.deleteAllByUserId(userId);
    }
  }
}
