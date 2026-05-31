/**
 * @file plants_usecase.spec.ts
 * @description Tests unitarios para CreatePlantUseCase, UpdatePlantUseCase,
 * DeletePlantUseCase y SearchSpeciesUseCase.
 * Mockea IPlantRepository, IPlantSpeciesRepository, IPlantMapper y verifyOwnership.
 * @module Plants
 * @layer Domain
 */

import 'reflect-metadata';
import { CreatePlantUseCase }   from './CreatePlantUseCase.js';
import { UpdatePlantUseCase }   from './UpdatePlantUseCase.js';
import { DeletePlantUseCase }   from './DeletePlantUseCase.js';
import { SearchSpeciesUseCase } from './SearchSpeciesUseCase.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';
import { UnauthorizedException } from '../../../core/exceptions/UnauthorizedException.js';
import { Plant } from '../../entities/Plant.js';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockPlantRepo = {
  findById:  jest.fn(),
  create:    jest.fn(),
  update:    jest.fn(),
  delete:    jest.fn(),
};

const mockSpeciesRepo = {
  findById: jest.fn(),
};

const mockMapper = {
  toResponseDTO: jest.fn(),
};

// ─── Helper: planta de ejemplo ────────────────────────────────────────────────

const USER_ID  = 'owner-user-id';
const PLANT_ID = 'plant-id-001';

const makePlant = (overrides: Partial<ConstructorParameters<typeof Plant>[0]> = {}) =>
  new Plant({
    id:               PLANT_ID,
    userId:           USER_ID,
    name:             'Monstera',
    location:         'Interior',
    wateringFrequency: 7,
    lightNeed:        'Medium',
    considerWeatherForWatering: false,
    overrides:        [],
    createdAt:        new Date(),
    updatedAt:        new Date(),
    ...overrides,
  });

const makePlantDTO = () => ({
  id:               PLANT_ID,
  userId:           USER_ID,
  name:             'Monstera',
  wateringFrequency: 7,
  lightNeed:        'Bright indirect',
  createdAt:        new Date().toISOString(),
});

// ─── CreatePlantUseCase ────────────────────────────────────────────────────────

const SPECIES_STUB = { id: 'species-001', name: 'Pothos', careRequirements: { wateringDays: 7, lightNeed: 'Low' } };

describe('CreatePlantUseCase', () => {
  let useCase: CreatePlantUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    useCase = new CreatePlantUseCase(
      mockPlantRepo   as any,
      mockSpeciesRepo as any,
      mockMapper      as any,
    );
    // Por defecto la especie existe
    mockSpeciesRepo.findById.mockResolvedValue(SPECIES_STUB);
  });

  it('debe crear una planta y devolver PlantResponseDTO', async () => {
    const dto = {
      name:             'Pothos',
      speciesId:        'species-001',
      wateringFrequency: 5,
      lightNeed:        'Low',
      considerWeatherForWatering: false,
    };

    const created     = makePlant({ name: 'Pothos' });
    const expectedDTO = makePlantDTO();
    mockPlantRepo.create.mockResolvedValue(created);
    mockMapper.toResponseDTO.mockReturnValue(expectedDTO);

    const result = await useCase.execute(dto as any, USER_ID);

    expect(mockSpeciesRepo.findById).toHaveBeenCalledWith('species-001');
    expect(mockPlantRepo.create).toHaveBeenCalledTimes(1);
    expect(mockMapper.toResponseDTO).toHaveBeenCalledWith(created);
    expect(result).toEqual(expectedDTO);
  });

  it('debe calcular nextWatering a partir de wateringFrequency', async () => {
    const dto = { name: 'Cactus', speciesId: 'species-001', wateringFrequency: 30, lightNeed: 'High' };
    const created = makePlant({ name: 'Cactus', wateringFrequency: 30 });

    mockPlantRepo.create.mockResolvedValue(created);
    mockMapper.toResponseDTO.mockReturnValue({});

    await useCase.execute(dto as any, USER_ID);

    const createdArg = mockPlantRepo.create.mock.calls[0][0];
    expect(createdArg.nextWatering).toBeInstanceOf(Date);
    expect(createdArg.nextWatering.getTime()).toBeGreaterThan(Date.now());
  });

  it('debe lanzar NotFoundException si la especie no existe', async () => {
    mockSpeciesRepo.findById.mockResolvedValue(null);
    const dto = { name: 'Rara', speciesId: 'no-existe', wateringFrequency: 7, lightNeed: 'Medium' };

    await expect(useCase.execute(dto as any, USER_ID)).rejects.toThrow(NotFoundException);
    expect(mockPlantRepo.create).not.toHaveBeenCalled();
  });
});

