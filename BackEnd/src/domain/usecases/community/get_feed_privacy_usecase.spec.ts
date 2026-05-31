/**
 * @file get_feed_privacy_usecase.spec.ts
 * @description Tests unitarios para GetFeedUseCase — filtrado por privacidad.
 * Verifica que los posts de usuarios con perfil privado se excluyen del feed
 * ajeno, y que el propio usuario puede ver sus posts aunque sea privado.
 * @module Community
 * @layer Domain
 */

import 'reflect-metadata';
import { GetFeedUseCase } from './GetFeedUseCase.js';
import { User }           from '../../entities/User.js';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockPostRepo = {
  findFeed: jest.fn(),
};

const mockUserRepo = {
  findById: jest.fn(),
};

const mockLikeRepo = {
  findByPostAndUser: jest.fn(),
};

const mockMapper = {
  toResponseDTO: jest.fn(),
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

const REQUESTER_ID = 'requester-001';
const PRIVATE_ID   = 'private-user-001';
const PUBLIC_ID    = 'public-user-001';

const makePost = (userId: string, id = `post-${userId}`) => ({
  id, userId, content: 'Hola', createdAt: new Date(),
});

const makeUser = (id: string, isPrivate: boolean, role?: 'user' | 'admin') =>
  new User({
    id, name: 'Test', email: `${id}@x.com`, passwordHash: 'h',
    role: role ?? 'user',
    preferences: {
      appearInChatSearch:        true,
      considerWeatherByDefault:  false,
      isPrivate,
    },
    createdAt: new Date(), updatedAt: new Date(),
  });

const makeDTO = (postId: string) => ({ id: postId, content: 'Hola', authorName: 'Test' });

// ─── Suite ────────────────────────────────────────────────────────────────────

describe('GetFeedUseCase — privacidad', () => {
  let useCase: GetFeedUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    mockLikeRepo.findByPostAndUser.mockResolvedValue(null);
    mockMapper.toResponseDTO.mockImplementation(
      (post: any) => makeDTO(post.id),
    );

    useCase = new GetFeedUseCase(
      mockPostRepo  as any,
      mockUserRepo  as any,
      mockLikeRepo  as any,
      mockMapper    as any,
    );
  });

  it('debe incluir posts de usuarios con perfil público', async () => {
    const post = makePost(PUBLIC_ID);
    mockPostRepo.findFeed.mockResolvedValue([post]);
    mockUserRepo.findById.mockResolvedValue(makeUser(PUBLIC_ID, false));

    const result = await useCase.execute(REQUESTER_ID);

    expect(result).toHaveLength(1);
    expect(result[0].id).toBe(post.id);
  });

  it('debe excluir posts de usuarios con perfil privado cuando el solicitante es ajeno', async () => {
    const post = makePost(PRIVATE_ID);
    mockPostRepo.findFeed.mockResolvedValue([post]);
    mockUserRepo.findById.mockResolvedValue(makeUser(PRIVATE_ID, true));

    const result = await useCase.execute(REQUESTER_ID);

    expect(result).toHaveLength(0);
    expect(mockMapper.toResponseDTO).not.toHaveBeenCalled();
  });

  it('en modo comunidad, excluye posts propios aunque el usuario no sea privado', async () => {
    // En modo feed, los posts del solicitante se excluyen siempre,
    // independientemente de isPrivate.
    const post = makePost(REQUESTER_ID);
    mockPostRepo.findFeed.mockResolvedValue([post]);
    mockUserRepo.findById.mockResolvedValue(makeUser(REQUESTER_ID, false));

    const result = await useCase.execute(REQUESTER_ID);

    expect(result).toHaveLength(0);
  });

  it('en modo perfil (authorId), incluye posts propios aunque el usuario sea privado', async () => {
    // Para ver posts propios se usa el modo perfil (authorId = userId).
    const post = makePost(REQUESTER_ID);
    mockPostRepo.findFeed.mockResolvedValue([post]);
    mockUserRepo.findById.mockResolvedValue(makeUser(REQUESTER_ID, true));

    // authorId = REQUESTER_ID → modo perfil, no se excluyen por userId ni por isPrivate propio
    const result = await useCase.execute(REQUESTER_ID, 1, 20, REQUESTER_ID);

    expect(result).toHaveLength(1);
    expect(result[0].id).toBe(post.id);
  });

  it('debe mezclar posts públicos y privados correctamente', async () => {
    const publicPost  = makePost(PUBLIC_ID,  'p-public');
    const privatePost = makePost(PRIVATE_ID, 'p-private');
    mockPostRepo.findFeed.mockResolvedValue([publicPost, privatePost]);

    mockUserRepo.findById
      .mockResolvedValueOnce(makeUser(REQUESTER_ID, false)) // solicitante (para rol)
      .mockResolvedValueOnce(makeUser(PUBLIC_ID,  false))   // autor del primer post
      .mockResolvedValueOnce(makeUser(PRIVATE_ID, true));   // autor del segundo post

    const result = await useCase.execute(REQUESTER_ID);

    expect(result).toHaveLength(1);
    expect(result[0].id).toBe('p-public');
  });

  it('debe excluir posts de usuario eliminado en el feed de comunidad', async () => {
    const post = makePost('deleted-user');
    mockPostRepo.findFeed.mockResolvedValue([post]);
    // findById devuelve null — usuario eliminado
    mockUserRepo.findById.mockResolvedValue(null);

    const result = await useCase.execute(REQUESTER_ID);

    // En feed de comunidad (!authorId), author===null → skip. Posts de
    // cuentas eliminadas no aparecen en el feed global.
    expect(result).toHaveLength(0);
  });

  it('debe devolver lista vacía si no hay posts', async () => {
    mockPostRepo.findFeed.mockResolvedValue([]);

    const result = await useCase.execute(REQUESTER_ID);

    expect(result).toHaveLength(0);
  });

  // ── Admin ve posts de usuarios privados ────────────────────────────────────

  it('admin debe ver posts de usuarios con perfil privado', async () => {
    const ADMIN_ID = 'admin-001';
    const post = makePost(PRIVATE_ID);
    mockPostRepo.findFeed.mockResolvedValue([post]);
    mockUserRepo.findById
      .mockResolvedValueOnce(makeUser(ADMIN_ID, false, 'admin'))  // solicitante (admin)
      .mockResolvedValueOnce(makeUser(PRIVATE_ID, true));         // autor del post (privado)

    const result = await useCase.execute(ADMIN_ID);

    // El admin debe ver el post aunque el autor tenga perfil privado.
    expect(result).toHaveLength(1);
    expect(result[0].id).toBe(post.id);
  });

  it('usuario normal NO debe ver posts de usuarios con perfil privado', async () => {
    const post = makePost(PRIVATE_ID);
    mockPostRepo.findFeed.mockResolvedValue([post]);
    mockUserRepo.findById
      .mockResolvedValueOnce(makeUser(REQUESTER_ID, false))  // solicitante (user normal)
      .mockResolvedValueOnce(makeUser(PRIVATE_ID, true));    // autor del post (privado)

    const result = await useCase.execute(REQUESTER_ID);

    expect(result).toHaveLength(0);
  });
});
