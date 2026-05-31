/**
 * @file PostLikeModel.ts
 * @description Define el nombre de la colección y el tipo del documento MongoDB para PostLike.
 * SIN lógica de mapeo — la transformación es responsabilidad exclusiva de los repositorios.
 * @module Community
 * @layer Data
 */

import { ObjectId } from 'mongodb';

/** Nombre de la colección en MongoDB */
export const POST_LIKE_COLLECTION = 'post_likes';

/**
 * Tipo del documento MongoDB tal como se almacena en la base de datos.
 * La unicidad (postId + userId) se garantiza mediante índice único compuesto.
 * NO contiene métodos de negocio ni de mapeo.
 */
export interface PostLikeDocument {
  _id: ObjectId;
  postId: ObjectId;
  userId: ObjectId;
  createdAt: Date;
}
