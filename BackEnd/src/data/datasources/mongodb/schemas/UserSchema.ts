/**
 * @file UserSchema.ts
 * @description Definición del schema de validación para la colección 'users' en MongoDB.
 * Describe la estructura y restricciones a nivel de base de datos.
 * Los índices se crean vía ensureIndexes() en MongoDBConnection usando DEFAULT_INDEXES.
 * @module Auth
 * @layer Data
 */

import { Document } from 'mongodb';

/**
 * Schema JSON de validación para MongoDB ($jsonSchema).
 * Se puede aplicar mediante db.command({ collMod: 'users', validator: USER_VALIDATOR }).
 * En el TFG se usa como referencia documental; la validación principal la hace class-validator en los DTOs.
 */
export const USER_VALIDATOR: Document = {
  $jsonSchema: {
    bsonType: 'object',
    required: ['name', 'email', 'passwordHash', 'preferences', 'createdAt', 'updatedAt'],
    additionalProperties: true,
    properties: {
      name: {
        bsonType: 'string',
        minLength: 2,
        maxLength: 100,
        description: 'Nombre completo del usuario — requerido',
      },
      email: {
        bsonType: 'string',
        pattern: '^[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2,}$',
        description: 'Email único del usuario — requerido',
      },
      passwordHash: {
        bsonType: 'string',
        description: 'Hash bcrypt de la contraseña — requerido',
      },
      photo: {
        bsonType: 'string',
        description: 'URL de la foto de perfil en Cloudinary — opcional',
      },
      bannerPhoto: {
        bsonType: 'string',
        description: 'URL del banner/fondo de perfil en Cloudinary — opcional',
      },
      bio: {
        bsonType: 'string',
        maxLength: 500,
        description: 'Biografía del usuario — opcional',
      },
      location: {
        bsonType: 'string',
        description: 'Ubicación del usuario para el clima (nombre ciudad) — opcional',
      },
      locationLat: {
        bsonType: 'double',
        description: 'Latitud geográfica de la ubicación — opcional',
      },
      locationLon: {
        bsonType: 'double',
        description: 'Longitud geográfica de la ubicación — opcional',
      },
      fcmToken: {
        bsonType: 'string',
        description: 'Token FCM para notificaciones push — opcional',
      },
      lastChatPushTitle: {
        bsonType: ['string', 'null'],
        description: 'Último título de push de chat enviado offline. Sirve para deduplicar: si el cálculo del siguiente push da el mismo título, se omite. Se resetea a null al conectar el socket.',
      },
      preferences: {
        bsonType: 'object',
        required: ['appearInChatSearch', 'considerWeatherByDefault'],
        properties: {
          appearInChatSearch:        { bsonType: 'bool' },
          considerWeatherByDefault:  { bsonType: 'bool' },
          isPrivate: {
            bsonType: 'bool',
            description: 'Perfil privado: no aparece en feed público — opcional, default false',
          },
          pushNotifications: {
            bsonType: 'bool',
            description: 'Si false, no enviar push FCM aunque haya fcmToken. Opcional, default true.',
          },
        },
      },
      createdAt:  { bsonType: 'date' },
      updatedAt:  { bsonType: 'date' },
      deletedAt:  { bsonType: 'date' },
    },
  },
};
