/**
 * @file PlantSchema.ts
 * @description Schema de validación JSON para la colección 'plants' en MongoDB.
 * Se usa como referencia documental; la validación de entrada se hace en DTOs con class-validator.
 * @module Plants
 * @layer Data
 */

import { Document } from 'mongodb';

/**
 * Schema JSON para validación de documentos en la colección 'plants'.
 */
export const PLANT_VALIDATOR: Document = {
  $jsonSchema: {
    bsonType: 'object',
    required: [
      'userId', 'name', 'location', 'wateringFrequency',
      'lightNeed', 'considerWeatherForWatering', 'createdAt', 'updatedAt',
    ],
    additionalProperties: true,
    properties: {
      userId: {
        bsonType: 'objectId',
        description: 'Referencia al usuario propietario — requerido',
      },
      name: {
        bsonType: 'string',
        minLength: 1,
        maxLength: 100,
        description: 'Nombre de la planta — requerido',
      },
      speciesId: {
        bsonType: 'objectId',
        description: 'Referencia a PlantSpecies — opcional',
      },
      photo: {
        bsonType: 'string',
        description: 'URL de imagen en Cloudinary — opcional',
      },
      location: {
        bsonType: 'string',
        enum: ['Interior', 'Exterior'],
        description: 'Ubicación de la planta — requerido',
      },
      wateringFrequency: {
        bsonType: 'int',
        minimum: 1,
        maximum: 365,
        description: 'Frecuencia de riego en días — requerido',
      },
      lightNeed: {
        bsonType: 'string',
        enum: ['Low', 'Medium', 'High'],
        description: 'Necesidad de luz — requerido',
      },
      pruningFrequency: {
        bsonType: 'int',
        minimum: 1,
        maximum: 365,
        description: 'Frecuencia de poda en días — opcional',
      },
      notes: {
        bsonType: 'string',
        maxLength: 1000,
        description: 'Notas libres del usuario — opcional',
      },
      nextWatering: {
        bsonType: 'date',
        description: 'Próxima fecha de riego — opcional',
      },
      nextPruning: {
        bsonType: 'date',
        description: 'Próxima fecha de poda — opcional',
      },
      considerWeatherForWatering: {
        bsonType: 'bool',
        description: 'Considerar clima para riego — requerido',
      },
      overrides: {
        bsonType: 'array',
        items: {
          bsonType: 'object',
          required: ['fromDate', 'toDate', 'wateringFrequencyDays'],
          properties: {
            fromDate:             { bsonType: 'date' },
            toDate:               { bsonType: 'date' },
            wateringFrequencyDays: { bsonType: 'int', minimum: 1 },
            reason:               { bsonType: 'string' },
          },
        },
      },
      // Reset de nextWatering pendiente de confirmación por history. Se
      // rellena en _processWeather y se limpia/aplica rollback en
      // _processYesterdayRain del día siguiente. Acepta null para
      // permitir "limpiar" el campo via $set sin tocar el resto de la
      // planta (en lugar de un $unset).
      pendingRainAdjustment: {
        bsonType: ['object', 'null'],
        required: ['resetAt', 'expectedMm', 'locationLat', 'locationLon'],
        properties: {
          resetAt:               { bsonType: 'date' },
          previousNextWatering:  { bsonType: ['date', 'null'] },
          expectedMm:            { bsonType: 'double' },
          locationLat:           { bsonType: 'double' },
          locationLon:           { bsonType: 'double' },
        },
      },
      createdAt:  { bsonType: 'date' },
      updatedAt:  { bsonType: 'date' },
      deletedAt:  { bsonType: ['date', 'null'] },
    },
  },
};
