/**
 * @file MarkReminderCompletedUseCase.ts
 * @description Caso de uso para marcar un recordatorio como completado.
 * Valida que el recordatorio pertenece al usuario antes de actualizar.
 * @module Reminders
 * @layer Domain
 *
 * @implements {IMarkReminderCompletedUseCase}
 * @injectable
 * @dependencies IReminderRepository
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { IMarkReminderCompletedUseCase } from '../../interfaces/usecases/reminders/IMarkReminderCompletedUseCase.js';
import type { IReminderRepository } from '../../repositories/IReminderRepository.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';
import { ForbiddenException } from '../../../core/exceptions/ForbiddenException.js';

/**
 * Marca un recordatorio como completado, validando la propiedad del usuario.
 *
 * @implements {IMarkReminderCompletedUseCase}
 * @injectable
 * @dependencies IReminderRepository
 */
@injectable()
export class MarkReminderCompletedUseCase implements IMarkReminderCompletedUseCase {
  constructor(
    @inject(TYPES.IReminderRepository) private readonly reminderRepo: IReminderRepository,
  ) {}

  /**
   * @param reminderId — Id del recordatorio a completar.
   * @param userId — Id del usuario propietario (para validación de acceso).
   * @throws {NotFoundException} Si el recordatorio no existe.
   * @throws {ForbiddenException} Si el recordatorio no pertenece al usuario.
   */
  async execute(reminderId: string, userId: string): Promise<void> {
    const reminders = await this.reminderRepo.findByUserId(userId);
    const reminder  = reminders.find((r) => r.id === reminderId);

    if (!reminder) {
      // Distinguir entre "no existe" y "no pertenece" requeriría findById;
      // TFG: simplificamos lanzando NotFoundException si no aparece en la lista del usuario
      throw new NotFoundException('Reminder', reminderId);
    }

    if (reminder.userId !== userId) {
      throw new ForbiddenException('No tienes permiso para completar este recordatorio');
    }

    await this.reminderRepo.updateStatus(reminderId, { isCompleted: true });
  }
}
