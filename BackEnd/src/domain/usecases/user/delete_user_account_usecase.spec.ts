/**
 * @file delete_user_account_usecase.spec.ts
 * @description Tests unitarios para DeleteUserAccountUseCase.
 * Verifica: eliminación de posts/comentarios con preserveContent=false,
 * conservación de contenido con preserveContent=true,
 * rechazo por contraseña incorrecta y usuario inexistente.
 * @module User
 * @layer Domain
 */

import 'reflect-metadata';
import { DeleteUserAccountUseCase } from './DeleteUserAccountUseCase.js';
import { NotFoundException }        from '../../../core/exceptions/NotFoundException.js';
import { HttpException }            from '../../../core/exceptions/HttpException.js';
import { User }                     from '../../entities/User.js';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockUserRepo = {
  findById: jest.fn(),
  delete:   jest.fn(),
};

const mockHashService = {
  compare: jest.fn(),
};

const mockPostRepo = {
  softDeleteByUserId:     jest.fn(),
  incrementCommentsCount: jest.fn(),
};

const mockCommentRepo = {
  findActiveByUserId: jest.fn(),
  softDeleteByUserId: jest.fn(),
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

const makeUser = () =>
  new User({
    id:           'user-001',
    name:         'Test User',
    email:        'test@example.com',
    passwordHash: 'hashed_password',
    preferences:  {
      appearInChatSearch:        true,
      considerWeatherByDefault:  false,
      isPrivate:                 false,
    },
    createdAt: new Date('2026-01-01T00:00:00.000Z'),
    updatedAt: new Date('2026-01-01T00:00:00.000Z'),
  });

// ─── Suite ────────────────────────────────────────────────────────────────────

describe('DeleteUserAccountUseCase', () => {
  let useCase: DeleteUserAccountUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    useCase = new DeleteUserAccountUseCase(
      mockUserRepo    as any,
      mockHashService as any,
      mockPostRepo    as any,
      mockCommentRepo as any,
    );
  });

  // ── preserveContent=false (comportamiento por defecto) ───────────────────────

  describe('preserveContent=false (comportamiento por defecto)', () => {
    test('debe eliminar posts y comentarios del usuario antes de borrar la cuenta', async () => {
      mockUserRepo.findById.mockResolvedValue(makeUser());
      mockHashService.compare.mockResolvedValue(true);
      // Sin comentarios activos: el decremento de commentsCount no se llama.
      mockCommentRepo.findActiveByUserId.mockResolvedValue([]);
      mockPostRepo.softDeleteByUserId.mockResolvedValue(undefined);
      mockCommentRepo.softDeleteByUserId.mockResolvedValue(undefined);
      mockUserRepo.delete.mockResolvedValue(undefined);

      await useCase.execute('user-001', 'correct_password');

      expect(mockPostRepo.softDeleteByUserId).toHaveBeenCalledWith('user-001');
      expect(mockCommentRepo.softDeleteByUserId).toHaveBeenCalledWith('user-001');
      expect(mockUserRepo.delete).toHaveBeenCalledWith('user-001', true);
    });

    test('llama a softDeleteByUserId incluso cuando preserveContent=false explícito', async () => {
      mockUserRepo.findById.mockResolvedValue(makeUser());
      mockHashService.compare.mockResolvedValue(true);
      mockCommentRepo.findActiveByUserId.mockResolvedValue([]);
      mockPostRepo.softDeleteByUserId.mockResolvedValue(undefined);
      mockCommentRepo.softDeleteByUserId.mockResolvedValue(undefined);
      mockUserRepo.delete.mockResolvedValue(undefined);

      await useCase.execute('user-001', 'correct_password', false);

      expect(mockPostRepo.softDeleteByUserId).toHaveBeenCalledTimes(1);
      expect(mockCommentRepo.softDeleteByUserId).toHaveBeenCalledTimes(1);
    });

    test('decrementa commentsCount para cada comentario activo del usuario', async () => {
      mockUserRepo.findById.mockResolvedValue(makeUser());
      mockHashService.compare.mockResolvedValue(true);
      // Usuario con 2 comentarios en posts distintos.
      mockCommentRepo.findActiveByUserId.mockResolvedValue([
        { id: 'c1', postId: 'post-001', userId: 'user-001', content: 'Hola', createdAt: new Date() },
        { id: 'c2', postId: 'post-002', userId: 'user-001', content: 'Adios', createdAt: new Date() },
      ]);
      mockPostRepo.incrementCommentsCount.mockResolvedValue(undefined);
      mockPostRepo.softDeleteByUserId.mockResolvedValue(undefined);
      mockCommentRepo.softDeleteByUserId.mockResolvedValue(undefined);
      mockUserRepo.delete.mockResolvedValue(undefined);

      await useCase.execute('user-001', 'correct_password');

      expect(mockPostRepo.incrementCommentsCount).toHaveBeenCalledTimes(2);
      expect(mockPostRepo.incrementCommentsCount).toHaveBeenCalledWith('post-001', -1);
      expect(mockPostRepo.incrementCommentsCount).toHaveBeenCalledWith('post-002', -1);
    });

    test('el orden de ejecución es: decremento comentarios → softDelete posts → softDelete comentarios → delete usuario', async () => {
      const callOrder: string[] = [];
      mockUserRepo.findById.mockResolvedValue(makeUser());
      mockHashService.compare.mockResolvedValue(true);
      mockCommentRepo.findActiveByUserId.mockResolvedValue([]);
      mockPostRepo.softDeleteByUserId.mockImplementation(async () => { callOrder.push('posts'); });
      mockCommentRepo.softDeleteByUserId.mockImplementation(async () => { callOrder.push('comments'); });
      mockUserRepo.delete.mockImplementation(async () => { callOrder.push('user'); });

      await useCase.execute('user-001', 'correct_password');

      expect(callOrder).toEqual(['posts', 'comments', 'user']);
    });
  });

  // ── preserveContent=true (conservar publicaciones) ───────────────────────────

  describe('preserveContent=true (conservar publicaciones)', () => {
    test('NO debe eliminar posts ni comentarios cuando preserveContent=true', async () => {
      mockUserRepo.findById.mockResolvedValue(makeUser());
      mockHashService.compare.mockResolvedValue(true);
      mockUserRepo.delete.mockResolvedValue(undefined);

      await useCase.execute('user-001', 'correct_password', true);

      expect(mockPostRepo.softDeleteByUserId).not.toHaveBeenCalled();
      expect(mockCommentRepo.softDeleteByUserId).not.toHaveBeenCalled();
    });

    test('debe eliminar la cuenta del usuario aunque se conserven posts y comentarios', async () => {
      mockUserRepo.findById.mockResolvedValue(makeUser());
      mockHashService.compare.mockResolvedValue(true);
      mockUserRepo.delete.mockResolvedValue(undefined);

      await useCase.execute('user-001', 'correct_password', true);

      // La cuenta se borra con soft-delete (true = soft-delete flag).
      expect(mockUserRepo.delete).toHaveBeenCalledWith('user-001', true);
    });
  });

  // ── contraseña incorrecta ─────────────────────────────────────────────────────

  describe('contraseña incorrecta', () => {
    test('debe lanzar HttpException cuando la contraseña no coincide', async () => {
      mockUserRepo.findById.mockResolvedValue(makeUser());
      mockHashService.compare.mockResolvedValue(false);

      await expect(
        useCase.execute('user-001', 'wrong_password'),
      ).rejects.toThrow(HttpException);
    });

    test('el HttpException lanzado debe tener statusCode 401', async () => {
      mockUserRepo.findById.mockResolvedValue(makeUser());
      mockHashService.compare.mockResolvedValue(false);

      try {
        await useCase.execute('user-001', 'wrong_password');
        fail('Debería haber lanzado una excepción');
      } catch (error) {
        expect(error).toBeInstanceOf(HttpException);
        expect((error as HttpException).statusCode).toBe(401);
      }
    });

    test('no debe llamar a softDeleteByUserId ni delete si la contraseña es incorrecta', async () => {
      mockUserRepo.findById.mockResolvedValue(makeUser());
      mockHashService.compare.mockResolvedValue(false);

      await expect(
        useCase.execute('user-001', 'wrong_password'),
      ).rejects.toThrow();

      expect(mockCommentRepo.findActiveByUserId).not.toHaveBeenCalled();
      expect(mockPostRepo.softDeleteByUserId).not.toHaveBeenCalled();
      expect(mockCommentRepo.softDeleteByUserId).not.toHaveBeenCalled();
      expect(mockUserRepo.delete).not.toHaveBeenCalled();
    });
  });

  // ── usuario no encontrado ─────────────────────────────────────────────────────

  describe('usuario no encontrado', () => {
    test('debe lanzar NotFoundException si el usuario no existe en la BD', async () => {
      mockUserRepo.findById.mockResolvedValue(null);

      await expect(
        useCase.execute('no-existe', 'any_password'),
      ).rejects.toThrow(NotFoundException);
    });

    test('no debe comparar la contraseña si el usuario no existe', async () => {
      mockUserRepo.findById.mockResolvedValue(null);

      await expect(
        useCase.execute('no-existe', 'any_password'),
      ).rejects.toThrow();

      expect(mockHashService.compare).not.toHaveBeenCalled();
    });

    test('no debe llamar a delete si el usuario no existe', async () => {
      mockUserRepo.findById.mockResolvedValue(null);

      await expect(
        useCase.execute('no-existe', 'any_password'),
      ).rejects.toThrow();

      expect(mockUserRepo.delete).not.toHaveBeenCalled();
    });
  });
});
