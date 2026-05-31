/**
 * @file MessageModel.ts
 * @description Define el nombre de la colección y el tipo del documento MongoDB para Message.
 * SIN lógica de mapeo — la transformación entre documento y entidad es responsabilidad
 * exclusiva de los mappers (data/mappers/message_mapper.ts).
 * @module Chat
 * @layer Data
 */

import { ObjectId } from 'mongodb';
import type { ContentMeta, MessageStatus } from '../../../../domain/entities/Message.js';

/** Nombre de la colección en MongoDB */
export const MESSAGE_COLLECTION = 'messages';

/**
 * Tipo del documento MongoDB tal como se almacena en la base de datos.
 * NO contiene métodos de negocio ni de mapeo.
 */
export interface MessageDocument {
  _id: ObjectId;
  conversationId: ObjectId;
  senderId: ObjectId;
  receiverId?: ObjectId;
  text?: string;
  contentMeta?: ContentMeta;
  status: MessageStatus;
  tempId?: string;
  createdAt: Date;
  updatedAt: Date;
}
