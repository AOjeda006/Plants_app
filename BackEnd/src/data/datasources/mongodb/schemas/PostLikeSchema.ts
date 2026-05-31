/**
 * @file PostLikeSchema.ts
 * @description Validador $jsonSchema para la colección 'post_likes' de MongoDB.
 * @module Community
 * @layer Data
 *
 * Índices recomendados:
 *   - { postId: 1, userId: 1 }  unique: true  — garantiza un like por usuario/post
 *   - { userId: 1, createdAt: -1 }             — likes de un usuario
 */

import type { Document } from 'mongodb';

/**
 * Validador $jsonSchema de la colección 'post_likes'.
 */
export const POST_LIKE_VALIDATOR: Document = {
  $jsonSchema: {
    bsonType: 'object',
    required: ['postId', 'userId', 'createdAt'],
    additionalProperties: false,
    properties: {
      _id:       { bsonType: 'objectId' },
      postId:    { bsonType: 'objectId', description: 'ID del post al que se da like' },
      userId:    { bsonType: 'objectId', description: 'ID del usuario que da el like' },
      createdAt: { bsonType: 'date',     description: 'Momento en que se registró el like' },
    },
  },
};
