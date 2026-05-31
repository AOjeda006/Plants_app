/**
 * @file CommentModel.ts
 * @description Define el nombre de la colección y el tipo del documento MongoDB para Comment.
 * SIN lógica de mapeo — la transformación entre documento y entidad es responsabilidad
 * exclusiva de los mappers (data/mappers/comment_mapper.ts).
 * @module Community
 * @layer Data
 */

import { ObjectId } from 'mongodb';

/** Nombre de la colección en MongoDB */
export const COMMENT_COLLECTION = 'comments';

/**
 * Tipo del documento MongoDB tal como se almacena en la base de datos.
 * Los campos usan ObjectId y Date nativos de MongoDB.
 * NO contiene métodos de negocio ni de mapeo.
 */
export interface CommentDocument {
  _id: ObjectId;
  postId: ObjectId;
  userId: ObjectId;
  content: string;
  createdAt: Date;
  deletedAt?: Date | null;
}
