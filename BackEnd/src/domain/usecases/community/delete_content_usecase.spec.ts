/**
 * @file delete_content_usecase.spec.ts
 * @description Tests unitarios para DeleteCommentUseCase y DeletePostUseCase.
 * Verifica soft-delete, validación de ownership, decremento de commentsCount
 * y NotFoundException para elementos inexistentes.
 * @module Community
 * @layer Domain
 */

import 'reflect-metadata';
import { DeleteCommentUseCase } from './DeleteCommentUseCase.js';
import { DeletePostUseCase }    from './DeletePostUseCase.js';
import { NotFoundException }    from '../../../core/exceptions/NotFoundException.js';
import { ForbiddenException }   from '../../../core/exceptions/ForbiddenException.js';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockPostRepo = {
  findById:               jest.fn(),
  softDelete:             jest.fn(),
  incrementCommentsCount: jest.fn(),
};

const mockCommentRepo = {
  findById:    jest.fn(),
  softDelete:  jest.fn(),
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

const POST_ID    = 'post-001';
const COMMENT_ID = 'comment-001';
const USER_ID    = 'user-001';
const OTHER_USER = 'user-999';

const makePost = (userId = USER_ID) => ({
  id:        POST_ID,
  userId,
  content:   'Mi primera planta',
  deletedAt: null,
});

const makeComment = (userId = USER_ID) => ({
  id:        COMMENT_ID,
  postId:    POST_ID,
  userId,
  content:   'Bonita planta!',
  deletedAt: null,
});

// ─── DeleteCommentUseCase ─────────────────────────────────────────────────────

describe('DeleteCommentUseCase', () => {
  let useCase: DeleteCommentUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    mockCommentRepo.softDelete.mockResolvedValue(undefined);
    mockPostRepo.incrementCommentsCount.mockResolvedValue(undefined);
    useCase = new DeleteCommentUseCase(
      mockCommentRepo as any,
      mockPostRepo    as any,
    );
  });

  it('debe hacer soft-delete del comentario y decrementar commentsCount', async () => {
    mockCommentRepo.findById.mockResolvedValue(makeComment());

    await useCase.execute(COMMENT_ID, USER_ID);

    expect(mockCommentRepo.softDelete).toHaveBeenCalledWith(COMMENT_ID);
    expect(mockPostRepo.incrementCommentsCount).toHaveBeenCalledWith(POST_ID, -1);
  });

  it('debe lanzar NotFoundException si el comentario no existe', async () => {
    mockCommentRepo.findById.mockResolvedValue(null);

    await expect(
      useCase.execute('no-existe', USER_ID),
    ).rejects.toThrow(NotFoundException);

    expect(mockCommentRepo.softDelete).not.toHaveBeenCalled();
    expect(mockPostRepo.incrementCommentsCount).not.toHaveBeenCalled();
  });

  it('debe lanzar NotFoundException si el comentario ya fue eliminado', async () => {
    const deleted = { ...makeComment(), deletedAt: new Date() };
    mockCommentRepo.findById.mockResolvedValue(deleted);

    await expect(
      useCase.execute(COMMENT_ID, USER_ID),
    ).rejects.toThrow(NotFoundException);
  });

  it('debe lanzar ForbiddenException si el usuario no es el autor', async () => {
    mockCommentRepo.findById.mockResolvedValue(makeComment());

    await expect(
      useCase.execute(COMMENT_ID, OTHER_USER),
    ).rejects.toThrow(ForbiddenException);

    expect(mockCommentRepo.softDelete).not.toHaveBeenCalled();
    expect(mockPostRepo.incrementCommentsCount).not.toHaveBeenCalled();
  });
});

// ─── DeletePostUseCase ───────────────────────────────────────────────────────

describe('DeletePostUseCase', () => {
  let useCase: DeletePostUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    mockPostRepo.softDelete.mockResolvedValue(undefined);
    useCase = new DeletePostUseCase(mockPostRepo as any);
  });

  it('debe hacer soft-delete del post propio', async () => {
    mockPostRepo.findById.mockResolvedValue(makePost());

    await useCase.execute(POST_ID, USER_ID);

    expect(mockPostRepo.softDelete).toHaveBeenCalledWith(POST_ID);
  });

  it('debe lanzar NotFoundException si el post no existe', async () => {
    mockPostRepo.findById.mockResolvedValue(null);

    await expect(
      useCase.execute('no-existe', USER_ID),
    ).rejects.toThrow(NotFoundException);

    expect(mockPostRepo.softDelete).not.toHaveBeenCalled();
  });

  it('debe lanzar ForbiddenException si el usuario no es el autor', async () => {
    mockPostRepo.findById.mockResolvedValue(makePost());

    await expect(
      useCase.execute(POST_ID, OTHER_USER),
    ).rejects.toThrow(ForbiddenException);

    expect(mockPostRepo.softDelete).not.toHaveBeenCalled();
  });
});
