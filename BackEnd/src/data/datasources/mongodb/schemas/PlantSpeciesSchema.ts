/**
 * @file PlantSpeciesSchema.ts
 * @description Schema de validación JSON para la colección 'plant_species' en MongoDB.
 * @module Plants
 * @layer Data
 */

import { Document } from 'mongodb';

/**
 * Schema JSON para validación de documentos en la colección 'plant_species'.
 */
export const PLANT_SPECIES_VALIDATOR: Document = {
  $jsonSchema: {
    bsonType: 'object',
    required: ['name', 'scientificName', 'careRequirements', 'climateCompatibility', 'tips', 'isPublic', 'auditHistory', 'createdAt', 'updatedAt'],
    additionalProperties: true,
    properties: {
      name: {
        bsonType: 'string',
        minLength: 1,
        maxLength: 100,
        description: 'Nombre común de la especie — requerido',
      },
      scientificName: {
        bsonType: 'string',
        minLength: 1,
        maxLength: 150,
        description: 'Nombre científico binomial — requerido',
      },
      image: {
        bsonType: 'string',
        description: 'URL imagen en Cloudinary — opcional (puede no tener imagen asignada)',
      },
      careRequirements: {
        bsonType: 'object',
        required: ['wateringDays', 'lightNeed'],
        properties: {
          wateringDays: { bsonType: 'int', minimum: 1, maximum: 365 },
          lightNeed:    { bsonType: 'string', enum: ['Low', 'Medium', 'High'] },
          temperatureRange: {
            bsonType: 'object',
            properties: {
              min: { bsonType: 'number' },
              max: { bsonType: 'number' },
            },
          },
        },
      },
      climateCompatibility: {
        bsonType: 'array',
        items: { bsonType: 'string' },
        description: 'Climas compatibles — requerido',
      },
      tips: {
        bsonType: 'array',
        items: { bsonType: 'string' },
        description: 'Consejos de cuidado — requerido',
      },
      createdBy: {
        bsonType: 'objectId',
        description: 'Usuario que propuso la especie — opcional (null si es del sistema)',
      },
      isPublic: {
        bsonType: 'bool',
        description: 'Visible para todos los usuarios — requerido',
      },
      requiresPruning: {
        bsonType: 'bool',
        description: 'Indica si la especie requiere poda anual — opcional',
      },
      pruningMonths: {
        bsonType: 'array',
        items: { bsonType: 'int', minimum: 1, maximum: 12 },
        description: 'Meses de poda recomendados (1=enero, 12=diciembre) — opcional',
      },
      produceFruit: {
        bsonType: 'bool',
        description: 'Indica si la especie produce frutos o cosecha — opcional',
      },
      harvestMonths: {
        bsonType: 'array',
        items: { bsonType: 'int', minimum: 1, maximum: 12 },
        description: 'Meses de cosecha (1=enero, 12=diciembre) — opcional',
      },
      seasonalWateringAdjustment: {
        bsonType: 'object',
        properties: {
          summer: { bsonType: 'number', minimum: 0.1, maximum: 5.0 },
          winter: { bsonType: 'number', minimum: 0.1, maximum: 5.0 },
        },
        description: 'Multiplicadores estacionales de riego (verano/invierno) — opcional',
      },
      minRainfallMm: {
        bsonType: 'number',
        minimum: 0,
        maximum: 200,
        description: 'Precipitación mínima en mm para considerar la planta regada por lluvia — opcional',
      },
      waterLitersPerWatering: {
        bsonType: 'number',
        minimum: 0,
        maximum: 50,
        description: 'Cantidad de agua en litros por riego (informativo) — opcional',
      },
      auditHistory: {
        bsonType: 'array',
        items: {
          bsonType: 'object',
          required: ['date', 'userId', 'changes'],
          properties: {
            date:    { bsonType: 'date' },
            userId:  { bsonType: 'string' },
            changes: { bsonType: 'string' },
          },
        },
      },
      createdAt: { bsonType: 'date' },
      updatedAt: { bsonType: 'date' },
      deletedAt: { bsonType: ['date', 'null'] },
    },
  },
};
