/**
 * @file export_user_data_usecase.spec.ts
 * @description Tests unitarios para ExportUserDataUseCase.
 * Verifica que el JSON exportado contiene perfil, plantas y totalPlants.
 * Verifica que lanza NotFoundException si el usuario no existe.
 * @module User
 * @layer Domain
 */

import 'reflect-metadata';
import { ExportUserDataUseCase } from './ExportUserDataUseCase.js';
import { NotFoundException }     from '../../../core/exceptions/NotFoundException.js';
import { User }                  from '../../entities/User.js';
import { Plant }                 from '../../entities/Plant.js';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockUserRepo = {
  findById: jest.fn(),
};

const mockPlantRepo = {
  findByUserId: jest.fn(),
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

const makeUser = (overrides = {}) =>
  new User({
    id:           'user-001',
    name:         'Test User',
    email:        'test@example.com',
    passwordHash: 'hashed',
    role:         'user',
    createdAt:    new Date('2026-01-01'),
    updatedAt:    new Date('2026-01-01'),
    ...overrides,
  });

const makePlant = (overrides = {}) =>
  new Plant({
    id:               'plant-001',
    userId:           'user-001',
    name:             'Monstera',
    location:         'Interior',
    wateringFrequency: 7,
    lightNeed:        'Medium',
    considerWeatherForWatering: false,
    createdAt:        new Date('2026-02-01'),
    updatedAt:        new Date('2026-02-01'),
    ...overrides,
  });

// ─── Suite ────────────────────────────────────────────────────────────────────

describe('ExportUserDataUseCase', () => {
  let useCase: ExportUserDataUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    useCase = new ExportUserDataUseCase(
      mockUserRepo  as any,
      mockPlantRepo as any,
    );
  });

  it('debe devolver exportedAt, profile, plants y totalPlants', async () => {
    mockUserRepo.findById.mockResolvedValue(makeUser());
    mockPlantRepo.findByUserId.mockResolvedValue([makePlant(), makePlant({ id: 'plant-002', name: 'Pothos' })]);

    const result = await useCase.execute('user-001');

    expect(result).toHaveProperty('exportedAt');
    expect(typeof result.exportedAt).toBe('string');

    expect(result).toHaveProperty('profile');
    const profile = result.profile as Record<string, unknown>;
    expect(profile.id).toBe('user-001');
    expect(profile.email).toBe('test@example.com');
    expect(profile).not.toHaveProperty('passwordHash');

    expect(Array.isArray(result.plants)).toBe(true);
    expect((result.plants as unknown[]).length).toBe(2);

    expect(result.totalPlants).toBe(2);
  });

  it('debe devolver plants vacío si el usuario no tiene plantas', async () => {
    mockUserRepo.findById.mockResolvedValue(makeUser());
    mockPlantRepo.findByUserId.mockResolvedValue([]);

    const result = await useCase.execute('user-001');

    expect(result.plants).toEqual([]);
    expect(result.totalPlants).toBe(0);
  });

  it('debe incluir speciesId como null si la planta no tiene especie', async () => {
    mockUserRepo.findById.mockResolvedValue(makeUser());
    const plant = makePlant();  // sin speciesId
    mockPlantRepo.findByUserId.mockResolvedValue([plant]);

    const result = await useCase.execute('user-001');

    const plants = result.plants as Array<Record<string, unknown>>;
    expect(plants[0].speciesId).toBeNull();
  });

  it('debe lanzar NotFoundException si el usuario no existe', async () => {
    mockUserRepo.findById.mockResolvedValue(null);

    await expect(useCase.execute('no-existe')).rejects.toThrow(NotFoundException);
  });

  it('debe incluir timestamp ISO válido en exportedAt', async () => {
    mockUserRepo.findById.mockResolvedValue(makeUser());
    mockPlantRepo.findByUserId.mockResolvedValue([]);

    const before = new Date().toISOString();
    const result = await useCase.execute('user-001');
    const after  = new Date().toISOString();

    expect(result.exportedAt as string >= before).toBe(true);
    expect(result.exportedAt as string <= after).toBe(true);
  });
});
