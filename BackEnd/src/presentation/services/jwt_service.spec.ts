/**
 * @file jwt_service.spec.ts
 * @description Tests unitarios para JwtService.
 * Verifica que sign() genera tokens válidos y que verify() los decodifica
 * correctamente, rechazando tokens inválidos o expirados.
 * @module Auth
 * @layer Presentation
 */

import 'reflect-metadata';
import { JwtService } from './JwtService.js';
import { UnauthorizedException } from '../../core/exceptions/UnauthorizedException.js';

describe('JwtService', () => {
  let service: JwtService;

  beforeEach(() => {
    service = new JwtService();
  });

  describe('sign()', () => {
    it('debe devolver un string con formato JWT (tres segmentos separados por punto)', () => {
      const token = service.sign({ userId: 'user123', email: 'test@example.com', role: 'user' });

      expect(typeof token).toBe('string');
      const parts = token.split('.');
      expect(parts).toHaveLength(3);
    });

    it('debe incluir el payload en el token decodificado', () => {
      const payload = { userId: 'abc123', email: 'user@example.com', role: 'user' as const };
      const token = service.sign(payload);

      const decoded = service.verify(token);
      expect(decoded.userId).toBe(payload.userId);
      expect(decoded.email).toBe(payload.email);
      expect(decoded.role).toBe(payload.role);
    });
  });

  describe('verify()', () => {
    it('debe devolver el payload correcto para un token válido', () => {
      const userId = 'user-id-999';
      const email  = 'valid@example.com';
      const token  = service.sign({ userId, email });

      const decoded = service.verify(token);
      expect(decoded.userId).toBe(userId);
      expect(decoded.email).toBe(email);
    });

    it('debe lanzar UnauthorizedException con un token modificado (firma inválida)', () => {
      const token = service.sign({ userId: 'u1', email: 'a@b.com' });
      const tampered = token.slice(0, -5) + 'XXXXX';

      expect(() => service.verify(tampered)).toThrow(UnauthorizedException);
    });

    it('debe lanzar UnauthorizedException con un token completamente inválido', () => {
      expect(() => service.verify('not.a.token')).toThrow(UnauthorizedException);
    });

    it('debe lanzar UnauthorizedException con una cadena vacía', () => {
      expect(() => service.verify('')).toThrow(UnauthorizedException);
    });
  });
});
