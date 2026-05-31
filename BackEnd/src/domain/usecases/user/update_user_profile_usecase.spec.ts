/**
 * @file update_user_profile_usecase.spec.ts
 * @description Tests unitarios para UpdateUserProfileUseCase.
 * Verifica: persistencia de bannerPhoto, actualización selectiva de campos
 * y comportamiento ante usuario inexistente.
 * @module User
 * @layer Domain
 */

import 'reflect-metadata';
import { UpdateUserProfileUseCase } from './UpdateUserProfileUseCase.js';
import { NotFoundException }        from '../../../core/exceptions/NotFoundException.js';
import { User }                     from '../../entities/User.js';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockUserRepo = {
  update: jest.fn(),
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

const makeUser = (overrides: Record<string, unknown> = {}) =>
  new User({
    id:           'user-001',
    name:         'Test User',
    email:        'test@example.com',
    passwordHash: 'hash',
    preferences:  {
      appearInChatSearch:        true,
      considerWeatherByDefault:  false,
      isPrivate:                 false,
    },
    createdAt: new Date('2026-03-17T00:00:00.000Z'),
    updatedAt: new Date('2026-03-17T00:00:00.000Z'),
    ...overrides,
  });

// ─── Suite ────────────────────────────────────────────────────────────────────

describe('UpdateUserProfileUseCase', () => {
  let useCase: UpdateUserProfileUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    useCase = new UpdateUserProfileUseCase(mockUserRepo as any);
  });

  it('debe persistir bannerPhoto cuando se incluye en el DTO', async () => {
    const updatedUser = makeUser({ bannerPhoto: 'https://cdn.example.com/banner.jpg' });
    mockUserRepo.update.mockResolvedValue(updatedUser);

    const dto = { bannerPhoto: 'https://cdn.example.com/banner.jpg' };
    const result = await useCase.execute('user-001', dto);

    expect(mockUserRepo.update).toHaveBeenCalledWith(
      'user-001',
      expect.objectContaining({ bannerPhoto: 'https://cdn.example.com/banner.jpg' }),
    );
    expect(result.bannerPhoto).toBe('https://cdn.example.com/banner.jpg');
  });

  it('NO debe incluir bannerPhoto en el update si no se envía en el DTO', async () => {
    const updatedUser = makeUser({ name: 'Nuevo Nombre' });
    mockUserRepo.update.mockResolvedValue(updatedUser);

    const dto = { name: 'Nuevo Nombre' };
    await useCase.execute('user-001', dto);

    const updateArg = mockUserRepo.update.mock.calls[0][1];
    expect(updateArg).not.toHaveProperty('bannerPhoto');
  });

  it('debe persistir name y bio cuando se envían en el DTO', async () => {
    const updatedUser = makeUser({ name: 'Nuevo Nombre', bio: 'Mi bio' });
    mockUserRepo.update.mockResolvedValue(updatedUser);

    const dto = { name: 'Nuevo Nombre', bio: 'Mi bio' };
    await useCase.execute('user-001', dto);

    expect(mockUserRepo.update).toHaveBeenCalledWith(
      'user-001',
      expect.objectContaining({ name: 'Nuevo Nombre', bio: 'Mi bio' }),
    );
  });

  it('debe incluir solo los campos definidos en el DTO (no sobreescribir con undefined)', async () => {
    const updatedUser = makeUser({ name: 'Solo Nombre' });
    mockUserRepo.update.mockResolvedValue(updatedUser);

    const dto = { name: 'Solo Nombre' };
    await useCase.execute('user-001', dto);

    const updateArg = mockUserRepo.update.mock.calls[0][1];
    // Solo name debe estar presente; el resto de campos no se deben enviar.
    expect(Object.keys(updateArg)).toEqual(['name']);
  });

  it('debe devolver UserResponseDTO sin passwordHash ni fcmToken', async () => {
    const updatedUser = makeUser();
    mockUserRepo.update.mockResolvedValue(updatedUser);

    const result = await useCase.execute('user-001', { name: 'Test' });

    expect(result).not.toHaveProperty('passwordHash');
    expect(result).not.toHaveProperty('fcmToken');
    expect(result).toHaveProperty('id');
    expect(result).toHaveProperty('name');
  });

  it('debe lanzar NotFoundException si userRepo.update lanza NotFoundException', async () => {
    mockUserRepo.update.mockRejectedValue(new NotFoundException('User', 'no-existe'));

    await expect(
      useCase.execute('no-existe', { name: 'Nuevo' }),
    ).rejects.toThrow(NotFoundException);
  });

  it('debe persistir locationLat y locationLon cuando se incluyen en el DTO', async () => {
    const updatedUser = makeUser({ locationLat: 40.4168, locationLon: -3.7038, location: 'Madrid, España' });
    mockUserRepo.update.mockResolvedValue(updatedUser);

    const dto = { location: 'Madrid, España', locationLat: 40.4168, locationLon: -3.7038 };
    await useCase.execute('user-001', dto);

    expect(mockUserRepo.update).toHaveBeenCalledWith(
      'user-001',
      expect.objectContaining({
        location:    'Madrid, España',
        locationLat: 40.4168,
        locationLon: -3.7038,
      }),
    );
  });
});
