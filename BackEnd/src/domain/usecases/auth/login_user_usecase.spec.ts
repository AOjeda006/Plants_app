/**
 * @file login_user_usecase.spec.ts
 * @description Tests unitarios para LoginUserUseCase.
 * Verifica autenticación correcta, credenciales inválidas y
 * que el mensaje de error sea genérico (no revela si el email existe).
 * @module Auth
 * @layer Domain
 */

import 'reflect-metadata';
import { LoginUserUseCase } from './LoginUserUseCase.js';
import { UnauthorizedException } from '../../../core/exceptions/UnauthorizedException.js';
import { User } from '../../entities/User.js';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockUserRepo = {
  findByEmail: jest.fn(),
};

const mockHashService = {
  compare: jest.fn(),
};

const mockJwtService = {
  sign: jest.fn(),
};

// ─── Helper ───────────────────────────────────────────────────────────────────

const makeUser = () =>
  new User({
    id:           'user-id-001',
    name:         'Test User',
    email:        'test@example.com',
    passwordHash: 'hashed_password',
    role:         'user',
    createdAt:    new Date(),
    updatedAt:    new Date(),
  });

// ─── Suite ────────────────────────────────────────────────────────────────────

describe('LoginUserUseCase', () => {
  let useCase: LoginUserUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    useCase = new LoginUserUseCase(
      mockUserRepo as any,
      mockHashService as any,
      mockJwtService as any,
    );
  });

  it('debe devolver token y datos públicos con credenciales válidas', async () => {
    const user = makeUser();
    mockUserRepo.findByEmail.mockResolvedValue(user);
    mockHashService.compare.mockResolvedValue(true);
    mockJwtService.sign.mockReturnValue('valid_jwt');

    const result = await useCase.execute({ email: 'test@example.com', password: 'Pass1234!' });

    expect(result.token).toBe('valid_jwt');
    expect(result.user.email).toBe('test@example.com');
    expect(result.user).not.toHaveProperty('passwordHash');
  });

  it('debe lanzar UnauthorizedException si el email no existe', async () => {
    mockUserRepo.findByEmail.mockResolvedValue(null);

    await expect(
      useCase.execute({ email: 'noexiste@example.com', password: 'cualquiera' }),
    ).rejects.toThrow(UnauthorizedException);
  });

  it('debe lanzar UnauthorizedException si la contraseña es incorrecta', async () => {
    mockUserRepo.findByEmail.mockResolvedValue(makeUser());
    mockHashService.compare.mockResolvedValue(false);

    await expect(
      useCase.execute({ email: 'test@example.com', password: 'mala_contraseña' }),
    ).rejects.toThrow(UnauthorizedException);
  });

  it('el mensaje de error debe ser el mismo tanto si el email no existe como si la contraseña es incorrecta', async () => {
    const EXPECTED_MSG = 'Credenciales incorrectas';

    // Email no existe
    mockUserRepo.findByEmail.mockResolvedValue(null);
    try {
      await useCase.execute({ email: 'noexiste@example.com', password: 'x' });
    } catch (e: any) {
      expect(e.message).toBe(EXPECTED_MSG);
    }

    // Contraseña incorrecta
    mockUserRepo.findByEmail.mockResolvedValue(makeUser());
    mockHashService.compare.mockResolvedValue(false);
    try {
      await useCase.execute({ email: 'test@example.com', password: 'mala' });
    } catch (e: any) {
      expect(e.message).toBe(EXPECTED_MSG);
    }
  });

  it('debe llamar a sign con userId, email y role del usuario', async () => {
    const user = makeUser();
    mockUserRepo.findByEmail.mockResolvedValue(user);
    mockHashService.compare.mockResolvedValue(true);
    mockJwtService.sign.mockReturnValue('token');

    await useCase.execute({ email: 'test@example.com', password: 'Pass1234!' });

    expect(mockJwtService.sign).toHaveBeenCalledWith({
      userId: user.id,
      email:  user.email,
      role:   user.role,
    });
  });
});
