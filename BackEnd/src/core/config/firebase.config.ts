/**
 * @file firebase.config.ts
 * @description Configuración de Firebase Admin SDK para Cloud Messaging (FCM).
 * Soporta dos formatos para la credencial:
 *   1. Path al archivo JSON descargado de Firebase Console (uso local).
 *   2. JSON inline (string) directamente en la env var FCM_SERVICE_ACCOUNT_JSON
 *      (uso típico en Render: la env var contiene el contenido completo del
 *      JSON, sin tener que subir el archivo).
 * @module Core
 * @layer Core
 */

import 'dotenv/config';
import path from 'path';

const RAW = process.env['FCM_SERVICE_ACCOUNT_JSON']?.trim() ?? '';

/**
 * Detecta si la env var contiene un JSON inline ({...}) o un path a archivo.
 * Heurística: el JSON empieza por `{` tras trim.
 */
const isInlineJson = RAW.startsWith('{');

/**
 * Si es JSON inline, intenta parsearlo. En caso de error, deja el credential
 * como null para que el datasource caiga en modo mock.
 */
let inlineCredential: object | null = null;
if (isInlineJson) {
  try {
    inlineCredential = JSON.parse(RAW) as object;
  } catch {
    // Ignorar; el datasource lo detectará como ausente y avisará en log.
    inlineCredential = null;
  }
}

export const firebaseConfig = {
  /**
   * Ruta al archivo JSON de cuenta de servicio (modo local). Se resuelve
   * como ruta absoluta desde la raíz del proyecto. Vacío si se usa el
   * modo inline.
   */
  serviceAccountPath: !isInlineJson && RAW
    ? path.resolve(process.cwd(), RAW)
    : '',

  /**
   * JSON inline parseado. null si no se proporcionó modo inline.
   */
  serviceAccountInline: inlineCredential,

  /**
   * Indica si Firebase debe inicializarse (presencia de credencial válida
   * en cualquiera de los dos formatos).
   */
  enabled: Boolean(RAW) && (isInlineJson ? inlineCredential !== null : true),
} as const;
