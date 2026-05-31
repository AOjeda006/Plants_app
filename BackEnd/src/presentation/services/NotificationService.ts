/**
 * @file NotificationService.ts
 * @description Servicio de notificaciones push.
 * Abstrae FirebaseAdminDataSource para el resto de la aplicación.
 * Expone sendToToken() para notificaciones individuales y
 * sendToUser() para cuando se disponga del token FCM del usuario.
 * TFG: los tokens FCM no se persisten en la BD en esta fase;
 *      sendToUser espera recibir el token directamente del caller.
 * @module Reminders
 * @layer Presentation
 *
 * @injectable
 * @dependencies FirebaseAdminDataSource
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../core/types.js';
import { FirebaseAdminDataSource, PushNotificationPayload } from '../../data/datasources/external/FirebaseAdminDataSource.js';
import type { IUserRepository } from '../../domain/repositories/IUserRepository.js';
import { SocketService } from './SocketService.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('NotificationService');

/** Códigos de error FCM que indican que el token ya no es válido. */
const FCM_INVALID_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered', // UNREGISTERED
  'messaging/invalid-registration-token',
  'messaging/invalid-argument',
]);

/**
 * Solicitud de envío push agrupada. Agrupar los parámetros en este objeto
 * facilita la lectura de los call sites frente a firmas con muchos
 * parámetros opcionales posicionales y permite añadir campos futuros sin
 * tocar las firmas.
 */
export interface PushRequest {
  /** Título visible de la notificación (Android/iOS). */
  title:        string;
  /** Cuerpo de la notificación. Cadena vacía permitida (los push de chat
   *  no muestran preview por privacidad). */
  body:         string;
  /** Pares clave-valor opcionales para deep-link y filtros frontend. */
  data?:        Record<string, string>;
  /** Si presente, el SO sustituye la card anterior con el mismo
   *  collapseKey en lugar de apilar (Android android.collapseKey +
   *  cabecera APNs apns-collapse-id). */
  collapseKey?: string;
}

/**
 * Variante de `PushRequest` orientada al usuario: añade el `userId`
 * opcional para la verificación de `preferences.pushNotifications` y para
 * la limpieza de `User.fcmToken` ante códigos FCM de token inválido.
 */
export interface PushToUserRequest extends PushRequest {
  /** ID del usuario destinatario. Si se proporciona, se re-verifica
   *  `preferences.pushNotifications` con el user freshly fetched antes
   *  de invocar FCM, y se intenta limpieza de token tras códigos
   *  UNREGISTERED/INVALID_TOKEN. */
  userId?: string;
}

/**
 * Servicio de notificaciones push — fachada sobre FirebaseAdminDataSource.
 *
 * @injectable
 * @dependencies FirebaseAdminDataSource
 */
@injectable()
export class NotificationService {
  constructor(
    @inject(TYPES.FirebaseDataSource) private readonly firebase: FirebaseAdminDataSource,
    @inject(TYPES.IUserRepository)    private readonly userRepo: IUserRepository,
    @inject(TYPES.SocketService)      private readonly socketService: SocketService,
  ) {}

  /**
   * Envía una notificación push a un token FCM concreto.
   *
   * @param token — Token FCM del dispositivo destino.
   * @param req — Solicitud push agrupada (title, body, data?, collapseKey?).
   * @returns messageId de FCM o 'mock' en modo TFG.
   */
  async sendToToken(token: string, req: PushRequest): Promise<string> {
    const payload: PushNotificationPayload = {
      token,
      title: req.title,
      body:  req.body,
      data:  req.data,
      ...(req.collapseKey ? { collapseKey: req.collapseKey } : {}),
    };
    try {
      return await this.firebase.sendPushNotification(payload);
    } catch (err) {
      logger.error(`NotificationService.sendToToken error: ${(err as Error).message}`);
      throw err;
    }
  }

  /**
   * Envía una notificación a un usuario usando su token FCM.
   * TFG: el token debe ser provisto por el caller (no se recupera de BD).
   *
   * @param fcmToken — Token FCM almacenado en el dispositivo del usuario.
   * @param req — Solicitud push para usuario (title, body, data?, userId?, collapseKey?).
   */
  async sendToUser(fcmToken: string, req: PushToUserRequest): Promise<void> {
    if (!fcmToken) {
      logger.warn('NotificationService.sendToUser: fcmToken vacío — notificación omitida');
      return;
    }

    if (req.userId && !(await this._userAcceptsPush(req.userId))) return;

    try {
      await this.sendToToken(fcmToken, req);
      logger.info(`Notificación enviada al usuario (token …${fcmToken.slice(-6)}): "${req.title}"`);
    } catch (err) {
      await this._handlePushFailure(err, req.userId, fcmToken);
      // Push fallido NO debe romper el flujo principal: la notificación
      // ya se persistió en MongoDB y se emitió por Socket.IO.
    }
  }

  /**
   * Verifica `preferences.pushNotifications` con el user freshly fetched
   * antes de invocar FCM. Devuelve false si el push debe omitirse
   * (preferencia desactivada o user no encontrado).
   * @private
   */
  private async _userAcceptsPush(userId: string): Promise<boolean> {
    const user = await this.userRepo.findById(userId).catch(() => null);
    if (user && !user.canReceiveNotifications()) {
      logger.debug(`Push skipped: user ${userId} has notifications disabled or no fcmToken`);
      return false;
    }
    return true;
  }

  /**
   * Maneja errores del SDK FCM: si el token es inválido
   * (UNREGISTERED/INVALID_TOKEN/INVALID_ARGUMENT) limpia `User.fcmToken`
   * y emite `fcm:invalid` por socket para que el frontend regenere y
   * re-registre el token.
   * @private
   */
  private async _handlePushFailure(
    err: unknown,
    userId: string | undefined,
    fcmToken: string,
  ): Promise<void> {
    const code = (err as { code?: string }).code ?? '';
    if (!userId || !FCM_INVALID_TOKEN_CODES.has(code)) return;

    logger.warn(`fcmToken inválido (${code}) para userId=${userId} (…${fcmToken.slice(-6)}) — limpiando del perfil`);
    try {
      await this.userRepo.update(userId, { fcmToken: '' });
    } catch (cleanupErr) {
      logger.error(`Error al limpiar fcmToken: ${(cleanupErr as Error).message}`);
    }
    try {
      this.socketService.emitToUser(userId, 'fcm:invalid', { reason: code });
    } catch (emitErr) {
      logger.warn(`emit fcm:invalid failed for ${userId}: ${(emitErr as Error).message}`);
    }
  }
}
