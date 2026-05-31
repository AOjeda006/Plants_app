/**
 * @file ICreateConversationUseCase.ts
 * @description Interfaz del caso de uso para obtener o crear una conversación entre dos usuarios.
 * Implementa la semántica "get or create": si ya existe la conversación, la devuelve.
 * Registrado en el container con el símbolo TYPES.IGetOrCreateConversationUseCase.
 * @module Chat
 * @layer Domain
 */

import type { ConversationResponseDTO } from '../../../dtos/chat/conversation-response.dto.js';

/**
 * Contrato del use case GetOrCreateConversation.
 * Garantiza que solo exista una conversación entre el par de usuarios.
 */
export interface ICreateConversationUseCase {
  /**
   * Ejecuta el caso de uso.
   *
   * @param participantId — ID del otro usuario con quien iniciar la conversación.
   * @param userId — ID del usuario autenticado.
   * @returns ConversationResponseDTO de la conversación (existente o nueva).
   * @throws {NotFoundException} Si el otro participante no existe.
   */
  execute(participantId: string, userId: string): Promise<ConversationResponseDTO>;
}
