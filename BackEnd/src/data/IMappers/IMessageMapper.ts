/**
 * @file IMessageMapper.ts
 * @description Interfaz del mapper de mensajes de chat.
 * Define el contrato de transformación entre documento MongoDB, entidad de dominio y DTO de respuesta.
 * @module Chat
 * @layer Data
 */

import type { Message, ContentMeta } from '../../domain/entities/Message.js';
import type { MessageDocument } from '../datasources/mongodb/models/MessageModel.js';
import type { MessageResponseDTO } from '../../domain/dtos/chat/message-response.dto.js';

/**
 * Contrato del mapper de mensajes.
 * Los repositorios dependen de esta interfaz, no de la implementación concreta.
 */
export interface IMessageMapper {
  /**
   * Convierte un documento MongoDB a entidad Message de dominio.
   *
   * @param doc — Documento de la colección 'messages'.
   * @returns Entidad Message.
   */
  toEntity(doc: MessageDocument): Message;

  /**
   * Construye un documento MongoDB para insertar un nuevo mensaje (sin _id).
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
  ): Omit<MessageDocument, '_id'>;

  /**
   * Convierte una entidad Message al DTO de respuesta HTTP, enriquecido con el nombre del emisor.
   *
   * @param entity — Entidad Message.
   * @param senderName — Nombre del emisor del mensaje.
   * @returns MessageResponseDTO serializable.
   */
  toResponseDTO(entity: Message, senderName: string): MessageResponseDTO;
}
