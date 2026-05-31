/**
 * @file update_plant_usecase.spec.ts
 * @description Tests unitarios de UpdatePlantUseCase.
 * Cubre el cálculo de nextWatering con ajuste estacional y la limpieza de
 * pendingRainAdjustment cuando el usuario registra lastWatered manual
 * (evita que el rollback del cron del día siguiente sobreescriba el riego).
 * @module Plants
 * @layer Domain
 */

import 'reflect-metadata';
import { UpdatePlantUseCase } from './UpdatePlantUseCase.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const PLANT_ID  = 'plant-001';
const USER_ID   = 'user-001';
const SPECIES_ID = 'sp-001';

const mockPlantRepo = {
  findById: jest.fn(),
  update:   jest.fn(),
};

const mockSpeciesRepo = {
  findById: jest.fn(),
};

const mockMapper = {
  toResponseDTO: jest.fn(),
};

/** Devuelve un objeto Plant-like con la forma mínima que usa el use case. */
const makePlant = (overrides: Record<string, unknown> = {}) => ({
  id:                PLANT_ID,
  userId:            USER_ID,
  name:              'Test',
  speciesId:         SPECIES_ID,
  wateringFrequency: 5,
  location:          'Exterior',
  lightNeed:         'Medium',
  considerWeatherForWatering: true,
  nextWatering:      new Date('2026-05-25'),
  createdAt:         new Date('2026-05-01'),
  updatedAt:         new Date('2026-05-01'),
  deletedAt:         null,
  ...overrides,
});

const makePendingAdjustment = () => ({
  resetAt:              new Date('2026-05-19'),
  previousNextWatering: new Date('2026-05-20'),
  expectedMm:           80,
  locationLat:          40.4,
  locationLon:          -3.7,
});

// ─── Suite ────────────────────────────────────────────────────────────────────

describe('UpdatePlantUseCase', () => {
  let useCase: UpdatePlantUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    mockSpeciesRepo.findById.mockResolvedValue(null); // sin ajuste estacional por defecto
    mockPlantRepo.update.mockImplementation(async (_id, data) => ({ ...makePlant(), ...data }));
    mockMapper.toResponseDTO.mockImplementation((p) => ({ id: p.id, name: p.name }));

    useCase = new UpdatePlantUseCase(
      mockPlantRepo   as any,
      mockSpeciesRepo as any,
      mockMapper      as any,
    );
  });

  // ── Errores estructurales ───────────────────────────────────────────────────

  it('lanza NotFoundException si la planta no existe', async () => {
    mockPlantRepo.findById.mockResolvedValue(null);
    await expect(useCase.execute(PLANT_ID, {} as any, USER_ID)).rejects.toThrow(NotFoundException);
  });

  it('lanza NotFoundException si la planta está soft-deleted', async () => {
    mockPlantRepo.findById.mockResolvedValue(makePlant({ deletedAt: new Date() }));
    await expect(useCase.execute(PLANT_ID, {} as any, USER_ID)).rejects.toThrow(NotFoundException);
  });

  // ── Limpieza de pendingRainAdjustment ───────────────────────────────────────

  it('limpia pendingRainAdjustment cuando se registra lastWatered manual', async () => {
    mockPlantRepo.findById.mockResolvedValue(makePlant({
      pendingRainAdjustment: makePendingAdjustment(),
    }));

    const dto = {
      wateringFrequency: 5,
      lastWatered:       new Date('2026-05-19T10:00:00Z').toISOString(),
    };

    await useCase.execute(PLANT_ID, dto as any, USER_ID);

    expect(mockPlantRepo.update).toHaveBeenCalledTimes(1);
    const updateArg = mockPlantRepo.update.mock.calls[0][1];
    expect(updateArg.pendingRainAdjustment).toBeNull();
    expect(updateArg.lastWatered).toBeInstanceOf(Date);
  });

  it('NO toca pendingRainAdjustment si la planta no tiene reset pendiente', async () => {
    mockPlantRepo.findById.mockResolvedValue(makePlant()); // sin pendingRainAdjustment

    const dto = {
      wateringFrequency: 5,
      lastWatered:       new Date('2026-05-19T10:00:00Z').toISOString(),
    };

    await useCase.execute(PLANT_ID, dto as any, USER_ID);

    const updateArg = mockPlantRepo.update.mock.calls[0][1];
    expect(updateArg).not.toHaveProperty('pendingRainAdjustment');
  });

  it('NO toca pendingRainAdjustment si solo se cambia el nombre (sin lastWatered)', async () => {
    mockPlantRepo.findById.mockResolvedValue(makePlant({
      pendingRainAdjustment: makePendingAdjustment(),
    }));

    await useCase.execute(PLANT_ID, { name: 'Nuevo nombre' } as any, USER_ID);

    const updateArg = mockPlantRepo.update.mock.calls[0][1];
    expect(updateArg).not.toHaveProperty('pendingRainAdjustment');
    expect(updateArg.name).toBe('Nuevo nombre');
  });

  // ── nextWatering ajustado por estacionalidad ───────────────────────────────

  it('recalcula nextWatering aplicando seasonalWateringAdjustment.summer en julio', async () => {
    // Forzamos julio (mes 7) en una ventana controlada.
    const realDate = Date;
    const fixedNow = new Date('2026-07-15T12:00:00Z');
    (global as any).Date = class extends realDate {
      constructor(value?: any) { super(value ?? fixedNow.toISOString()); }
      static now() { return fixedNow.getTime(); }
    } as any;

    try {
      mockPlantRepo.findById.mockResolvedValue(makePlant());
      mockSpeciesRepo.findById.mockResolvedValue({
        id: SPECIES_ID,
        seasonalWateringAdjustment: { summer: 0.6, winter: 1.5 },
      });

      await useCase.execute(PLANT_ID, { wateringFrequency: 10 } as any, USER_ID);

      // 10 * 0.6 = 6 días en verano (max(1, round(6))).
      const updateArg = mockPlantRepo.update.mock.calls[0][1];
      expect(updateArg.wateringFrequency).toBe(10);
      const nextWatering: Date = updateArg.nextWatering;
      const diffDays = Math.round((nextWatering.getTime() - fixedNow.getTime()) / (1000 * 60 * 60 * 24));
      expect(diffDays).toBe(6);
    } finally {
      (global as any).Date = realDate;
    }
  });
});
