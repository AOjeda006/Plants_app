/**
 * @file FirebaseAdminDataSource.ts
 * @description Datasource de Firebase Admin SDK para Cloud Messaging (FCM).
 * Inicializa el SDK con el archivo de cuenta de servicio y expone métodos
 * para enviar notificaciones push individuales y en lote.
 * TFG: si FCM_SERVICE_ACCOUNT_JSON no está definida, el datasource opera en
 *      modo mock y registra las notificaciones sin enviarlas realmente.
 * @module Reminders
 * @layer Data
 *
 * @injectable
 */

import { injectable } from 'inversify';
import * as admin from 'firebase-admin';
import { firebaseConfig } from '../../../core/config/firebase.config.js';
import { createLogger } from '../../../core/logger.js';

const logger = createLogger('FirebaseAdminDataSource');

/** Parámetros mínimos para una notificación push */
export interface PushNotificationPayload {
  token:   string;
  title:   string;
  body:    string;
  data?:   Record<string, string>;
  /**
   * Clave de colapso para agrupar pushes consecutivos relativos al mismo
   * "tema" (p. ej. chat con un mismo receptor). En Android se mapea a
   * `android.collapseKey`; en iOS a la cabecera `apns-collapse-id`. Si
   * está presente, el SO sustituye la notificación previa con el mismo
   * collapseKey en lugar de apilarlas.
   */
  collapseKey?: string;
}

/**
 * Datasource de Firebase Admin SDK — envío de notificaciones push.
 *
 * @injectable
 */
@injectable()
export class FirebaseAdminDataSource {

  private readonly messaging: admin.messaging.Messaging | null = null;

  constructor() {
    if (firebaseConfig.enabled) {
      try {
        // Inicializar solo si no hay una instancia ya creada (hot-reload en dev)
        if (!admin.apps.length) {
          // Soporta credencial inline (Render env var con JSON) o path a
          // archivo (modo local).
          const credential = firebaseConfig.serviceAccountInline
            ? admin.credential.cert(firebaseConfig.serviceAccountInline as admin.ServiceAccount)
            : admin.credential.cert(firebaseConfig.serviceAccountPath);
          admin.initializeApp({ credential });
        }
        this.messaging = admin.messaging();
        logger.info('FirebaseAdminDataSource: SDK inicializado correctamente');
      } catch (err) {
        logger.error(`FirebaseAdminDataSource: error al inicializar Firebase SDK — ${(err as Error).message}`);
        // TFG: no relanzar; operamos en modo degradado (mock)
      }
    } else {
      logger.warn('FirebaseAdminDataSource: FCM_SERVICE_ACCOUNT_JSON no definido — modo mock activo');
    }
  }

  /**
   * Indica si el SDK está inicializado y hay envío real de pushes.
   * Se utiliza desde NotificationService para emitir warnings claros si
   * el modo mock está activo en producción.
   */
  get isReady(): boolean {
    return this.messaging !== null;
  }

  /**
   * Envía una notificación push a un dispositivo específico.
   * Si el SDK no está disponible, registra el intento en modo mock.
   *
   * @param payload — Token del dispositivo, título, cuerpo y datos opcionales.
   * @returns messageId de FCM, o 'mock' en modo TFG.
   */
  async sendPushNotification(payload: PushNotificationPayload): Promise<string> {
    if (!this.messaging) {
      // TFG: modo mock — simular envío sin llamada real a FCM
      logger.debug(`[MOCK FCM] → token=${payload.token.substring(0, 10)}… title="${payload.title}"`);
      return 'mock-message-id';
    }

    const messageId = await this.messaging.send({
      token:        payload.token,
      notification: { title: payload.title, body: payload.body },
      data:         payload.data,
      android: {
        priority:     'high',
        notification: { channelId: 'plants_app_notifications', sound: 'default' },
        // Si hay collapseKey, agrupar bajo la misma "ranura" del SO. Sin
        // él, cada push acumula su propia card.
        ...(payload.collapseKey ? { collapseKey: payload.collapseKey } : {}),
      },
      apns: {
        payload: { aps: { sound: 'default' } },
        ...(payload.collapseKey
          ? { headers: { 'apns-collapse-id': payload.collapseKey } }
          : {}),
      },
    });

    // Log a nivel info para que sea visible en producción Render: si FCM
    // devuelve messageId, el push fue ACEPTADO por Firebase. Si la
    // notificación no llega al dispositivo, la causa está en
    // permisos del SO / ahorro de batería / token stale.
    logger.info(`FCM accepted: messageId=${messageId} token=…${payload.token.slice(-6)} title="${payload.title}"`);
    return messageId;
  }

  /**
   * Envía notificaciones push en lote (hasta 500 tokens por llamada FCM).
   * Internamente usa sendEach para tolerar fallos parciales.
   *
   * @param payloads — Lista de notificaciones individuales.
   * @returns Número de notificaciones enviadas con éxito.
   */
  async sendBatch(payloads: PushNotificationPayload[]): Promise<number> {
    if (!payloads.length) return 0;

    if (!this.messaging) {
      logger.debug(`[MOCK FCM] sendBatch ${payloads.length} notificaciones`);
      return payloads.length;
    }

    const messages: admin.messaging.Message[] = payloads.map((p) => ({
      token:        p.token,
      notification: { title: p.title, body: p.body },
      data:         p.data,
      android:      { priority: 'high' },
      apns:         { payload: { aps: { sound: 'default' } } },
    }));

    // sendEach tolera fallos por token inválido sin abortar todo el lote
    const response = await this.messaging.sendEach(messages);
    const successCount = response.successCount;

    if (response.failureCount > 0) {
      logger.warn(`FCM sendBatch: ${response.failureCount} fallos de ${payloads.length} notificaciones`);
    }

    logger.debug(`FCM sendBatch: ${successCount}/${payloads.length} enviadas`);
    return successCount;
  }
}
