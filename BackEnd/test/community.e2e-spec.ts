/**
 * @file community.e2e-spec.ts
 * @description Tests de integración E2E para PostController.
 * Flujo: login → crear post → obtener feed → like (idempotente) → unlike → comentar → obtener comentarios.
 * @module Community
 * @layer Presentation
 *
 * PREREQUISITOS:
 *   1. Backend corriendo en http://localhost:3000
 *   2. MongoDB accesible (configurado en .env)
 *   3. Ejecutar con: npm run test:e2e
 */

import request from 'supertest';

const BASE_URL = process.env['TEST_BASE_URL'] ?? 'http://localhost:3000';

// ─── Setup ────────────────────────────────────────────────────────────────────

const TIMESTAMP = Date.now();
const EMAIL     = `e2e_community_spec_${TIMESTAMP}@example.com`;
const PASSWORD  = 'Test1234!';
const NAME      = 'E2E Community Spec';

let authToken  = '';
let postId     = '';
let commentId  = '';

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

describe('PostController (E2E)', () => {
  beforeAll(async () => {
    const reg = await request(BASE_URL)
      .post('/auth/register')
      .send({ name: NAME, email: EMAIL, password: PASSWORD });

    authToken = reg.status === 201
      ? reg.body.token
      : (await request(BASE_URL).post('/auth/login').send({ email: EMAIL, password: PASSWORD })).body.token;
  });

  // ── POST /community — crear post ─────────────────────────────────────────

  describe('POST /community', () => {
    it('debe crear un post y devolver PostResponseDTO (201)', async () => {
      const response = await request(BASE_URL)
        .post('/community')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          title:   'Mi primera monstera E2E',
          content: 'Hoy ha sacado su primera hoja fenestrada.',
          tags:    ['monstera', 'interior'],
        });

      expect(response.status).toBe(201);
      expect(response.body).toHaveProperty('id');
      expect(response.body.title).toBe('Mi primera monstera E2E');
      expect(response.body.likesCount).toBe(0);

      postId = response.body.id;
    });

    it('debe devolver 401 sin token', async () => {
      const response = await request(BASE_URL)
        .post('/community')
        .send({ title: 'Post sin auth', content: 'Contenido' });

      expect(response.status).toBe(401);
    });
  });

  // ── GET /community — feed ────────────────────────────────────────────────

  describe('GET /community', () => {
    it('debe devolver el feed con el post recién creado (200)', async () => {
      const response = await request(BASE_URL)
        .get('/community')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
    });
  });

  // ── GET /community/:id — detalle del post ─────────────────────────────────

  describe('GET /community/:id', () => {
    it('debe devolver los detalles del post (200)', async () => {
      const response = await request(BASE_URL)
        .get(`/community/${postId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.id).toBe(postId);
    });

    it('debe devolver 404 para un post inexistente', async () => {
      const response = await request(BASE_URL)
        .get('/community/000000000000000000000000')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(404);
    });
  });

  // ── POST /community/:id/like — dar like ──────────────────────────────────

  describe('POST /community/:id/like', () => {
    it('debe dar like al post y devolver 200 o 204', async () => {
      const response = await request(BASE_URL)
        .post(`/community/${postId}/like`)
        .set('Authorization', `Bearer ${authToken}`);

      expect([200, 204]).toContain(response.status);
    });

    it('debe ser idempotente: dar like dos veces no aumenta el contador en 2', async () => {
      await request(BASE_URL)
        .post(`/community/${postId}/like`)
        .set('Authorization', `Bearer ${authToken}`);

      const postAfter = await request(BASE_URL)
        .get(`/community/${postId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(postAfter.body.likesCount).toBe(1);
    });
  });

  // ── DELETE /community/:id/like — quitar like ──────────────────────────────

  describe('DELETE /community/:id/like', () => {
    it('debe quitar el like del post (200 o 204)', async () => {
      const response = await request(BASE_URL)
        .delete(`/community/${postId}/like`)
        .set('Authorization', `Bearer ${authToken}`);

      expect([200, 204]).toContain(response.status);
    });

    it('después de unlike el contador debe ser 0', async () => {
      const postAfter = await request(BASE_URL)
        .get(`/community/${postId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(postAfter.body.likesCount).toBe(0);
    });
  });

  // ── POST /community/:id/comments — crear comentario ──────────────────────

  describe('POST /community/:id/comments', () => {
    it('debe crear un comentario y devolver CommentResponseDTO (201)', async () => {
      const response = await request(BASE_URL)
        .post(`/community/${postId}/comments`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ content: 'Qué bonita la monstera!' });

      expect(response.status).toBe(201);
      expect(response.body).toHaveProperty('id');
      expect(response.body.content).toBe('Qué bonita la monstera!');

      commentId = response.body.id;
    });
  });

  // ── GET /community/:id/comments — obtener comentarios ────────────────────

  describe('GET /community/:id/comments', () => {
    it('debe devolver la lista de comentarios del post (200)', async () => {
      const response = await request(BASE_URL)
        .get(`/community/${postId}/comments`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.some((c: any) => c.id === commentId)).toBe(true);
    });
  });

  // ── DELETE /community/:id — eliminar post ─────────────────────────────────

  describe('DELETE /community/:id', () => {
    it('debe eliminar el post (204)', async () => {
      const response = await request(BASE_URL)
        .delete(`/community/${postId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect([200, 204]).toContain(response.status);
    });
  });
});
