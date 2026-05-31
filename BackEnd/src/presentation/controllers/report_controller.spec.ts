/**
 * @file report_controller.spec.ts
 * @description Tests unitarios para ReportController.
 * Verifica la validación del body, normalización del tipo de reporte y
 * la inserción correcta en la colección 'reports'.
 * @module Admin
 * @layer Presentation
 */

import 'reflect-metadata';
import { ReportController } from './ReportController.js';
import { HttpException }    from '../../core/exceptions/HttpException.js';

// ─── Constantes ───────────────────────────────────────────────────────────────

/** ObjectId-valid hex (24 caracteres). */
const USER_ID   = '64f1a2b3c4d5e6f7a8b9c0d1';
const TARGET_ID = '64f1a2b3c4d5e6f7a8b9c0d2';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockInsertOne        = jest.fn().mockResolvedValue({ insertedId: {} });
const mockFindOneAndUpdate = jest.fn().mockResolvedValue({ seq: 1 });

/** Devuelve métodos distintos según la colección solicitada. */
const mockCollection = jest.fn().mockImplementation((name: string) => {
  if (name === 'counters') return { findOneAndUpdate: mockFindOneAndUpdate };
  return { insertOne: mockInsertOne };
});

const mockGetDatabase = jest.fn().mockReturnValue({ collection: mockCollection });
const mockDb          = { getDatabase: mockGetDatabase };

// ─── Helpers ──────────────────────────────────────────────────────────────────

function makeReq(body: Record<string, unknown>, userId = USER_ID): any {
  return { body, user: { id: userId, role: 'user' } };
}

/**
 * Crea un mock de Response Express que captura status y json encadenados.
 */
function makeRes(): { status: jest.Mock; json: jest.Mock; captured: unknown[] } {
  const captured: unknown[] = [];
  const res: any = {
    captured,
    status: jest.fn(),
    json:   jest.fn((data: unknown) => { captured.push(data); }),
  };
  // Permite encadenamiento: res.status(201).json({...})
  res.status.mockReturnValue(res);
  return res;
}

// ─── Suite ────────────────────────────────────────────────────────────────────

describe('ReportController — POST /reports', () => {
  let controller: ReportController;

  beforeEach(() => {
    jest.clearAllMocks();
    controller = new ReportController(mockDb as any);
  });

  it('crea un reporte válido y devuelve 201 con status pending y ticketNumber', async () => {
    mockFindOneAndUpdate.mockResolvedValueOnce({ seq: 7 });
    const req  = makeReq({ type: 'post', targetId: TARGET_ID, text: 'Contenido inapropiado' });
    const res  = makeRes();
    const next = jest.fn();

    await (controller as any).handleCreateReport(req, res, next);

    expect(mockFindOneAndUpdate).toHaveBeenCalledTimes(1);
    expect(mockInsertOne).toHaveBeenCalledTimes(1);
    expect(res.status).toHaveBeenCalledWith(201);
    const body = res.captured[0] as any;
    expect(body).toMatchObject({
      type:         'post',
      text:         'Contenido inapropiado',
      status:       'pending',
      ticketNumber: 7,
    });
    expect(next).not.toHaveBeenCalled();
  });

  it('llama a next con HttpException(400) si text está vacío o solo espacios', async () => {
    const req  = makeReq({ type: 'general', text: '   ' });
    const res  = makeRes();
    const next = jest.fn();

    await (controller as any).handleCreateReport(req, res, next);

    expect(next).toHaveBeenCalledTimes(1);
    const err = next.mock.calls[0][0];
    expect(err).toBeInstanceOf(HttpException);
    expect((err as HttpException).statusCode).toBe(400);
    expect(mockInsertOne).not.toHaveBeenCalled();
  });

  it('llama a next con HttpException(400) si text está ausente', async () => {
    const req  = makeReq({ type: 'post', targetId: TARGET_ID });
    const res  = makeRes();
    const next = jest.fn();

    await (controller as any).handleCreateReport(req, res, next);

    expect(next).toHaveBeenCalledTimes(1);
    const err = next.mock.calls[0][0];
    expect(err).toBeInstanceOf(HttpException);
    expect((err as HttpException).statusCode).toBe(400);
  });

  it('normaliza a "general" si el type es un valor no permitido', async () => {
    const req  = makeReq({ type: 'spam', text: 'Reporte de prueba' });
    const res  = makeRes();
    const next = jest.fn();

    await (controller as any).handleCreateReport(req, res, next);

    const body = res.captured[0] as any;
    expect(body.type).toBe('general');
    expect(mockInsertOne).toHaveBeenCalledTimes(1);
  });

  it('usa "general" por defecto cuando type está ausente', async () => {
    const req  = makeReq({ text: 'Sin tipo explícito' });
    const res  = makeRes();
    const next = jest.fn();

    await (controller as any).handleCreateReport(req, res, next);

    const body = res.captured[0] as any;
    expect(body.type).toBe('general');
  });

  it('recorta el texto a 1000 caracteres si supera el límite', async () => {
    const longText = 'x'.repeat(1500);
    const req      = makeReq({ text: longText });
    const res      = makeRes();
    const next     = jest.fn();

    await (controller as any).handleCreateReport(req, res, next);

    const body = res.captured[0] as any;
    expect(body.text.length).toBe(1000);
  });

  it('acepta los tres tipos válidos sin normalización: general, post, comment', async () => {
    for (const type of ['general', 'post', 'comment']) {
      jest.clearAllMocks();
      const req  = makeReq({ type, text: 'Reporte válido' });
      const res  = makeRes();
      const next = jest.fn();

      await (controller as any).handleCreateReport(req, res, next);

      const body = res.captured[0] as any;
      expect(body.type).toBe(type);
    }
  });
});
