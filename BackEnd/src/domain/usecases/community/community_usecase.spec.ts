/**
 * @file community_usecase.spec.ts
 * @description Tests unitarios para LikePostUseCase, UnlikePostUseCase y CreateCommentUseCase.
 * Verifica toggle de likes (ConflictException si duplicado), NotFoundException para inexistentes
 * y creación correcta de comentarios.
 * @module Community
 * @layer Domain
 */

import 'reflect-metadata';
import { LikePostUseCase }      from './LikePostUseCase.js';
import { UnlikePostUseCase }    from './UnlikePostUseCase.js';
import { CreateCommentUseCase } from './CreateCommentUseCase.js';
import { NotFoundException }    from '../../../core/exceptions/NotFoundException.js';
import { ConflictException }    from '../../../core/exceptions/ConflictException.js';
import { User }                 from '../../entities/User.js';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockPostRepo = {
  findById:              jest.fn(),
  incrementLikesCount:   jest.fn(),
  incrementCommentsCount: jest.fn(),
};

const mockLikeRepo = {
  findByPostAndUser: jest.fn(),
  create:            jest.fn(),
  delete:            jest.fn(),
};

const mockCommentRepo = {
  create: jest.fn(),
};

const mockUserRepo = {
  findById: jest.fn(),
};

const mockCommentMapper = {
  toResponseDTO: jest.fn(),
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

const POST_ID = 'post-001';
const USER_ID = 'user-001';

const makePost = () => ({ id: POST_ID, authorId: 'author-001', likesCount: 0 });

const makeUser = () =>
  new User({
    id: USER_ID, name: 'Autor', email: 'a@b.com', passwordHash: 'hash',
    createdAt: new Date(), updatedAt: new Date(),
  });

const makeComment = () => ({ id: 'comment-001', postId: POST_ID, authorId: USER_ID, content: 'Genial!' });

const makeCommentDTO = () => ({ id: 'comment-001', content: 'Genial!', authorName: 'Autor' });

// ─── LikePostUseCase ─────────────────────────────────────────────────────────

describe('LikePostUseCase', () => {
  let useCase: LikePostUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    mockPostRepo.incrementLikesCount.mockResolvedValue(undefined);
    mockLikeRepo.create.mockResolvedValue(undefined);
    useCase = new LikePostUseCase(mockPostRepo as any, mockLikeRepo as any);
  });

  it('debe crear el like e incrementar el contador', async () => {
    mockPostRepo.findById.mockResolvedValue(makePost());
    mockLikeRepo.findByPostAndUser.mockResolvedValue(null);

    await useCase.execute(POST_ID, USER_ID);

    expect(mockLikeRepo.create).toHaveBeenCalledWith(POST_ID, USER_ID);
    expect(mockPostRepo.incrementLikesCount).toHaveBeenCalledWith(POST_ID, 1);
  });

  it('debe lanzar ConflictException si el usuario ya dio like al post', async () => {
    mockPostRepo.findById.mockResolvedValue(makePost());
    mockLikeRepo.findByPostAndUser.mockResolvedValue({ id: 'like-001' });

    await expect(useCase.execute(POST_ID, USER_ID)).rejects.toThrow(ConflictException);

    expect(mockLikeRepo.create).not.toHaveBeenCalled();
    expect(mockPostRepo.incrementLikesCount).not.toHaveBeenCalled();
  });

  it('debe lanzar NotFoundException si el post no existe', async () => {
    mockPostRepo.findById.mockResolvedValue(null);

    await expect(useCase.execute('no-existe', USER_ID)).rejects.toThrow(NotFoundException);
  });
});

// ─── UnlikePostUseCase ────────────────────────────────────────────────────────

describe('UnlikePostUseCase', () => {
  let useCase: UnlikePostUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    mockPostRepo.incrementLikesCount.mockResolvedValue(undefined);
    mockLikeRepo.delete.mockResolvedValue(undefined);
    useCase = new UnlikePostUseCase(mockPostRepo as any, mockLikeRepo as any);
  });

  it('debe eliminar el like y decrementar el contador', async () => {
    mockPostRepo.findById.mockResolvedValue(makePost());
    mockLikeRepo.findByPostAndUser.mockResolvedValue({ id: 'like-001' });

    await useCase.execute(POST_ID, USER_ID);

    expect(mockLikeRepo.delete).toHaveBeenCalledWith(POST_ID, USER_ID);
    expect(mockPostRepo.incrementLikesCount).toHaveBeenCalledWith(POST_ID, -1);
  });

  it('debe ser idempotente: no hace nada si el like no existe', async () => {
    mockPostRepo.findById.mockResolvedValue(makePost());
    mockLikeRepo.findByPostAndUser.mockResolvedValue(null);

    await useCase.execute(POST_ID, USER_ID);

    expect(mockLikeRepo.delete).not.toHaveBeenCalled();
    expect(mockPostRepo.incrementLikesCount).not.toHaveBeenCalled();
  });

  it('debe lanzar NotFoundException si el post no existe', async () => {
    mockPostRepo.findById.mockResolvedValue(null);

    await expect(useCase.execute('no-existe', USER_ID)).rejects.toThrow(NotFoundException);
  });
});

// ─── Toggle de likes (secuencia unlike → like) ───────────────────────────────

