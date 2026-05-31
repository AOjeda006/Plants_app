/**
 * @file register_user_usecase.spec.ts
 * @description Tests unitarios para RegisterUserUseCase.
 * Mockea IUserRepository, HashService y JwtService.
 * @module Auth
 * @layer Domain
 */

import 'reflect-metadata';
import { RegisterUserUseCase } from './RegisterUserUseCase.js';
import { HttpException } from '../../../core/exceptions/HttpException.js';
import { User } from '../../entities/User.js';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockUserRepo = {
  findByEmail: jest.fn(),
  create:      jest.fn(),
};

const mockHashService = {
  hash:    jest.fn(),
  compare: jest.fn(),
};

const mockJwtService = {
  sign:   jest.fn(),
  verify: jest.fn(),
};

// ─── Helper: usuario de ejemplo ───────────────────────────────────────────────

const makeUser = (overrides = {}) =>
  new User({
    id:           'user-id-001',
    name:         'Test User',
    email:        'test@example.com',
    passwordHash: 'hashed_password',
    role:         'user',
    createdAt:    new Date(),
    updatedAt:    new Date(),
    ...overrides,
  });

// ─── Suite ────────────────────────────────────────────────────────────────────

describe('RegisterUserUseCase', () => {
  let useCase: RegisterUserUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    useCase = new RegisterUserUseCase(
      mockUserRepo as any,
      mockHashService as any,
      mockJwtService as any,
    );
  });

  it('debe registrar un nuevo usuario y devolver token + datos públicos', async () => {
    const dto = { name: 'Test User', email: 'test@example.com', password: 'Pass1234!' };

    mockUserRepo.findByEmail.mockResolvedValue(null);
    mockHashService.hash.mockResolvedValue('hashed_password');
    const createdUser = makeUser();
    mockUserRepo.create.mockResolvedValue(createdUser);
    mockJwtService.sign.mockReturnValue('jwt_token_abc');

    const result = await useCase.execute(dto);

    expect(result.token).toBe('jwt_token_abc');
    expect(result.user).not.toHaveProperty('passwordHash');
    expect(result.user).not.toHaveProperty('fcmToken');
    expect(mockUserRepo.create).toHaveBeenCalledTimes(1);
    expect(mockHashService.hash).toHaveBeenCalledWith(dto.password);
  });

  it('debe lanzar HttpException 409 si el email ya está registrado', async () => {
    mockUserRepo.findByEmail.mockResolvedValue(makeUser());

    await expect(
      useCase.execute({ name: 'A', email: 'existing@example.com', password: 'Pass!' }),
    ).rejects.toThrow(HttpException);

    await expect(
      useCase.execute({ name: 'A', email: 'existing@example.com', password: 'Pass!' }),
    ).rejects.toMatchObject({ statusCode: 409 });
  });

  it('debe convertir el email a minúsculas antes de persistir', async () => {
    const dto = { name: 'User', email: 'USER@EXAMPLE.COM', password: 'Pass1234!' };

    mockUserRepo.findByEmail.mockResolvedValue(null);
    mockHashService.hash.mockResolvedValue('hash');
    mockUserRepo.create.mockResolvedValue(makeUser({ email: 'user@example.com' }));
    mockJwtService.sign.mockReturnValue('token');

    await useCase.execute(dto);

    const createCall = mockUserRepo.create.mock.calls[0][0] as User;
    expect(createCall.email).toBe('user@example.com');
  });
});