// ─── UpdatePlantUseCase ────────────────────────────────────────────────────────

describe('UpdatePlantUseCase', () => {
  let useCase: UpdatePlantUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    // UpdatePlantUseCase requiere 3 dependencias: plantRepo, speciesRepo, mapper.
    useCase = new UpdatePlantUseCase(mockPlantRepo as any, mockSpeciesRepo as any, mockMapper as any);
    // Por defecto speciesRepo no encuentra especie (suficiente para tests sin wateringFrequency).
    mockSpeciesRepo.findById.mockResolvedValue(null);
  });

  it('debe actualizar la planta y devolver PlantResponseDTO', async () => {
    const plant = makePlant();
    mockPlantRepo.findById.mockResolvedValue(plant);

    const updated     = makePlant({ name: 'Monstera Actualizada' });
    const expectedDTO = makePlantDTO(); // capturado una sola vez para evitar diferencia de ms
    mockPlantRepo.update.mockResolvedValue(updated);
    mockMapper.toResponseDTO.mockReturnValue(expectedDTO);

    const result = await useCase.execute(PLANT_ID, { name: 'Monstera Actualizada' } as any, USER_ID);

    expect(mockPlantRepo.update).toHaveBeenCalledTimes(1);
    expect(result).toEqual(expectedDTO);
  });

  it('debe lanzar NotFoundException si la planta no existe', async () => {
    mockPlantRepo.findById.mockResolvedValue(null);

    await expect(
      useCase.execute('no-existe', {} as any, USER_ID),
    ).rejects.toThrow(NotFoundException);
  });

  it('debe lanzar UnauthorizedException si el userId no coincide con el propietario', async () => {
    mockPlantRepo.findById.mockResolvedValue(makePlant({ userId: 'otro-usuario' }));

    await expect(
      useCase.execute(PLANT_ID, {} as any, USER_ID),
    ).rejects.toThrow(UnauthorizedException);
  });

  it('debe lanzar NotFoundException si la planta tiene deletedAt definido', async () => {
    mockPlantRepo.findById.mockResolvedValue(makePlant({ deletedAt: new Date() }));

    await expect(
      useCase.execute(PLANT_ID, {} as any, USER_ID),
    ).rejects.toThrow(NotFoundException);
  });

  // ── Ajuste estacional de riego ─────────────────────────────────────────────

  it('aplica factor estacional de verano (×0.7) al actualizar wateringFrequency', async () => {
    // Fijar el reloj en verano (julio) para que getSeasonalFactor retorne el factor summer.
    jest.useFakeTimers({ now: new Date('2026-07-15T12:00:00.000Z') });

    const plant = makePlant({ speciesId: 'species-001' });
    mockPlantRepo.findById.mockResolvedValue(plant);
    // Especie con ajuste verano = 0.7 → regar un 30% más frecuente.
    mockSpeciesRepo.findById.mockResolvedValue({
      seasonalWateringAdjustment: { summer: 0.7 },
    });
    mockPlantRepo.update.mockImplementation(async (_id: string, _updates: unknown) => makePlant());
    mockMapper.toResponseDTO.mockReturnValue(makePlantDTO());

    await useCase.execute(PLANT_ID, { wateringFrequency: 10 } as any, USER_ID);

    const updateArgs = mockPlantRepo.update.mock.calls[0][1] as any;
    // effectiveFreq = round(10 * 0.7) = 7 días
    const expectedFreq = Math.round(10 * 0.7);
    const expectedDate = new Date('2026-07-15T12:00:00.000Z');
    expectedDate.setDate(expectedDate.getDate() + expectedFreq);

    expect(updateArgs.nextWatering).toBeInstanceOf(Date);
    expect(
      Math.abs((updateArgs.nextWatering as Date).getTime() - expectedDate.getTime()),
    ).toBeLessThan(2000);

    jest.useRealTimers();
  });

  it('no aplica ajuste estacional si la planta no tiene speciesId', async () => {
    const plant = makePlant(); // sin speciesId
    mockPlantRepo.findById.mockResolvedValue(plant);
    mockPlantRepo.update.mockResolvedValue(makePlant());
    mockMapper.toResponseDTO.mockReturnValue(makePlantDTO());

    await useCase.execute(PLANT_ID, { wateringFrequency: 10 } as any, USER_ID);

    // speciesRepo.findById no debe ser invocado si plant.speciesId es undefined.
    expect(mockSpeciesRepo.findById).not.toHaveBeenCalled();

    const updateArgs = mockPlantRepo.update.mock.calls[0][1] as any;
    // nextWatering = hoy + 10 días (sin factor)
    const expectedMin = Date.now() + (10 - 1) * 24 * 60 * 60 * 1000;
    const expectedMax = Date.now() + (10 + 1) * 24 * 60 * 60 * 1000;
    expect((updateArgs.nextWatering as Date).getTime()).toBeGreaterThan(expectedMin);
    expect((updateArgs.nextWatering as Date).getTime()).toBeLessThan(expectedMax);
  });
});

