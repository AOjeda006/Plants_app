/**
 * @file user_controller_fcm.spec.ts
 * @description Tests unitarios para los handlers de fcm-token de UserController.
 * Verifican que:
 *   1. PUT con un token previamente asignado a otro usuario limpia el otro.
 *   2. PUT con token vacío no intenta limpiar otros usuarios.
 *   3. DELETE /users/me/fcm-token vacía el campo (idempotente).
 * @module User
 * @layer Presentation
 */

import 'reflect-metadata';
import { UserController } from './UserController.js';

// ─── Helpers ──────────────────────────────────────────────────────────────────

function makeReq(userId: string, body?: Record<string, unknown>): any {
  return {
    user: { userId },
    body: body ?? {},
  };
}

function makeRes(): {
  status: jest.Mock;
  end: jest.Mock;
  json: jest.Mock;
  statusCode?: number;
} {
  const res: any = { statusCode: undefined };
  res.status = jest.fn((code: number) => {
    res.statusCode = code;
    return res;
  });
  res.end  = jest.fn(() => res);
  res.json = jest.fn(() => res);
  return res;
}

/**
 * Construye un mock mínimo del `db` que pasa al UserController. Acumula
 * todas las llamadas a `updateOne` y `updateMany` para verificación.
 */
function makeMockDb(): {
  db: any;
  updateOneCalls: any[];
  updateManyCalls: any[];
} {
  const updateOneCalls:  any[] = [];
  const updateManyCalls: any[] = [];
  const collection = (_name: string) => ({
    updateOne: jest.fn(async (filter: any, update: any) => {
      updateOneCalls.push({ filter, update });
      return { acknowledged: true, matchedCount: 1, modifiedCount: 1 };
    }),
    updateMany: jest.fn(async (filter: any, update: any) => {
      updateManyCalls.push({ filter, update });
      return { acknowledged: true, matchedCount: 0, modifiedCount: 0 };
    }),
  });
  return {
    db: {
      getDatabase: () => ({ collection }),
    },
    updateOneCalls,
    updateManyCalls,
  };
}

// ─── Suite ────────────────────────────────────────────────────────────────────

describe('UserController fcm-token', () => {
  // Inyectamos solo la dependencia `db`; el resto del controller no se ejerce.
  // Orden de parámetros del constructor (ver UserController):
  //   getUser, updateProfile, updatePreferences, changePassword,
  //   deleteAccount, exportData, db.
  function makeController(db: any): UserController {
    return new UserController(
      undefined as any,  // getUser
      undefined as any,  // updateProfile
      undefined as any,  // updatePreferences
      undefined as any,  // changePassword
      undefined as any,  // deleteAccount
      undefined as any,  // exportData
      db,                // db (MongoDBConnection)
    );
  }

  it('PUT con token nuevo y único: no hace updateMany, sí updateOne con el nuevo token', async () => {
    const { db, updateOneCalls, updateManyCalls } = makeMockDb();
    const controller = makeController(db);
    const req  = makeReq('507f1f77bcf86cd799439011', { fcmToken: 'fresh-token' });
    const res  = makeRes();
    const next = jest.fn((err: any) => { if (err) throw err; });

    await (controller as any).handleSetFcmToken(req, res, next);

    expect(next).not.toHaveBeenCalled();
    expect(res.statusCode).toBe(204);
    // updateMany sí se llamó (defensa frente a transferencia entre cuentas).
    // El filter buscó OTROS users con el mismo token.
    expect(updateManyCalls.length).toBe(1);
    expect(updateManyCalls[0].filter.fcmToken).toBe('fresh-token');
    expect(updateOneCalls.length).toBe(1);
    expect(updateOneCalls[0].update.$set.fcmToken).toBe('fresh-token');
  });

  it('PUT con token vacío NO ejecuta updateMany (limpieza local únicamente)', async () => {
    const { db, updateOneCalls, updateManyCalls } = makeMockDb();
    const controller = makeController(db);
    const req  = makeReq('507f1f77bcf86cd799439011', { fcmToken: '' });
    const res  = makeRes();
    const next = jest.fn();

    await (controller as any).handleSetFcmToken(req, res, next);

    expect(res.statusCode).toBe(204);
    // Token vacío → no intenta desasociar de otros.
    expect(updateManyCalls.length).toBe(0);
    expect(updateOneCalls.length).toBe(1);
    expect(updateOneCalls[0].update.$set.fcmToken).toBe('');
  });

  it('DELETE limpia fcmToken (204, idempotente)', async () => {
    const { db, updateOneCalls, updateManyCalls } = makeMockDb();
    const controller = makeController(db);
    const req  = makeReq('507f1f77bcf86cd799439011');
    const res  = makeRes();
    const next = jest.fn();

    await (controller as any).handleDeleteFcmToken(req, res, next);

    expect(res.statusCode).toBe(204);
    // No hay updateMany en el DELETE.
    expect(updateManyCalls.length).toBe(0);
    expect(updateOneCalls.length).toBe(1);
    expect(updateOneCalls[0].update.$set.fcmToken).toBe('');
  });

  it('DELETE es idempotente: segunda llamada también devuelve 204', async () => {
    const { db, updateOneCalls } = makeMockDb();
    const controller = makeController(db);
    const req  = makeReq('507f1f77bcf86cd799439011');
    const res1 = makeRes();
    const res2 = makeRes();
    const next = jest.fn();

    await (controller as any).handleDeleteFcmToken(req, res1, next);
    await (controller as any).handleDeleteFcmToken(req, res2, next);

    expect(res1.statusCode).toBe(204);
    expect(res2.statusCode).toBe(204);
    expect(updateOneCalls.length).toBe(2);
  });
});
