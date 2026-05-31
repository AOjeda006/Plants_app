/**
 * @file IGetMessagesUseCase.ts
 * @description Interfaz del caso de uso para obtener mensajes de una conversación.
 * @module Chat
 * @layer Domain
 */

import type { MessageResponseDTO } from '../../../dtos/chat/message-response.dto.js';

/**
 * Contrato del use case GetConversationMessages.
 * Verifica que el usuario es participante antes de devolver los mensajes.
 */
export interface IGetMessagesUseCase {
  /**
   * Ejecuta el caso de uso.
   *
   * @param conversationId — ID de la conversación.
   * @param userId — ID del usuario solicitante (para verificar participación).
   * @param page — Número de página (base 1). Por defecto 1.
   * @param limit — Elementos por página. Por defecto 30.
   * @returns Lista paginada de MessageResponseDTOs ordenada por fecha descendente.
   * @throws {NotFoundException} Si la conversación no existe.
   * @throws {ForbiddenException} Si el usuario no es participante.
   */
  execute(conversationId: string, userId: string, page?: number, limit?: number): Promise<MessageResponseDTO[]>;
}
