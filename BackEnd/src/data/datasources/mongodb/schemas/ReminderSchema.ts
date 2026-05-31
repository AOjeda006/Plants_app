/**
 * @file ReminderSchema.ts
 * @description Validador JSON de la colección reminders en MongoDB.
 * @module Reminders
 * @layer Data
 */

export const REMINDER_SCHEMA = {
  bsonType: 'object',
  required: ['plantId', 'userId', 'type', 'scheduledDate', 'message', 'isCompleted', 'suspended', 'attempts', 'createdAt'],
  properties: {
    plantId:       { bsonType: 'objectId', description: 'Id de la planta asociada' },
    userId:        { bsonType: 'objectId', description: 'Id del usuario propietario' },
    type:          { bsonType: 'string',   enum: ['watering', 'pruning', 'custom'] },
    scheduledDate: { bsonType: 'date',     description: 'Fecha programada del recordatorio' },
    message:       { bsonType: 'string',   description: 'Mensaje de la notificación' },
    isCompleted:   { bsonType: 'bool',     description: 'true si el recordatorio ha finalizado definitivamente' },
    suspended:     { bsonType: 'bool',     description: 'true si está suspendido temporalmente' },
    attempts:      { bsonType: 'int',      description: 'Número de intentos de notificación' },
    createdAt:     { bsonType: 'date' },
  },
} as const;
