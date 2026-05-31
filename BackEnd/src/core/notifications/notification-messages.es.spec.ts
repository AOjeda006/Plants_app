/**
 * @file notification-messages.es.spec.ts
 * @description Tests del helper centralizado de mensajes de notificación.
 * Verifica formato esperado de cada función pública Y que ninguna
 * incluye palabras inglesas comunes de WeatherAPI — anti-regresión de
 * idioma.
 * @module Core
 * @layer Core
 */

import { NotificationMessages } from './notification-messages.es.js';

/**
 * Patrón de palabras inglesas comunes de WeatherAPI y UI genérica.
 * Si una función del helper produce un mensaje que matchee este regex,
 * el test falla. Usamos `\b` para no chocar con "rain"/"raid" español.
 *
 * Excepciones de palabras que también existen en español:
 *  - "today" (inglés) vs "today" no existe en español pero coincide con
 *    nombres propios, etc. Mantengo el filtro porque ninguno de
 *    nuestros mensajes contiene "today".
 */
const ENGLISH_PATTERN =
  /\b(rain|storm|cloudy|sunny|possible|alert|warning|today|tomorrow|patchy|thundery|shower|drizzle|snow|fog|hail|freezing|loading|please|wait)\b/i;

describe('NotificationMessages.es', () => {

  // ── watering ────────────────────────────────────────────────────────────────

  describe('watering', () => {
    it('pending: incluye nombre de planta', () => {
      const msg = NotificationMessages.watering.pending('Rosa');
      expect(msg).toBe('Es hora de regar "Rosa"');
      expect(msg).not.toMatch(ENGLISH_PATTERN);
    });

    it('rainPostponed: incluye porcentaje y nombre', () => {
      const msg = NotificationMessages.watering.rainPostponed('Cactus', 85);
      expect(msg).toContain('Cactus');
      expect(msg).toContain('85%');
      expect(msg).not.toMatch(ENGLISH_PATTERN);
    });

    it('stormAlert: incluye condition (debe llegar ya traducido al español por lang=es)', () => {
      const msg = NotificationMessages.watering.stormAlert('Limonero', 'Tormenta eléctrica');
      expect(msg).toContain('Limonero');
      expect(msg).toContain('Tormenta eléctrica');
      expect(msg).not.toMatch(ENGLISH_PATTERN);
    });

    it('rainConfirmed: incluye mm, ciudad y especie opcionalmente', () => {
      const msg = NotificationMessages.watering.rainConfirmed('Rosa', 12, 'Sevilla', 'Rosa común');
      expect(msg).toContain('12mm');
      expect(msg).toContain('Sevilla');
      expect(msg).toContain('Rosa común');
      expect(msg).not.toMatch(ENGLISH_PATTERN);
    });

    it('rainConfirmed: omite ciudad y especie si no se pasan', () => {
      const msg = NotificationMessages.watering.rainConfirmed('Rosa', 8);
      expect(msg).toContain('8mm');
      expect(msg).not.toContain('undefined');
      expect(msg).not.toMatch(ENGLISH_PATTERN);
    });

    it('rainRollback: indica rollback con flecha', () => {
      const msg = NotificationMessages.watering.rainRollback('Tomatera', 1, 'Madrid');
      expect(msg).toContain('Tomatera');
      expect(msg).toContain('Madrid');
      expect(msg).toContain('1mm');
      expect(msg).toContain('↩️');
      expect(msg).not.toMatch(ENGLISH_PATTERN);
    });

    it('rainConfirmedAdjustment: marca de éxito ✅', () => {
      const msg = NotificationMessages.watering.rainConfirmedAdjustment('Lavanda', 6, 'Valencia');
      expect(msg).toContain('✅');
      expect(msg).toContain('Lavanda');
      expect(msg).toContain('6mm');
      expect(msg).not.toMatch(ENGLISH_PATTERN);
    });

    it('simulatedRain: mensaje admin formal', () => {
      const msg = NotificationMessages.watering.simulatedRain('Albahaca', 'Bilbao');
      expect(msg).toContain('Albahaca');
      expect(msg).toContain('Bilbao');
      expect(msg).not.toMatch(ENGLISH_PATTERN);
    });

    it('simulatedStorm: mensaje admin formal', () => {
      const msg = NotificationMessages.watering.simulatedStorm('Olivo', 'Granada');
      expect(msg).toContain('Olivo');
      expect(msg).toContain('Granada');
      expect(msg).not.toMatch(ENGLISH_PATTERN);
    });
  });

  // ── pruning / harvest / dailySummary ───────────────────────────────────────

  describe('pruning', () => {
    it('pending: incluye planta y especie', () => {
      const msg = NotificationMessages.pruning.pending('Rosa del jardín', 'Rosa');
      expect(msg).toBe('Es tiempo de podar "Rosa del jardín" (Rosa)');
      expect(msg).not.toMatch(ENGLISH_PATTERN);
    });
  });

  describe('harvest', () => {
    it('pending: incluye planta y especie', () => {
      const msg = NotificationMessages.harvest.pending('Mi naranjo', 'Naranjo');
      expect(msg).toBe('Este mes puedes cosechar: "Mi naranjo" (Naranjo)');
      expect(msg).not.toMatch(ENGLISH_PATTERN);
    });
  });

  describe('dailySummary', () => {
    it('allCaughtUp: mensaje fijo en español', () => {
      const msg = NotificationMessages.dailySummary.allCaughtUp();
      expect(msg).toContain('Todo al día');
      expect(msg).not.toMatch(ENGLISH_PATTERN);
    });

    it('multipleAlerts: incluye count', () => {
      const msg = NotificationMessages.dailySummary.multipleAlerts(7);
      expect(msg).toContain('7 avisos');
      expect(msg).not.toMatch(ENGLISH_PATTERN);
    });

    it('multipleAlertsRain: incluye count', () => {
      const msg = NotificationMessages.dailySummary.multipleAlertsRain(4);
      expect(msg).toContain('4 alertas de lluvia');
      expect(msg).not.toMatch(ENGLISH_PATTERN);
    });

    it('multipleAlertsStorm: incluye count', () => {
      const msg = NotificationMessages.dailySummary.multipleAlertsStorm(3);
      expect(msg).toContain('3 alertas de tormenta');
      expect(msg).not.toMatch(ENGLISH_PATTERN);
    });
  });

  // ── admin ──────────────────────────────────────────────────────────────────

  describe('admin', () => {
    it('postDeleted: con motivo', () => {
      const msg = NotificationMessages.admin.postDeleted('contenido inapropiado');
      expect(msg).toContain('eliminada por moderación');
      expect(msg).toContain('contenido inapropiado');
      expect(msg).not.toMatch(ENGLISH_PATTERN);
    });

    it('postDeleted: sin motivo', () => {
      const msg = NotificationMessages.admin.postDeleted();
      expect(msg).toContain('eliminada por moderación');
      expect(msg).not.toContain('undefined');
      expect(msg).not.toMatch(ENGLISH_PATTERN);
    });

    it('contentRestored: especifica tipo', () => {
      const msg = NotificationMessages.admin.contentRestored('publicación');
      expect(msg).toContain('publicación');
      expect(msg).toContain('aprobada');
      expect(msg).not.toMatch(ENGLISH_PATTERN);
    });

    it('ban: muestra fecha en formato español', () => {
      const until = new Date('2026-06-15T00:00:00Z');
      const msg = NotificationMessages.admin.ban(until);
      expect(msg).toContain('suspendida');
      // Formato es-ES varía por locale del runtime, pero debe contener "2026".
      expect(msg).toContain('2026');
      expect(msg).not.toMatch(ENGLISH_PATTERN);
    });
  });
});
