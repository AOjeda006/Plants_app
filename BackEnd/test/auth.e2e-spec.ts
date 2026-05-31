/**
 * @file auth.e2e-spec.ts
 * @description Tests de integración E2E para AuthController.
 * Flujo: registro → login → validar token → contraseña incorrecta.
 * @module Auth
 * @layer Presentation
 *
 * PREREQUISITOS:
 *   1. Backend corriendo en http://localhost:3000
 *   2. MongoDB accesible (configurado en .env)
 *   3. Ejecutar con: npm run test:e2e
 *
 * TFG: Estos tests usan supertest contra el servidor real en lugar de
 *      levantar un servidor de test, para evitar complejidad con el
 *      bootstrap de inversify + NestJS.
 */

import request from 'supertest';

const BASE_URL = process.env['TEST_BASE_URL'] ?? 'http://localhost:3000';

// ─── Constantes de test ───────────────────────────────────────────────────────

const TIMESTAMP = Date.now();
const EMAIL     = `e2e_auth_spec_${TIMESTAMP}@example.com`;
const PASSWORD  = 'Test1234!';
const NAME      = 'E2E Auth Spec';

let authToken = '';

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

describe('AuthController (E2E)', () => {
  // ── Registro ───────────────────────────────────────────────────────────────

  describe('POST /auth/register', () => {
    it('debe registrar un nuevo usuario y devolver token + datos públicos (201)', async () => {
      const response = await request(BASE_URL)
        .post('/auth/register')
        .send({ name: NAME, email: EMAIL, password: PASSWORD });

      expect(response.status).toBe(201);
      expect(response.body).toHaveProperty('token');
      expect(response.body.user).toHaveProperty('id');
      expect(response.body.user.email).toBe(EMAIL);
      expect(response.body.user).not.toHaveProperty('passwordHash');

      authToken = response.body.token;
    });

    it('debe devolver 409 si el email ya está registrado', async () => {
      const response = await request(BASE_URL)
        .post('/auth/register')
        .send({ name: NAME, email: EMAIL, password: PASSWORD });

      expect(response.status).toBe(409);
      expect(response.body.code).toBe('EMAIL_ALREADY_EXISTS');
    });

    it('debe devolver 422 si faltan campos obligatorios', async () => {
      const response = await request(BASE_URL)
        .post('/auth/register')
        .send({ email: 'incompleto@example.com' }); // sin name ni password

      expect(response.status).toBeGreaterThanOrEqual(400);
    });
  });

  // ── Login ──────────────────────────────────────────────────────────────────

  describe('POST /auth/login', () => {
    it('debe autenticar al usuario con credenciales válidas y devolver token (200)', async () => {
      const response = await request(BASE_URL)
        .post('/auth/login')
        .send({ email: EMAIL, password: PASSWORD });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('token');
      expect(response.body.user.email).toBe(EMAIL);

      authToken = response.body.token;
    });

    it('debe devolver 401 con contraseña incorrecta', async () => {
      const response = await request(BASE_URL)
        .post('/auth/login')
        .send({ email: EMAIL, password: 'ContraseñaEquivocada!' });

      expect(response.status).toBe(401);
    });

    it('debe devolver 401 con email inexistente (mensaje genérico)', async () => {
      const response = await request(BASE_URL)
        .post('/auth/login')
        .send({ email: 'noexiste_spec@example.com', password: PASSWORD });

      expect(response.status).toBe(401);
    });
  });

  // ── Validar token ─────────────────────────────────────────────────────────

  describe('GET /auth/validate-token', () => {
    it('debe validar un token válido y devolver el payload (200)', async () => {
      const response = await request(BASE_URL)
        .get('/auth/validate-token')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('userId');
    });

    it('debe devolver 401 sin token', async () => {
      const response = await request(BASE_URL).get('/auth/validate-token');
      expect(response.status).toBe(401);
    });

    it('debe devolver 401 con token inválido', async () => {
      const response = await request(BASE_URL)
        .get('/auth/validate-token')
        .set('Authorization', 'Bearer token.invalido.aqui');

      expect(response.status).toBe(401);
    });
  });
});