describe('Toggle de likes — secuencia unlike → like', () => {
  let likeUseCase:   LikePostUseCase;
  let unlikeUseCase: UnlikePostUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    mockPostRepo.incrementLikesCount.mockResolvedValue(undefined);
    mockLikeRepo.create.mockResolvedValue(undefined);
    mockLikeRepo.delete.mockResolvedValue(undefined);
    likeUseCase   = new LikePostUseCase(mockPostRepo as any, mockLikeRepo as any);
    unlikeUseCase = new UnlikePostUseCase(mockPostRepo as any, mockLikeRepo as any);
  });

  it('debe permitir dar like de nuevo después de hacer unlike', async () => {
    mockPostRepo.findById.mockResolvedValue(makePost());

    // Paso 1: unlike — el like existe, se elimina.
    mockLikeRepo.findByPostAndUser.mockResolvedValueOnce({ id: 'like-001' });
    await unlikeUseCase.execute(POST_ID, USER_ID);
    expect(mockLikeRepo.delete).toHaveBeenCalledWith(POST_ID, USER_ID);

    // Paso 2: like de nuevo — ya no existe, se crea sin error.
    mockLikeRepo.findByPostAndUser.mockResolvedValueOnce(null);
    await expect(likeUseCase.execute(POST_ID, USER_ID)).resolves.toBeUndefined();
    expect(mockLikeRepo.create).toHaveBeenCalledWith(POST_ID, USER_ID);
  });

  it('debe lanzar ConflictException al dar like dos veces seguidas', async () => {
    mockPostRepo.findById.mockResolvedValue(makePost());
    mockLikeRepo.findByPostAndUser
      .mockResolvedValueOnce(null)               // primera vez: no existe → OK
      .mockResolvedValueOnce({ id: 'like-001' }); // segunda vez: ya existe → 409

    // Primera llamada: debe resolver sin error.
    await expect(likeUseCase.execute(POST_ID, USER_ID)).resolves.toBeUndefined();

    // Segunda llamada sobre el mismo post: debe lanzar ConflictException.
    await expect(likeUseCase.execute(POST_ID, USER_ID)).rejects.toThrow(ConflictException);
    expect(mockLikeRepo.create).toHaveBeenCalledTimes(1);
  });

  it('secuencia like→unlike→like produce exactamente +1, -1, +1 en incrementLikesCount', async () => {
    mockPostRepo.findById.mockResolvedValue(makePost());

    // like: el like no existe → se crea
    mockLikeRepo.findByPostAndUser.mockResolvedValueOnce(null);
    await likeUseCase.execute(POST_ID, USER_ID);
    expect(mockPostRepo.incrementLikesCount).toHaveBeenLastCalledWith(POST_ID, 1);

    // unlike: el like existe → se elimina
    mockLikeRepo.findByPostAndUser.mockResolvedValueOnce({ id: 'like-001' });
    await unlikeUseCase.execute(POST_ID, USER_ID);
    expect(mockPostRepo.incrementLikesCount).toHaveBeenLastCalledWith(POST_ID, -1);

    // like de nuevo: no existe → se crea
    mockLikeRepo.findByPostAndUser.mockResolvedValueOnce(null);
    await likeUseCase.execute(POST_ID, USER_ID);
    expect(mockPostRepo.incrementLikesCount).toHaveBeenLastCalledWith(POST_ID, 1);

    // En total: 3 llamadas a incrementLikesCount (no 4 ni más).
    expect(mockPostRepo.incrementLikesCount).toHaveBeenCalledTimes(3);
  });
});

// ─── CreateCommentUseCase ─────────────────────────────────────────────────────

describe('CreateCommentUseCase', () => {
  let useCase: CreateCommentUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    mockPostRepo.incrementCommentsCount.mockResolvedValue(undefined);
    useCase = new CreateCommentUseCase(
      mockCommentRepo     as any,
      mockPostRepo        as any,
      mockUserRepo        as any,
      mockCommentMapper   as any,
    );
  });

  it('debe crear el comentario, incrementar el contador y devolver CommentResponseDTO', async () => {
    mockPostRepo.findById.mockResolvedValue(makePost());
    mockUserRepo.findById.mockResolvedValue(makeUser());
    mockCommentRepo.create.mockResolvedValue(makeComment());
    mockCommentMapper.toResponseDTO.mockReturnValue(makeCommentDTO());

    const result = await useCase.execute(POST_ID, USER_ID, 'Genial!');

    expect(mockCommentRepo.create).toHaveBeenCalledWith(POST_ID, USER_ID, 'Genial!');
    expect(mockPostRepo.incrementCommentsCount).toHaveBeenCalledWith(POST_ID, 1);
    expect(result).toEqual(makeCommentDTO());
  });

  it('debe lanzar NotFoundException si el post no existe', async () => {
    mockPostRepo.findById.mockResolvedValue(null);

    await expect(
      useCase.execute('no-existe', USER_ID, 'texto'),
    ).rejects.toThrow(NotFoundException);
  });

  it('debe lanzar NotFoundException si el autor no existe', async () => {
    mockPostRepo.findById.mockResolvedValue(makePost());
    mockUserRepo.findById.mockResolvedValue(null);

    await expect(
      useCase.execute(POST_ID, 'usuario-inexistente', 'texto'),
    ).rejects.toThrow(NotFoundException);
  });
});
