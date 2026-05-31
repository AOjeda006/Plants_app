/**
 * @file notification-messages.es.ts
 * @description Helper centralizado para la construcción de mensajes de
 * notificación en español.
 *
 * Cualquier nueva notificación añadida al backend DEBE pasar por una
 * función de este helper. Beneficios:
 *  - Anti-regresión: imposible colar inglés accidentalmente.
 *  - Coherencia léxica/tipográfica en toda la app.
 *  - Punto único para futura i18n del backend (multi-idioma).
 *
 * El test E2E `notifications-language.e2e-spec.ts` verifica con regex que
 * el campo `message` de cualquier notificación generada no contiene
 * palabras inglesas comunes de WeatherAPI.
 *
 * @module Core
 * @layer Core
 */

/**
 * Plantillas paramétricas de mensajes en español, organizadas por
 * dominio. Lambdas con parámetros tipados — el compilador detecta
 * desajustes al llamar.
 */
export const NotificationMessages = {
  /** Recordatorios de riego y eventos relacionados con lluvia. */
  watering: {
    pending:        (plantName: string) =>
      `Es hora de regar "${plantName}"`,
    rainPostponed:  (plantName: string, expectedPct: number) =>
      `Riego de "${plantName}" pospuesto: se esperan lluvias (${expectedPct}%)`,
    stormAlert:     (plantName: string, condition: string) =>
      `Alerta para "${plantName}": ${condition} esperada hoy`,
    rainConfirmed:  (plantName: string, rainfallMm: number, city?: string, speciesName?: string) =>
      `☔ Ayer llovió ${rainfallMm}mm${city ? ` en ${city}` : ''}. "${plantName}"${speciesName ? ` (${speciesName})` : ''} se considera regada.`,
    rainRollback:   (plantName: string, rainfallMm: number, city?: string) =>
      `↩️ La lluvia prevista${city ? ` en ${city}` : ''} no llegó (${rainfallMm}mm). "${plantName}" vuelve a su estado de riego anterior.`,
    rainConfirmedAdjustment: (plantName: string, rainfallMm: number, city?: string, speciesName?: string) =>
      `✅ Confirmado: "${plantName}"${speciesName ? ` (${speciesName})` : ''} recibió ${rainfallMm}mm ayer${city ? ` en ${city}` : ''}.`,
    simulatedRain:  (plantName: string, location: string) =>
      `Lluvia prevista en ${location} (80%). Se recomienda no regar "${plantName}" hoy.`,
    simulatedStorm: (plantName: string, location: string) =>
      `Tormenta prevista mañana en ${location}. Considera proteger "${plantName}".`,
  },

  /** Recordatorios de poda. */
  pruning: {
    pending: (plantName: string, speciesName: string) =>
      `Es tiempo de podar "${plantName}" (${speciesName})`,
  },

  /** Recordatorios de cosecha. */
  harvest: {
    pending: (plantName: string, speciesName: string) =>
      `Este mes puedes cosechar: "${plantName}" (${speciesName})`,
  },

  /** Resúmenes diarios y estado general. */
  dailySummary: {
    allCaughtUp: () => '🌿 ¡Todo al día! Tus plantas no necesitan atención hoy.',
    multipleAlerts: (count: number) =>
      `Tienes ${count} avisos hoy. Toca para verlos en la app.`,
    multipleAlertsRain: (count: number) =>
      `${count} alertas de lluvia. Revisa tus plantas de exterior.`,
    multipleAlertsStorm: (count: number) =>
      `${count} alertas de tormenta. Revisa tus plantas de exterior.`,
  },

  /** Acciones de admin sobre contenido del usuario. */
  admin: {
    postDeleted:    (reason?: string) =>
      `Tu publicación ha sido eliminada por moderación${reason ? `: ${reason}` : ''}.`,
    commentDeleted: (reason?: string) =>
      `Tu comentario ha sido eliminado por moderación${reason ? `: ${reason}` : ''}.`,
    contentRestored: (contentType: 'publicación' | 'comentario') =>
      `Tu ${contentType} ha sido aprobada tras revisión.`,
    warning: (text: string) => text, // mensaje custom del admin, ya en español
    ban: (until: Date) =>
      `Tu cuenta ha sido suspendida hasta el ${until.toLocaleDateString('es-ES')}.`,
  },
} as const;
