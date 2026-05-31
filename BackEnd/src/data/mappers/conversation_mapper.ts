/**
 * @file conversation_mapper.ts
 * @description Implementación del mapper de conversaciones de chat.
 * Convierte entre ConversationDocument (MongoDB), Conversation (dominio) y ConversationResponseDTO (presentación).
 * @module Chat
 * @layer Data
 *
 * @implements {IConversationMapper}
 * @injectable
 */

import { injectable } from 'inversify';
import { ObjectId } from 'mongodb';
import type { IConversationMapper } from '../IMappers/IConversationMapper.js';
import { Conversation } from '../../domain/entities/Conversation.js';
import type { ConversationDocument } from '../datasources/mongodb/models/ConversationModel.js';
import type { ConversationResponseDTO, ParticipantSummaryDTO } from '../../domain/dtos/chat/conversation-response.dto.js';
import type { MessageResponseDTO } from '../../domain/dtos/chat/message-response.dto.js';

/**
 * Mapper de conversaciones de chat.
 *
 * @implements {IConversationMapper}
 * @injectable
 */
@injectable()
export class ConversationMapper implements IConversationMapper {

  /**
   * Convierte un documento MongoDB a entidad Conversation.
   *
   * @param doc — Documento de la colección 'conversations'.
   * @returns Entidad Conversation.
   */
  toEntity(doc: ConversationDocument): Conversation {
    return new Conversation({
      id:            doc._id.toHexString(),
      participants:  doc.participants.map(id => id.toHexString()),
      lastMessageAt: doc.lastMessageAt,
      createdAt:     doc.createdAt,
      updatedAt:     doc.updatedAt,
      deletedAt:     doc.deletedAt,
    });
  }

  /**
   * Construye un documento MongoDB para insertar una nueva conversación (sin _id).
   *
   * @param participantA — ID del primer participante.
   * @param participantB — ID del segundo participante.
   * @returns Documento parcial para insertar en MongoDB.
   */
  toDocument(participantA: string, participantB: string): Omit<ConversationDocument, '_id'> {
    const now = new Date();
    return {
      participants:  [new ObjectId(participantA), new ObjectId(participantB)],
      lastMessageAt: undefined,
      createdAt:     now,
      updatedAt:     now,
      deletedAt:     null,
    };
  }

  /**
   * Convierte una entidad Conversation al DTO de respuesta HTTP.
   *
   * @param entity — Entidad Conversation.
   * @param participant — Datos del otro participante.
   * @param lastMessage — Último mensaje de la conversación.
   * @param unreadCount — Número de mensajes no leídos.
   * @returns ConversationResponseDTO serializable.
   */
  toResponseDTO(
    entity: Conversation,
    participant: ParticipantSummaryDTO,
    lastMessage?: MessageResponseDTO,
    unreadCount = 0,
  ): ConversationResponseDTO {
    return {
      id:            entity.id,
      participant,
      lastMessage,
      lastMessageAt: entity.lastMessageAt?.toISOString(),
      unreadCount,
      createdAt:     entity.createdAt.toISOString(),
    };
  }
}
