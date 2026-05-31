/**
 * @file PostSchema.ts
 * @description Validador $jsonSchema para la colección 'posts' de MongoDB.
 * Define las reglas de validación a nivel de base de datos.
 * @module Community
 * @layer Data
 *
 * Índices recomendados (crear con MongoDBConnection.ensureIndexes):
 *   - { userId: 1, createdAt: -1 }        — feed del usuario
 *   - { createdAt: -1 }                   — feed global
 *   - { deletedAt: 1 }  sparse: true      — filtrar borrados
 */

import type { Document } from 'mongodb';

/**
 * Validador $jsonSchema de la colección 'posts'.
 * Aplicar con `db.createCollection('posts', { validator: POST_VALIDATOR })`.
 */
export const POST_VALIDATOR: Document = {
  $jsonSchema: {
    bsonType: 'object',
    required: ['userId', 'content', 'likesCount', 'commentsCount', 'createdAt', 'updatedAt'],
    additionalProperties: true,
    properties: {
      _id: { bsonType: 'objectId' },
      userId:        { bsonType: 'objectId',                               description: 'ID del autor del post' },
      content:       { bsonType: 'string',   maxLength: 1000,              description: 'Texto del post (máx. 1000 chars)' },
      image:         { bsonType: 'string',                                  description: 'URL Cloudinary de la imagen adjunta' },
      likesCount:    { bsonType: 'int',      minimum: 0,                   description: 'Contador desnormalizado de likes' },
      commentsCount: { bsonType: 'int',      minimum: 0,                   description: 'Contador desnormalizado de comentarios' },
      seenBy:        { bsonType: 'array',
                       items: { bsonType: 'objectId' },                     description: 'IDs de usuarios que han visto el post' },
      createdAt:     { bsonType: 'date',                                    description: 'Fecha de creación' },
      updatedAt:     { bsonType: 'date',                                    description: 'Fecha de última modificación' },
      deletedAt:     { bsonType: ['date', 'null'],                          description: 'Borrado lógico; null si activo' },
    },
  },
};
