/**
 * @file IMarkReminderCompletedUseCase.ts
 * @description Interfaz del caso de uso para marcar un recordatorio como completado.
 * @module Reminders
 * @layer Domain
 */
export interface IMarkReminderCompletedUseCase {
  execute(reminderId: string, userId: string): Promise<void>;
}
