/**
 * @file message-response.dto.ts
 * @description DTO de respuesta HTTP para un mensaje de chat.
 * Incluye el nombre del emisor enriquecido para evitar llamadas adicionales.
 * @module Chat
 * @layer Domain
 */

import type { ContentMeta } from '../../entities/Message.js';

/**
 * DTO de respuesta para un mensaje de chat.
 */
export interface MessageResponseDTO {
  id: string;
  conversationId: string;
  senderId: string;
  senderName: string;
  text?: string;
  contentMeta?: ContentMeta;
  status: 'pending' | 'sent' | 'delivered' | 'read';
  tempId?: string;
  createdAt: string;
}
