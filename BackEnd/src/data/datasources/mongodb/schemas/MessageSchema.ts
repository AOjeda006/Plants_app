/**
 * @file MessageSchema.ts
 * @description Validador $jsonSchema para la colección 'messages' de MongoDB.
 * @module Chat
 * @layer Data
 *
 * Índices recomendados:
 *   - { conversationId: 1, createdAt: -1 } — paginación de mensajes
 *   - { conversationId: 1, status: 1 }     — conteo de no leídos
 *   - { tempId: 1 }  sparse: true          — matching de ACK optimistas
 *   - { senderId: 1 }                       — mensajes de un usuario
 */

import type { Document } from 'mongodb';

/**
 * Validador $jsonSchema de la colección 'messages'.
 */
export const MESSAGE_VALIDATOR: Document = {
  $jsonSchema: {
    bsonType: 'object',
    required: ['conversationId', 'senderId', 'status', 'createdAt', 'updatedAt'],
    additionalProperties: true,
    properties: {
      _id:            { bsonType: 'objectId' },
      conversationId: { bsonType: 'objectId',    description: 'ID de la conversación' },
      senderId:       { bsonType: 'objectId',    description: 'ID del emisor' },
      receiverId:     { bsonType: 'objectId',    description: 'ID del receptor (opcional)' },
      text:           { bsonType: 'string', maxLength: 2000, description: 'Texto del mensaje' },
      contentMeta:    { bsonType: 'object',      description: 'Metadatos de contenido multimedia' },
      status:         { bsonType: 'string', enum: ['pending', 'sent', 'delivered', 'read'],
                        description: 'Estado de entrega: pending → sent → delivered → read' },
      tempId:         { bsonType: 'string',      description: 'ID temporal del cliente para ACK optimista' },
      createdAt:      { bsonType: 'date',        description: 'Fecha de creación' },
      updatedAt:      { bsonType: 'date',        description: 'Fecha de última modificación' },
    },
  },
};
