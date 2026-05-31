/**
 * @file ISendMessageUseCase.ts
 * @description Interfaz del caso de uso para enviar un mensaje en una conversación.
 * @module Chat
 * @layer Domain
 */

import type { SendMessageRequestDto } from '../../../dtos/chat/send-message-request.dto.js';
import type { MessageResponseDTO } from '../../../dtos/chat/message-response.dto.js';

/**
 * Contrato del use case SendMessage.
 * Persiste el mensaje y emite el evento Socket.IO al destinatario.
 */
export interface ISendMessageUseCase {
  /**
   * Ejecuta el caso de uso.
   *
   * @param conversationId — ID de la conversación donde se envía el mensaje.
   * @param senderId — ID del usuario emisor.
   * @param dto — Datos del mensaje (texto, contentMeta, tempId).
   * @returns MessageResponseDTO del mensaje persistido.
   * @throws {NotFoundException} Si la conversación no existe.
   * @throws {ForbiddenException} Si el emisor no es participante.
   */
  execute(conversationId: string, senderId: string, dto: SendMessageRequestDto): Promise<MessageResponseDTO>;
}
