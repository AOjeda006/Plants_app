/**
 * @file refresh_token_usecase.spec.ts
 * @description Tests unitarios para RefreshTokenUseCase. Cubre los 4 casos
 * críticos:
 *  - Refresh con userId válido → token nuevo + usuario.
 *  - Refresh con userId inexistente → NotFoundException (404).
 *  - Refresh con usuario soft-deleted → NotFoundException (findById ya filtra).
 *  - El nuevo token se firma con userId, email y role frescos del usuario.
 * Los casos "token expirado" y "token inválido" NO se prueban aquí porque los
 * resuelve el AuthMiddleware antes de llegar al use case (UnauthorizedException
 * 401 cuando jwt.verify falla).
 * @module Auth
 * @layer Domain
 */

import 'reflect-metadata';
import { RefreshTokenUseCase } from './RefreshTokenUseCase.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';
import { User } from '../../entities/User.js';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockUserRepo = {
  findById: jest.fn(),
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

describe('RefreshTokenUseCase', () => {
  let useCase: RefreshTokenUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    useCase = new RefreshTokenUseCase(
      mockUserRepo as any,
      mockJwtService as any,
    );
  });

  it('devuelve un token nuevo y los datos del usuario cuando éste sigue activo', async () => {
    const user = makeUser();
    mockUserRepo.findById.mockResolvedValue(user);
    mockJwtService.sign.mockReturnValue('new_jwt_token');

    const result = await useCase.execute('user-id-001');

    expect(result.token).toBe('new_jwt_token');
    expect(result.user.email).toBe('test@example.com');
    expect(result.user).not.toHaveProperty('passwordHash');
  });

  it('lanza NotFoundException si el usuario no existe (findById devuelve null)', async () => {
    mockUserRepo.findById.mockResolvedValue(null);

    await expect(useCase.execute('non-existent-id')).rejects.toThrow(NotFoundException);
    expect(mockJwtService.sign).not.toHaveBeenCalled();
  });

  it('lanza NotFoundException si el usuario fue soft-deleted (findById filtra deletedAt)', async () => {
    // El repositorio implementa el filtro `deletedAt: null` internamente,
    // por lo que devuelve null ante un usuario soft-deleted aunque el _id
    // siga existiendo en la colección.
    mockUserRepo.findById.mockResolvedValue(null);

    await expect(useCase.execute('soft-deleted-id')).rejects.toThrow(NotFoundException);
  });

  it('firma el nuevo token con userId, email y role frescos del usuario', async () => {
    const user = makeUser();
    mockUserRepo.findById.mockResolvedValue(user);
    mockJwtService.sign.mockReturnValue('token');

    await useCase.execute('user-id-001');

    expect(mockJwtService.sign).toHaveBeenCalledWith({
      userId: user.id,
      email:  user.email,
      role:   user.role,
    });
  });
});
