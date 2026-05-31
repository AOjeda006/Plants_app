/**
 * @file PostModel.ts
 * @description Define el nombre de la colección y el tipo del documento MongoDB para Post.
 * SIN lógica de mapeo — la transformación entre documento y entidad es responsabilidad
 * exclusiva de los mappers (data/mappers/post_mapper.ts).
 * @module Community
 * @layer Data
 */

import { ObjectId } from 'mongodb';

/** Nombre de la colección en MongoDB */
export const POST_COLLECTION = 'posts';

/**
 * Tipo del documento MongoDB tal como se almacena en la base de datos.
 * Los campos usan ObjectId y Date nativos de MongoDB.
 * NO contiene métodos de negocio ni de mapeo.
 */
export interface PostDocument {
  _id: ObjectId;
  userId: ObjectId;
  content: string;
  image?: string;
  likesCount: number;
  commentsCount: number;
  seenBy?: ObjectId[];
  createdAt: Date;
  updatedAt: Date;
  deletedAt?: Date | null;
}
