/**
 * @file plants.e2e-spec.ts
 * @description Tests de integración E2E para PlantController.
 * Flujo: login → crear planta → obtener lista → obtener por id → actualizar → eliminar.
 * @module Plants
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
const EMAIL     = `e2e_plants_spec_${TIMESTAMP}@example.com`;
const PASSWORD  = 'Test1234!';
const NAME      = 'E2E Plants Spec';

let authToken = '';
let plantId   = '';

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

describe('PlantController (E2E)', () => {
  // ── Autenticación previa ──────────────────────────────────────────────────

  beforeAll(async () => {
    const reg = await request(BASE_URL)
      .post('/auth/register')
      .send({ name: NAME, email: EMAIL, password: PASSWORD });

    if (reg.status === 201) {
      authToken = reg.body.token;
    } else {
      // Ya existía — hacer login
      const login = await request(BASE_URL)
        .post('/auth/login')
        .send({ email: EMAIL, password: PASSWORD });
      authToken = login.body.token;
    }
  });

  // ── POST /plants — crear planta ───────────────────────────────────────────

  describe('POST /plants', () => {
    it('debe crear una planta y devolver PlantResponseDTO (201)', async () => {
      const response = await request(BASE_URL)
        .post('/plants')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name:              'Monstera E2E',
          location:          'Interior',
          wateringFrequency: 7,
          lightNeed:         'Medium',
        });

      expect(response.status).toBe(201);
      expect(response.body).toHaveProperty('id');
      expect(response.body.name).toBe('Monstera E2E');
      expect(response.body).toHaveProperty('nextWatering');

      plantId = response.body.id;
    });

    it('debe devolver 401 sin token de autenticación', async () => {
      const response = await request(BASE_URL)
        .post('/plants')
        .send({ name: 'Planta sin auth', wateringFrequency: 7, lightNeed: 'Low' });

      expect(response.status).toBe(401);
    });
  });

  // ── GET /plants — obtener lista ────────────────────────────────────────────

  describe('GET /plants', () => {
    it('debe devolver la lista de plantas del usuario (200)', async () => {
      const response = await request(BASE_URL)
        .get('/plants')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.length).toBeGreaterThanOrEqual(1);
    });

    it('debe devolver 401 sin token', async () => {
      const response = await request(BASE_URL).get('/plants');
      expect(response.status).toBe(401);
    });
  });

  // ── GET /plants/:id — obtener por id ──────────────────────────────────────

  describe('GET /plants/:id', () => {
    it('debe devolver los detalles de la planta creada (200)', async () => {
      const response = await request(BASE_URL)
        .get(`/plants/${plantId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.id).toBe(plantId);
      expect(response.body.name).toBe('Monstera E2E');
    });

    it('debe devolver 404 para un id inexistente', async () => {
      const response = await request(BASE_URL)
        .get('/plants/000000000000000000000000')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(404);
    });
  });

  // ── PUT /plants/:id — actualizar planta ───────────────────────────────────

  describe('PUT /plants/:id', () => {
    it('debe actualizar la planta y devolver datos actualizados (200)', async () => {
      const response = await request(BASE_URL)
        .put(`/plants/${plantId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name: 'Monstera Actualizada E2E' });

      expect(response.status).toBe(200);
      expect(response.body.name).toBe('Monstera Actualizada E2E');
    });
  });

  // ── DELETE /plants/:id — eliminar planta ──────────────────────────────────

  describe('DELETE /plants/:id', () => {
    it('debe eliminar (soft delete) la planta y devolver 204', async () => {
      const response = await request(BASE_URL)
        .delete(`/plants/${plantId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(204);
    });

    it('debe devolver 404 al intentar acceder a una planta eliminada', async () => {
      const response = await request(BASE_URL)
        .get(`/plants/${plantId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(404);
    });
  });
});
