/**
 * @file CommentSchema.ts
 * @description Validador $jsonSchema para la colección 'comments' de MongoDB.
 * @module Community
 * @layer Data
 *
 * Índices recomendados:
 *   - { postId: 1, createdAt: -1 }   — comentarios de un post
 *   - { userId: 1, createdAt: -1 }   — comentarios de un usuario
 *   - { deletedAt: 1 }  sparse: true — filtrar borrados
 */

import type { Document } from 'mongodb';

/**
 * Validador $jsonSchema de la colección 'comments'.
 */
export const COMMENT_VALIDATOR: Document = {
  $jsonSchema: {
    bsonType: 'object',
    required: ['postId', 'userId', 'content', 'createdAt'],
    additionalProperties: true,
    properties: {
      _id:       { bsonType: 'objectId' },
      postId:    { bsonType: 'objectId',                  description: 'ID del post comentado' },
      userId:    { bsonType: 'objectId',                  description: 'ID del autor del comentario' },
      content:   { bsonType: 'string',   maxLength: 500,  description: 'Texto del comentario (máx. 500 chars)' },
      createdAt: { bsonType: 'date',                      description: 'Fecha de creación' },
      deletedAt: { bsonType: ['date', 'null'],             description: 'Borrado lógico; null si activo' },
    },
  },
};
