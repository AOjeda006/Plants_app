/**
 * @file conversation-response.dto.ts
 * @description DTO de respuesta HTTP para una conversación de chat.
 * Incluye datos del otro participante, último mensaje y contador de no leídos.
 * @module Chat
 * @layer Domain
 */

import type { MessageResponseDTO } from './message-response.dto.js';

/**
 * Datos básicos del participante expuestos en la respuesta de conversación.
 */
export interface ParticipantSummaryDTO {
  id: string;
  name: string;
  photo?: string;
}

/**
 * DTO de respuesta para una conversación, enriquecida con datos contextuales.
 */
export interface ConversationResponseDTO {
  id: string;
  participant: ParticipantSummaryDTO;
  lastMessage?: MessageResponseDTO;
  lastMessageAt?: string;
  unreadCount: number;
  createdAt: string;
  /** true cuando el otro participante ha eliminado su cuenta. La conversación es de solo lectura. */
  isParticipantDeleted?: boolean;
}
