/**
 * @file plant_species_mapper.spec.ts
 * @description Tests unitarios para PlantSpeciesMapper.
 * Verifica que requiresPruning y pruningMonths (array) se mapean correctamente entre
 * documento MongoDB, entidad de dominio y DTO de respuesta.
 * @module Plants
 * @layer Data
 */

import { ObjectId } from 'mongodb';
import { PlantSpeciesMapper } from './plant_species_mapper.js';
import type { PlantSpeciesDocument } from '../datasources/mongodb/models/PlantSpeciesModel.js';

// ─── Helpers ──────────────────────────────────────────────────────────────────

const NOW = new Date('2026-01-01T00:00:00.000Z');

/**
 * Crea un documento de especie base con overrides opcionales.
 */
function makeDoc(overrides: Partial<PlantSpeciesDocument> = {}): PlantSpeciesDocument {
  return {
    _id:                  new ObjectId('507f1f77bcf86cd799439011'),
    name:                 'Rosa',
    scientificName:       'Rosa spp.',
    image:                '',
    careRequirements:     { wateringDays: 5, lightNeed: 'High' },
    climateCompatibility: ['Templado', 'Mediterráneo'],
    tips:                 ['Poda los tallos muertos para estimular nuevas flores.'],
    isPublic:             true,
    auditHistory:         [],
    createdAt:            NOW,
    updatedAt:            NOW,
    ...overrides,
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

describe('PlantSpeciesMapper', () => {
  const mapper = new PlantSpeciesMapper();

  // ── toEntity() ───────────────────────────────────────────────────────────────

  describe('toEntity()', () => {
    test('mapea requiresPruning=true y pruningMonths=[2] correctamente', () => {
      const doc    = makeDoc({ requiresPruning: true, pruningMonths: [2] });
      const entity = mapper.toEntity(doc);

      expect(entity.requiresPruning).toBe(true);
      expect(entity.pruningMonths).toEqual([2]);
    });

    test('mapea requiresPruning=true y pruningMonths=[3] correctamente (Lavanda)', () => {
      const doc    = makeDoc({ name: 'Lavanda', requiresPruning: true, pruningMonths: [3] });
      const entity = mapper.toEntity(doc);

      expect(entity.requiresPruning).toBe(true);
      expect(entity.pruningMonths).toEqual([3]);
    });

    test('requiresPruning y pruningMonths son undefined cuando el documento no los incluye', () => {
      const doc    = makeDoc();
      const entity = mapper.toEntity(doc);

      expect(entity.requiresPruning).toBeUndefined();
      expect(entity.pruningMonths).toBeUndefined();
    });

    test('mapea requiresPruning=false sin pruningMonths', () => {
      const doc    = makeDoc({ requiresPruning: false });
      const entity = mapper.toEntity(doc);

      expect(entity.requiresPruning).toBe(false);
      expect(entity.pruningMonths).toBeUndefined();
    });

    test('mapea produceFruit=true y harvestMonths=[6,7,8] correctamente (Limonero)', () => {
      const doc    = makeDoc({ name: 'Limonero', produceFruit: true, harvestMonths: [6, 7, 8] });
      const entity = mapper.toEntity(doc);

      expect(entity.produceFruit).toBe(true);
      expect(entity.harvestMonths).toEqual([6, 7, 8]);
    });

    test('produceFruit y harvestMonths son undefined cuando el documento no los incluye', () => {
      const doc    = makeDoc();
      const entity = mapper.toEntity(doc);

      expect(entity.produceFruit).toBeUndefined();
      expect(entity.harvestMonths).toBeUndefined();
    });
  });

  // ── toDocument() ─────────────────────────────────────────────────────────────

  describe('toDocument()', () => {
    test('incluye requiresPruning y pruningMonths en el documento cuando la entidad los tiene', () => {
      const doc    = makeDoc({ requiresPruning: true, pruningMonths: [2] });
      const entity = mapper.toEntity(doc);
      const result = mapper.toDocument(entity);

      expect(result.requiresPruning).toBe(true);
      expect(result.pruningMonths).toEqual([2]);
    });

    test('requiresPruning y pruningMonths son undefined en el documento cuando la entidad no los tiene', () => {
      const doc    = makeDoc();
      const entity = mapper.toEntity(doc);
      const result = mapper.toDocument(entity);

      expect(result.requiresPruning).toBeUndefined();
      expect(result.pruningMonths).toBeUndefined();
    });

    test('incluye produceFruit y harvestMonths en el documento cuando la entidad los tiene', () => {
      const doc    = makeDoc({ produceFruit: true, harvestMonths: [10, 11] });
      const entity = mapper.toEntity(doc);
      const result = mapper.toDocument(entity);

      expect(result.produceFruit).toBe(true);
      expect(result.harvestMonths).toEqual([10, 11]);
    });

    test('produceFruit y harvestMonths son undefined en el documento cuando la entidad no los tiene', () => {
      const doc    = makeDoc();
      const entity = mapper.toEntity(doc);
      const result = mapper.toDocument(entity);

      expect(result.produceFruit).toBeUndefined();
      expect(result.harvestMonths).toBeUndefined();
    });
  });

  // ── toResponseDTO() ───────────────────────────────────────────────────────────

  describe('toResponseDTO()', () => {
    test('incluye requiresPruning y pruningMonths en el DTO cuando la entidad los tiene', () => {
      const doc    = makeDoc({ requiresPruning: true, pruningMonths: [2] });
      const entity = mapper.toEntity(doc);
      const dto    = mapper.toResponseDTO(entity);

      expect(dto.requiresPruning).toBe(true);
      expect(dto.pruningMonths).toEqual([2]);
    });

    test('requiresPruning y pruningMonths son undefined en el DTO cuando la entidad no los tiene', () => {
      const doc    = makeDoc();
      const entity = mapper.toEntity(doc);
      const dto    = mapper.toResponseDTO(entity);

      expect(dto.requiresPruning).toBeUndefined();
      expect(dto.pruningMonths).toBeUndefined();
    });

    test('incluye produceFruit y harvestMonths en el DTO cuando la entidad los tiene', () => {
      const doc    = makeDoc({ produceFruit: true, harvestMonths: [6, 7, 8] });
      const entity = mapper.toEntity(doc);
      const dto    = mapper.toResponseDTO(entity);

      expect(dto.produceFruit).toBe(true);
      expect(dto.harvestMonths).toEqual([6, 7, 8]);
    });

    test('produceFruit y harvestMonths son undefined en el DTO cuando la entidad no los tiene', () => {
      const doc    = makeDoc();
      const entity = mapper.toEntity(doc);
      const dto    = mapper.toResponseDTO(entity);

      expect(dto.produceFruit).toBeUndefined();
      expect(dto.harvestMonths).toBeUndefined();
    });
  });

  // ── round-trip ────────────────────────────────────────────────────────────────

  describe('round-trip toEntity → toDocument', () => {
    test('los campos de poda se conservan intactos en ida y vuelta', () => {
      const original = makeDoc({ requiresPruning: true, pruningMonths: [2] });
      const entity   = mapper.toEntity(original);
      const restored = mapper.toDocument(entity);

      expect(restored.requiresPruning).toBe(original.requiresPruning);
      expect(restored.pruningMonths).toEqual(original.pruningMonths);
    });

    test('los campos de cosecha se conservan intactos en ida y vuelta', () => {
      const original = makeDoc({ produceFruit: true, harvestMonths: [6, 7, 8] });
      const entity   = mapper.toEntity(original);
      const restored = mapper.toDocument(entity);

      expect(restored.produceFruit).toBe(original.produceFruit);
      expect(restored.harvestMonths).toEqual(original.harvestMonths);
    });
  });
});
