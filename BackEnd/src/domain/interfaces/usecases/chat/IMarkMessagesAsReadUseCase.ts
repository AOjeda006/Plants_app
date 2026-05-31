/**
 * @file IMarkMessagesAsReadUseCase.ts
 * @description Interfaz del caso de uso para marcar mensajes como leídos.
 * @module Chat
 * @layer Domain
 */
export interface IMarkMessagesAsReadUseCase {
  execute(conversationId: string, userId: string): Promise<void>;
}