// ─── DeletePlantUseCase ────────────────────────────────────────────────────────

describe('DeletePlantUseCase', () => {
  let useCase: DeletePlantUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    useCase = new DeletePlantUseCase(mockPlantRepo as any);
  });

  it('debe llamar a plantRepo.delete con softDelete=true', async () => {
    mockPlantRepo.findById.mockResolvedValue(makePlant());
    mockPlantRepo.delete.mockResolvedValue(undefined);

    await useCase.execute(PLANT_ID, USER_ID);

    expect(mockPlantRepo.delete).toHaveBeenCalledWith(PLANT_ID, true);
  });

  it('debe lanzar NotFoundException si la planta no existe', async () => {
    mockPlantRepo.findById.mockResolvedValue(null);

    await expect(
      useCase.execute('no-existe', USER_ID),
    ).rejects.toThrow(NotFoundException);
  });

  it('debe lanzar UnauthorizedException si el usuario no es el propietario', async () => {
    mockPlantRepo.findById.mockResolvedValue(makePlant({ userId: 'otro-owner' }));

    await expect(
      useCase.execute(PLANT_ID, USER_ID),
    ).rejects.toThrow(UnauthorizedException);
  });

  it('debe lanzar NotFoundException si la planta ya fue eliminada (deletedAt definido)', async () => {
    mockPlantRepo.findById.mockResolvedValue(makePlant({ deletedAt: new Date() }));

    await expect(
      useCase.execute(PLANT_ID, USER_ID),
    ).rejects.toThrow(NotFoundException);
  });
});

// ─── SearchSpeciesUseCase ──────────────────────────────────────────────────────

const mockSpeciesSearchRepo = { search: jest.fn() };
const mockSpeciesMapper     = { toResponseDTO: jest.fn((s: any) => ({ id: s.id, name: s.name })) };

const makeSpecies = (id: string, name = 'Monstera deliciosa') => ({
  id,
  name,
  scientificName: 'Monstera deliciosa',
  isPublic:        true,
  careRequirements: { wateringDays: 7, lightNeed: 'Medium' },
});

describe('SearchSpeciesUseCase', () => {
  let useCase: SearchSpeciesUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    useCase = new SearchSpeciesUseCase(
      mockSpeciesSearchRepo as any,
      mockSpeciesMapper     as any,
    );
  });

  it('debe devolver todas las especies cuando query es vacío', async () => {
    const species = [makeSpecies('s1'), makeSpecies('s2')];
    mockSpeciesSearchRepo.search.mockResolvedValue(species);

    const result = await useCase.execute('');

    expect(mockSpeciesSearchRepo.search).toHaveBeenCalledWith('');
    expect(result).toHaveLength(2);
  });

  it('debe devolver las especies filtradas por query no vacío', async () => {
    const species = [makeSpecies('s1', 'Cactus')];
    mockSpeciesSearchRepo.search.mockResolvedValue(species);

    const result = await useCase.execute('Cactus');

    expect(mockSpeciesSearchRepo.search).toHaveBeenCalledWith('Cactus');
    expect(result).toHaveLength(1);
    expect(result[0].name).toBe('Cactus');
  });

  it('debe recortar espacios del query antes de delegar', async () => {
    mockSpeciesSearchRepo.search.mockResolvedValue([]);

    await useCase.execute('  Pothos  ');

    expect(mockSpeciesSearchRepo.search).toHaveBeenCalledWith('Pothos');
  });

  it('debe devolver array vacío si el repositorio no encuentra resultados', async () => {
    mockSpeciesSearchRepo.search.mockResolvedValue([]);

    const result = await useCase.execute('inexistente');

    expect(result).toHaveLength(0);
  });
});
