/**
 * @file moderation.e2e-spec.ts
 * @description Tests E2E del flujo de moderación de comunidad por admin.
 * Flujo: usuario regular crea post → admin lo elimina → verificar que ya no
 * aparece en GET /community y que el regular recibe una notificación.
 * @module Admin
 * @layer Presentation
 *
 * PREREQUISITOS:
 *   1. Backend corriendo en http://localhost:3000 (o TEST_BASE_URL).
 *   2. Usuario admin existente con credenciales admin@plants.app /
 *      admin1234 (defaults del seed seed-admin.ts) o las definidas en las
 *      env vars ADMIN_EMAIL / ADMIN_PASSWORD.
 *   3. Ejecutar con: npm run test:e2e
 *
 * TFG: Reutiliza el patrón de los specs E2E ya existentes (auth, plants,
 *      community): supertest contra el backend real, sin levantar Express
 *      adicional (evita la complejidad del bootstrap inversify + DI).
 */

import request from 'supertest';

const BASE_URL = process.env['TEST_BASE_URL'] ?? 'http://localhost:3000';

// ─── Constantes de test ───────────────────────────────────────────────────────

const TIMESTAMP    = Date.now();
const REGULAR_NAME     = 'E2E Mod Regular';
const REGULAR_EMAIL    = `e2e_mod_regular_${TIMESTAMP}@example.com`;
const REGULAR_PASSWORD = 'Test1234!';

const ADMIN_EMAIL    = process.env['ADMIN_EMAIL']    ?? 'admin@plants.app';
const ADMIN_PASSWORD = process.env['ADMIN_PASSWORD'] ?? 'admin1234';

let regularToken  = '';
let regularId     = '';
let adminToken    = '';
let createdPostId = '';

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

describe('Moderación de comunidad por admin (E2E)', () => {
  // ── Bootstrap: registrar regular y loguear admin ────────────────────────────

  beforeAll(async () => {
    const reg = await request(BASE_URL)
      .post('/auth/register')
      .send({ name: REGULAR_NAME, email: REGULAR_EMAIL, password: REGULAR_PASSWORD });
    if (reg.status !== 201) {
      throw new Error(`Setup failed: register regular returned ${reg.status}`);
    }
    regularToken = reg.body.token;
    regularId    = reg.body.user.id;

    const adminLogin = await request(BASE_URL)
      .post('/auth/login')
      .send({ email: ADMIN_EMAIL, password: ADMIN_PASSWORD });
    if (adminLogin.status !== 200) {
      throw new Error(
        `Setup failed: admin login returned ${adminLogin.status}. ` +
        `Asegúrate de que el seed admin se haya ejecutado y las credenciales ` +
        `coincidan con ADMIN_EMAIL/ADMIN_PASSWORD.`,
      );
    }
    adminToken = adminLogin.body.token;
  });

  // ── 1) Regular crea post ───────────────────────────────────────────────────

  describe('POST /community (usuario regular)', () => {
    it('debe crear un post con autor=regular y devolver 201', async () => {
      const response = await request(BASE_URL)
        .post('/community')
        .set('Authorization', `Bearer ${regularToken}`)
        .send({ content: `Post a moderar ${TIMESTAMP}` });

      expect(response.status).toBe(201);
      expect(response.body).toHaveProperty('id');
      expect(response.body.userId).toBe(regularId);
      createdPostId = response.body.id;
    });
  });

  // ── 2) Admin elimina el post ───────────────────────────────────────────────

  describe('DELETE /admin/posts/:id (admin)', () => {
    it('debe permitir al admin soft-deletear el post (204)', async () => {
      expect(createdPostId).not.toBe('');
      const response = await request(BASE_URL)
        .delete(`/admin/posts/${createdPostId}`)
        .set('Authorization', `Bearer ${adminToken}`);
      expect(response.status).toBe(204);
    });

    it('debe devolver 404 al intentar borrarlo de nuevo', async () => {
      const response = await request(BASE_URL)
        .delete(`/admin/posts/${createdPostId}`)
        .set('Authorization', `Bearer ${adminToken}`);
      expect(response.status).toBe(404);
    });

    it('debe rechazar la operación si la hace un usuario regular (403)', async () => {
      // Reusa createdPostId aunque ya esté borrado: el guard de permiso se
      // evalúa antes de buscar el post, por lo que devuelve 403.
      const response = await request(BASE_URL)
        .delete(`/admin/posts/${createdPostId}`)
        .set('Authorization', `Bearer ${regularToken}`);
      expect(response.status).toBe(403);
    });
  });

  // ── 3) GET /community no muestra el post ───────────────────────────────────

  describe('GET /community (post moderado)', () => {
    it('no debe incluir el post eliminado en el feed', async () => {
      const response = await request(BASE_URL)
        .get('/community')
        .set('Authorization', `Bearer ${regularToken}`);

      expect(response.status).toBe(200);
      const ids = (response.body.posts as Array<{ id: string }>).map((p) => p.id);
      expect(ids).not.toContain(createdPostId);
    });
  });

  // ── 4) Regular recibe notificación de moderación ───────────────────────────

  describe('GET /notifications (notificación admin → regular)', () => {
    it('debe devolver una notificación con mensaje sobre la publicación eliminada', async () => {
      const response = await request(BASE_URL)
        .get('/notifications')
        .set('Authorization', `Bearer ${regularToken}`);

      expect(response.status).toBe(200);
      const items = response.body as Array<{ message: string; type: string }>;
      const found = items.find(
        (n) => typeof n.message === 'string' &&
               n.message.toLowerCase().includes('publicación') &&
               n.message.toLowerCase().includes('eliminad'),
      );
      expect(found).toBeDefined();
    });
  });
});
