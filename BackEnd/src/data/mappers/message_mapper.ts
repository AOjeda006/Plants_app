/**
 * @file message_mapper.ts
 * @description Implementación del mapper de mensajes de chat.
 * Convierte entre MessageDocument (MongoDB), Message (dominio) y MessageResponseDTO (presentación).
 * @module Chat
 * @layer Data
 *
 * @implements {IMessageMapper}
 * @injectable
 */

import { injectable } from 'inversify';
import { ObjectId } from 'mongodb';
import type { IMessageMapper } from '../IMappers/IMessageMapper.js';
import { Message, ContentMeta } from '../../domain/entities/Message.js';
import type { MessageDocument } from '../datasources/mongodb/models/MessageModel.js';
import type { MessageResponseDTO } from '../../domain/dtos/chat/message-response.dto.js';

/**
 * Mapper de mensajes de chat.
 *
 * @implements {IMessageMapper}
 * @injectable
 */
@injectable()
export class MessageMapper implements IMessageMapper {

  /**
   * Convierte un documento MongoDB a entidad Message.
   *
   * @param doc — Documento de la colección 'messages'.
   * @returns Entidad Message.
   */
  toEntity(doc: MessageDocument): Message {
    return new Message({
      id:             doc._id.toHexString(),
      conversationId: doc.conversationId.toHexString(),
      senderId:       doc.senderId.toHexString(),
      receiverId:     doc.receiverId?.toHexString(),
      text:           doc.text,
      contentMeta:    doc.contentMeta,
      status:         doc.status,
      tempId:         doc.tempId,
      createdAt:      doc.createdAt,
      updatedAt:      doc.updatedAt,
    });
  }

  /**
   * Construye un documento MongoDB para insertar un nuevo mensaje (sin _id).
   * El estado inicial es siempre 'sent' (el servidor ya ha recibido el mensaje).
   *
   * @param conversationId — ID de la conversación.
   * @param senderId — ID del emisor.
   * @param receiverId — ID del receptor.
   * @param text — Texto del mensaje.
   * @param contentMeta — Metadatos de contenido multimedia.
   * @param tempId — ID temporal del cliente.
   * @returns Documento parcial para insertar en MongoDB.
   */
  toDocument(
    conversationId: string,
    senderId: string,
    receiverId: string,
    text?: string,
    contentMeta?: ContentMeta,
    tempId?: string,
  ): Omit<MessageDocument, '_id'> {
    const now = new Date();
    return {
      conversationId: new ObjectId(conversationId),
      senderId:       new ObjectId(senderId),
      receiverId:     receiverId ? new ObjectId(receiverId) : undefined,
      text,
      contentMeta,
      status:         'sent',
      tempId,
      createdAt:      now,
      updatedAt:      now,
    };
  }

  /**
   * Convierte una entidad Message al DTO de respuesta HTTP, enriquecido con el nombre del emisor.
   *
   * @param entity — Entidad Message.
   * @param senderName — Nombre del emisor.
   * @returns MessageResponseDTO serializable.
   */
  toResponseDTO(entity: Message, senderName: string): MessageResponseDTO {
    return {
      id:             entity.id,
      conversationId: entity.conversationId,
      senderId:       entity.senderId,
      senderName,
      text:           entity.text,
      contentMeta:    entity.contentMeta,
      status:         entity.status,
      tempId:         entity.tempId,
      createdAt:      entity.createdAt.toISOString(),
    };
  }
}
