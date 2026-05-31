/**
 * @file GetUserRemindersUseCase.ts
 * @description Caso de uso para obtener los recordatorios activos de un usuario.
 * @module Reminders
 * @layer Domain
 *
 * @implements {IGetUserRemindersUseCase}
 * @injectable
 * @dependencies IReminderRepository, IReminderMapper
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { IGetUserRemindersUseCase } from '../../interfaces/usecases/reminders/IGetUserRemindersUseCase.js';
import type { IReminderRepository } from '../../repositories/IReminderRepository.js';
import type { IReminderMapper } from '../../../data/IMappers/IReminderMapper.js';
import type { ReminderResponseDTO } from '../../dtos/reminders/reminder-response.dto.js';

/**
 * Obtiene los recordatorios activos (no completados) del usuario.
 *
 * @implements {IGetUserRemindersUseCase}
 * @injectable
 * @dependencies IReminderRepository, IReminderMapper
 */
@injectable()
export class GetUserRemindersUseCase implements IGetUserRemindersUseCase {
  constructor(
    @inject(TYPES.IReminderRepository) private readonly reminderRepo: IReminderRepository,
    @inject(TYPES.IReminderMapper)     private readonly mapper: IReminderMapper,
  ) {}

  /**
   * @param userId — Id del usuario autenticado.
   * @returns Lista de ReminderResponseDTO ordenados por scheduledDate asc.
   */
  async execute(userId: string): Promise<ReminderResponseDTO[]> {
    const reminders = await this.reminderRepo.findByUserId(userId);
    return reminders.map((r) => this.mapper.toResponseDTO(r));
  }
}
