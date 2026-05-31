/**
 * @file ConversationModel.ts
 * @description Define el nombre de la colección y el tipo del documento MongoDB para Conversation.
 * SIN lógica de mapeo — la transformación entre documento y entidad es responsabilidad
 * exclusiva de los mappers (data/mappers/conversation_mapper.ts).
 * @module Chat
 * @layer Data
 */

import { ObjectId } from 'mongodb';

/** Nombre de la colección en MongoDB */
export const CONVERSATION_COLLECTION = 'conversations';

/**
 * Tipo del documento MongoDB tal como se almacena en la base de datos.
 * NO contiene métodos de negocio ni de mapeo.
 */
export interface ConversationDocument {
  _id: ObjectId;
  participants: ObjectId[];
  lastMessageAt?: Date;
  createdAt: Date;
  updatedAt: Date;
  deletedAt?: Date | null;
}
