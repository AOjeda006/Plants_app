/**
 * @file ReminderHistorySchema.ts
 * @description Validador JSON de la colección reminder_history en MongoDB.
 * @module Reminders
 * @layer Data
 */

export const REMINDER_HISTORY_SCHEMA = {
  bsonType: 'object',
  required: ['reminderId', 'processedAt', 'result', 'idempotencyKey'],
  properties: {
    reminderId:      { bsonType: 'objectId', description: 'Id del recordatorio procesado' },
    processedAt:     { bsonType: 'date',     description: 'Momento del procesamiento' },
    result:          { bsonType: 'string',   enum: ['success', 'skipped', 'error'] },
    details:         { bsonType: 'string',   description: 'Detalle adicional (error, razón de skip)' },
    idempotencyKey:  { bsonType: 'string',   description: 'Clave de idempotencia: reminderId_YYYY-MM-DD' },
  },
} as const;
