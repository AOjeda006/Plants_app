/**
 * @file ConversationSchema.ts
 * @description Validador $jsonSchema para la colección 'conversations' de MongoDB.
 * @module Chat
 * @layer Data
 *
 * Índices recomendados:
 *   - { participants: 1 }              — buscar conversaciones de un usuario
 *   - { participants: 1, deletedAt: 1} — filtrar activas por participante
 *   - { lastMessageAt: -1 }            — ordenar por actividad reciente
 */

import type { Document } from 'mongodb';

/**
 * Validador $jsonSchema de la colección 'conversations'.
 */
export const CONVERSATION_VALIDATOR: Document = {
  $jsonSchema: {
    bsonType: 'object',
    required: ['participants', 'createdAt', 'updatedAt'],
    additionalProperties: true,
    properties: {
      _id:           { bsonType: 'objectId' },
      participants:  { bsonType: 'array', items: { bsonType: 'objectId' }, minItems: 2,
                       description: 'IDs de los participantes (mínimo 2)' },
      lastMessageAt: { bsonType: ['date', 'null'],  description: 'Fecha del último mensaje' },
      createdAt:     { bsonType: 'date',             description: 'Fecha de creación' },
      updatedAt:     { bsonType: 'date',             description: 'Fecha de última modificación' },
      deletedAt:     { bsonType: ['date', 'null'],   description: 'Borrado lógico; null si activa' },
    },
  },
};
