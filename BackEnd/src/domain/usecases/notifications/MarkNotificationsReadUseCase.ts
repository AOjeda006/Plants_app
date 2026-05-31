/**
 * @file MarkNotificationsReadUseCase.ts
 * @description Caso de uso para marcar todas las notificaciones del usuario como leídas.
 * @module Reminders
 * @layer Domain
 *
 * @implements {IMarkNotificationsReadUseCase}
 * @injectable
 * @dependencies INotificationRepository
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { IMarkNotificationsReadUseCase } from '../../interfaces/usecases/notifications/IMarkNotificationsReadUseCase.js';
import type { INotificationRepository } from '../../repositories/INotificationRepository.js';

/**
 * Marca todas las notificaciones del usuario como leídas (isRead=true).
 *
 * @implements {IMarkNotificationsReadUseCase}
 * @injectable
 * @dependencies INotificationRepository
 */
@injectable()
export class MarkNotificationsReadUseCase implements IMarkNotificationsReadUseCase {
  constructor(
    @inject(TYPES.INotificationRepository) private readonly notifRepo: INotificationRepository,
  ) {}

  /**
   * Marca notificaciones como leídas.
   * Si se proporcionan ids, solo marca esas; si no, marca todas.
   *
   * @param userId — Id del usuario autenticado.
   * @param ids — Ids de notificaciones específicas (opcional).
   */
  async execute(userId: string, ids?: string[]): Promise<void> {
    if (ids && ids.length > 0) {
      await this.notifRepo.markReadByIds(userId, ids);
    } else {
      await this.notifRepo.markAllReadByUserId(userId);
    }
  }
}
