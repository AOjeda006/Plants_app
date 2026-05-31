/**
 * @file IConversationMapper.ts
 * @description Interfaz del mapper de conversaciones de chat.
 * Define el contrato de transformación entre documento MongoDB, entidad de dominio y DTO de respuesta.
 * @module Chat
 * @layer Data
 */

import type { Conversation } from '../../domain/entities/Conversation.js';
import type { ConversationDocument } from '../datasources/mongodb/models/ConversationModel.js';
import type { ConversationResponseDTO, ParticipantSummaryDTO } from '../../domain/dtos/chat/conversation-response.dto.js';
import type { MessageResponseDTO } from '../../domain/dtos/chat/message-response.dto.js';

/**
 * Contrato del mapper de conversaciones.
 * Los repositorios dependen de esta interfaz, no de la implementación concreta.
 */
export interface IConversationMapper {
  /**
   * Convierte un documento MongoDB a entidad Conversation de dominio.
   *
   * @param doc — Documento de la colección 'conversations'.
   * @returns Entidad Conversation.
   */
  toEntity(doc: ConversationDocument): Conversation;

  /**
   * Construye un documento MongoDB para insertar una nueva conversación (sin _id).
   *
   * @param participantA — ID del primer participante.
   * @param participantB — ID del segundo participante.
   * @returns Documento parcial para insertar en MongoDB.
   */
  toDocument(participantA: string, participantB: string): Omit<ConversationDocument, '_id'>;

  /**
   * Convierte una entidad Conversation al DTO de respuesta HTTP.
   *
   * @param entity — Entidad Conversation.
   * @param participant — Datos del otro participante en la conversación.
   * @param lastMessage — Último mensaje de la conversación (opcional).
   * @param unreadCount — Número de mensajes no leídos para el usuario actual.
   * @returns ConversationResponseDTO serializable.
   */
  toResponseDTO(
    entity: Conversation,
    participant: ParticipantSummaryDTO,
    lastMessage?: MessageResponseDTO,
    unreadCount?: number,
  ): ConversationResponseDTO;
}
