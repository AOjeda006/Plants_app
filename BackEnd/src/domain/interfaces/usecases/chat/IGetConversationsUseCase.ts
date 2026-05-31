/**
 * @file IGetConversationsUseCase.ts
 * @description Interfaz del caso de uso para obtener las conversaciones del usuario.
 * @module Chat
 * @layer Domain
 */

import type { ConversationResponseDTO } from '../../../dtos/chat/conversation-response.dto.js';

/**
 * Contrato del use case GetUserConversations.
 * Devuelve todas las conversaciones activas del usuario, enriquecidas con
 * datos del otro participante, último mensaje y contador de no leídos.
 */
export interface IGetConversationsUseCase {
  /**
   * Ejecuta el caso de uso.
   *
   * @param userId — ID del usuario autenticado.
   * @returns Lista de ConversationResponseDTOs ordenada por actividad reciente.
   */
  execute(userId: string): Promise<ConversationResponseDTO[]>;
}
