/**
 * @file user_usecase.spec.ts
 * @description Tests unitarios para ChangePasswordUseCase y UpdateUserPreferencesUseCase.
 * Verifica cambio correcto de contraseña, contraseña actual incorrecta y merge de preferencias.
 * @module User
 * @layer Domain
 */

import 'reflect-metadata';
import { ChangePasswordUseCase }          from './ChangePasswordUseCase.js';
import { UpdateUserPreferencesUseCase }   from './UpdateUserPreferencesUseCase.js';
import { NotFoundException }              from '../../../core/exceptions/NotFoundException.js';
import { HttpException }                  from '../../../core/exceptions/HttpException.js';
import { User }                           from '../../entities/User.js';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockUserRepo = {
  findById: jest.fn(),
  update:   jest.fn(),
};

const mockHashService = {
  compare: jest.fn(),
  hash:    jest.fn(),
};

// ─── Helper ───────────────────────────────────────────────────────────────────

const makeUser = (overrides = {}) =>
  new User({
    id:           'user-001',
    name:         'Test User',
    email:        'test@example.com',
    passwordHash: 'hashed_old_password',
    preferences:  {
      appearInChatSearch:        true,
      considerWeatherByDefault:  false,
      isPrivate:                 false,
    },
    createdAt:    new Date(),
    updatedAt:    new Date(),
    ...overrides,
  });

// ─── ChangePasswordUseCase ────────────────────────────────────────────────────

describe('ChangePasswordUseCase', () => {
  let useCase: ChangePasswordUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    useCase = new ChangePasswordUseCase(mockUserRepo as any, mockHashService as any);
  });

  it('debe actualizar la contraseña correctamente', async () => {
    mockUserRepo.findById.mockResolvedValue(makeUser());
    mockHashService.compare.mockResolvedValue(true);
    mockHashService.hash.mockResolvedValue('hashed_new_password');
    mockUserRepo.update.mockResolvedValue(makeUser({ passwordHash: 'hashed_new_password' }));

    await useCase.execute('user-001', 'oldPass123!', 'newPass456!');

    expect(mockHashService.hash).toHaveBeenCalledWith('newPass456!');
    expect(mockUserRepo.update).toHaveBeenCalledWith('user-001', {
      passwordHash: 'hashed_new_password',
    });
  });

  it('debe lanzar HttpException 401 si la contraseña actual es incorrecta', async () => {
    mockUserRepo.findById.mockResolvedValue(makeUser());
    mockHashService.compare.mockResolvedValue(false);

    await expect(
      useCase.execute('user-001', 'wrongPass!', 'newPass456!'),
    ).rejects.toThrow(HttpException);

    await expect(
      useCase.execute('user-001', 'wrongPass!', 'newPass456!'),
    ).rejects.toMatchObject({ statusCode: 401 });
  });

  it('debe lanzar NotFoundException si el usuario no existe', async () => {
    mockUserRepo.findById.mockResolvedValue(null);

    await expect(
      useCase.execute('no-existe', 'pass', 'newpass'),
    ).rejects.toThrow(NotFoundException);
  });

  it('no debe actualizar la contraseña si la verificación falla', async () => {
    mockUserRepo.findById.mockResolvedValue(makeUser());
    mockHashService.compare.mockResolvedValue(false);

    try {
      await useCase.execute('user-001', 'wrong', 'new');
    } catch {
      // esperado
    }

    expect(mockUserRepo.update).not.toHaveBeenCalled();
  });
});

// ─── UpdateUserPreferencesUseCase ─────────────────────────────────────────────

describe('UpdateUserPreferencesUseCase', () => {
  let useCase: UpdateUserPreferencesUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    useCase = new UpdateUserPreferencesUseCase(mockUserRepo as any);
  });

  it('debe actualizar las preferencias enviadas y preservar las no enviadas (merge)', async () => {
    const user = makeUser();
    mockUserRepo.findById.mockResolvedValue(user);
    const updatedUser = makeUser({
      preferences: {
        appearInChatSearch:        false, // cambiado
        considerWeatherByDefault:  false, // preservado
        isPrivate:                 false, // preservado
      },
    });
    mockUserRepo.update.mockResolvedValue(updatedUser);

    const dto = { appearInChatSearch: false };
    const result = await useCase.execute('user-001', dto);

    // El update debe llamarse con el merge de preferencias
    const updateCall = mockUserRepo.update.mock.calls[0][1];
    expect(updateCall.preferences.appearInChatSearch).toBe(false);
    expect(updateCall.preferences.isPrivate).toBe(false);         // preservado
    expect(result.preferences.appearInChatSearch).toBe(false);
  });

  it('debe lanzar NotFoundException si el usuario no existe', async () => {
    mockUserRepo.findById.mockResolvedValue(null);

    await expect(
      useCase.execute('no-existe', {}),
    ).rejects.toThrow(NotFoundException);
  });

  it('debe devolver UserResponseDTO sin passwordHash ni fcmToken', async () => {
    const user = makeUser();
    mockUserRepo.findById.mockResolvedValue(user);
    mockUserRepo.update.mockResolvedValue(user);

    const result = await useCase.execute('user-001', {});

    expect(result).not.toHaveProperty('passwordHash');
    expect(result).not.toHaveProperty('fcmToken');
    expect(result).toHaveProperty('id');
    expect(result).toHaveProperty('preferences');
  });

  it('no debe sobreescribir preferencias no enviadas en el dto', async () => {
    const user = makeUser({
      preferences: {
        appearInChatSearch:        false, // ya está en false
        considerWeatherByDefault:  true,
        isPrivate:                 true,  // establecido explícitamente
      },
    });
    mockUserRepo.findById.mockResolvedValue(user);
    mockUserRepo.update.mockResolvedValue(user);

    // Solo se envía considerWeatherByDefault
    const dto = { considerWeatherByDefault: false };
    await useCase.execute('user-001', dto);

    const updateCall = mockUserRepo.update.mock.calls[0][1];
    // Todos los campos no enviados deben preservarse
    expect(updateCall.preferences.appearInChatSearch).toBe(false);
    expect(updateCall.preferences.considerWeatherByDefault).toBe(false);
    expect(updateCall.preferences.isPrivate).toBe(true); // preservado
  });
});
