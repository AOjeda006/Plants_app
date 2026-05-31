/**
 * @file ban_middleware.spec.ts
 * @description Tests unitarios para BanMiddleware.
 * Verifica que las operaciones de escritura (POST, PUT, DELETE) son bloqueadas
 * para usuarios con bannedUntil > now, y que las lecturas (GET) siempre pasan.
 * @module Core
 * @layer Core
 */

import 'reflect-metadata';
import { Request, Response, NextFunction } from 'express';
import { ObjectId } from 'mongodb';
import { createBanMiddleware } from './BanMiddleware.js';
import { ForbiddenException } from '../exceptions/ForbiddenException.js';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockFindOne = jest.fn();

const mockDb = {
  getDatabase: () => ({
    collection: () => ({
      findOne: mockFindOne,
    }),
  }),
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

const USER_ID = new ObjectId().toHexString();

/**
 * Crea un objeto Request fake con el método HTTP y el userId en user.
 */
const makeReq = (method: string, userId?: string, originalUrl = '/community'): Partial<Request> => ({
  method,
  originalUrl,
  user: userId ? { userId } : undefined,
} as any);

const makeRes = (): Partial<Response> => ({});

/**
 * Ejecuta el middleware y devuelve el resultado de next().
 * Si next recibe un error, lo lanza para que rejects.toThrow pueda capturarlo.
 */
const runMiddleware = async (
  req: Partial<Request>,
  res: Partial<Response> = makeRes(),
): Promise<void> => {
  const middleware = createBanMiddleware(mockDb as any);
  return new Promise<void>((resolve, reject) => {
    const next: NextFunction = (err?: any) => {
      if (err) reject(err);
      else resolve();
    };
    middleware(req as Request, res as Response, next);
  });
};

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

describe('BanMiddleware', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // ── GET siempre pasa ────────────────────────────────────────────────────────

  it('debe permitir peticiones GET sin consultar la BD', async () => {
    const req = makeReq('GET', USER_ID);
    await runMiddleware(req);

    // No debe consultar la BD para operaciones de lectura.
    expect(mockFindOne).not.toHaveBeenCalled();
  });

  // ── Usuario sin baneo ──────────────────────────────────────────────────────

  it('debe permitir POST si el usuario no está baneado', async () => {
    mockFindOne.mockResolvedValue({ bannedUntil: null });
    const req = makeReq('POST', USER_ID);

    await runMiddleware(req);

    expect(mockFindOne).toHaveBeenCalledTimes(1);
  });

  it('debe permitir POST si bannedUntil ya expiró', async () => {
    const pastDate = new Date();
    pastDate.setDate(pastDate.getDate() - 1);
    mockFindOne.mockResolvedValue({ bannedUntil: pastDate });
    const req = makeReq('POST', USER_ID);

    await runMiddleware(req);

    expect(mockFindOne).toHaveBeenCalledTimes(1);
  });

  // ── Usuario baneado ─────────────────────────────────────────────────────────

  it('debe lanzar ForbiddenException para POST si el usuario está baneado', async () => {
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 3);
    mockFindOne.mockResolvedValue({ bannedUntil: futureDate });
    const req = makeReq('POST', USER_ID);

    await expect(runMiddleware(req)).rejects.toThrow(ForbiddenException);
  });

  it('debe lanzar ForbiddenException para PUT si el usuario está baneado', async () => {
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 7);
    mockFindOne.mockResolvedValue({ bannedUntil: futureDate });
    const req = makeReq('PUT', USER_ID);

    await expect(runMiddleware(req)).rejects.toThrow(ForbiddenException);
  });

  it('debe lanzar ForbiddenException para DELETE si el usuario está baneado', async () => {
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 1);
    mockFindOne.mockResolvedValue({ bannedUntil: futureDate });
    const req = makeReq('DELETE', USER_ID);

    await expect(runMiddleware(req)).rejects.toThrow(ForbiddenException);
  });

  // ── Whitelist: POST /chat/:id/read ──────────────────────────────────────────

  it('debe permitir POST /chat/:id/read a un usuario baneado', async () => {
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 5);
    mockFindOne.mockResolvedValue({ bannedUntil: futureDate });
    const req = makeReq('POST', USER_ID, '/chat/abc123/read');

    await runMiddleware(req);

    // No debe consultar la BD — pasa por la whitelist antes del check de baneo.
    expect(mockFindOne).not.toHaveBeenCalled();
  });

  // ── Sin userId ──────────────────────────────────────────────────────────────

  it('debe permitir el paso si no hay userId en la request', async () => {
    const req = makeReq('POST');
    await runMiddleware(req);

    // Sin userId no puede consultar bannedUntil → pasa sin bloquear.
    expect(mockFindOne).not.toHaveBeenCalled();
  });

  // ── Admin exento ────────────────────────────────────────────────────────────

  it('debe permitir POST a un admin baneado (admins exentos)', async () => {
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 5);
    mockFindOne.mockResolvedValue({ bannedUntil: futureDate });
    // Admin: tiene role='admin' en req.user
    const req = { method: 'POST', originalUrl: '/community', user: { userId: USER_ID, role: 'admin' } } as any;

    await runMiddleware(req);

    // No debe consultar la BD — el middleware retorna antes de la query.
    expect(mockFindOne).not.toHaveBeenCalled();
  });

  it('debe bloquear POST a un user normal baneado (no exento)', async () => {
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 5);
    mockFindOne.mockResolvedValue({ bannedUntil: futureDate });
    const req = { method: 'POST', originalUrl: '/community', user: { userId: USER_ID, role: 'user' } } as any;

    await expect(runMiddleware(req)).rejects.toThrow(ForbiddenException);
  });
});
