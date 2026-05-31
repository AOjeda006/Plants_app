/**
 * @file hash_service.spec.ts
 * @description Tests unitarios para HashService.
 * Verifica que hash() produce un hash bcrypt válido y que compare()
 * distingue correctamente entre contraseñas correctas e incorrectas.
 * @module Auth
 * @layer Presentation
 */

import 'reflect-metadata';
import { HashService } from './HashService.js';

describe('HashService', () => {
  let service: HashService;

  beforeEach(() => {
    service = new HashService();
  });

  describe('hash()', () => {
    it('debe devolver un string diferente a la contraseña original', async () => {
      const password = 'MiContraseña123!';
      const hash = await service.hash(password);

      expect(typeof hash).toBe('string');
      expect(hash).not.toBe(password);
    });

    it('debe generar hashes distintos para la misma contraseña (salt aleatorio)', async () => {
      const password = 'MiContraseña123!';
      const hash1 = await service.hash(password);
      const hash2 = await service.hash(password);

      expect(hash1).not.toBe(hash2);
    });

    it('el hash debe comenzar con el identificador bcrypt $2b$', async () => {
      const hash = await service.hash('cualquierContraseña');
      expect(hash).toMatch(/^\$2[ab]\$/);
    });
  });

  describe('compare()', () => {
    it('debe devolver true cuando la contraseña coincide con su hash', async () => {
      const password = 'ContraseñaSegura456!';
      const hash = await service.hash(password);

      const result = await service.compare(password, hash);
      expect(result).toBe(true);
    });

    it('debe devolver false cuando la contraseña no coincide', async () => {
      const password = 'ContraseñaCorrecta!';
      const wrongPassword = 'ContraseñaIncorrecta!';
      const hash = await service.hash(password);

      const result = await service.compare(wrongPassword, hash);
      expect(result).toBe(false);
    });

    it('debe devolver false para una cadena vacía contra un hash real', async () => {
      const hash = await service.hash('ContraseñaReal!');
      const result = await service.compare('', hash);
      expect(result).toBe(false);
    });
  });
});
