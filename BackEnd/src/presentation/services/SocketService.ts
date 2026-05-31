/**
 * @file SocketService.ts
 * @description Servicio de Socket.IO que gestiona la instancia del servidor en tiempo real.
 * Mantiene el mapa userId → socketIds para emisiones dirigidas a usuarios concretos.
 * Requiere inicialización explícita con el servidor HTTP mediante init().
 * @module Chat
 * @layer Presentation
 *
 * @injectable
 */

import { injectable } from 'inversify';
import { Server, Socket } from 'socket.io';
import type { Server as HttpServer } from 'http';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('SocketService');

/**
 * Servicio de Socket.IO centralizado.
 *
 * Gestiona la instancia del servidor Socket.IO y el mapa de presencia
 * userId → Set<socketId> para emitir eventos a usuarios concretos.
 *
 * TFG: implementación single-instance. Para multi-instancia se requeriría
 * el adaptador socket.io-redis.
 *
 * @injectable
 */
@injectable()
export class SocketService {
  private io: Server | null = null;

  /** Mapa de presencia: userId → conjunto de socketIds activos */
  private userSockets = new Map<string, Set<string>>();

  /**
   * Inicializa el servidor Socket.IO y lo adjunta al servidor HTTP.
   * Debe llamarse en bootstrap() después de app.listen().
   *
   * @param httpServer — Instancia del servidor HTTP de Node.js.
   */
  init(httpServer: HttpServer): void {
    this.io = new Server(httpServer, {
      cors: {
        origin: '*',
        methods: ['GET', 'POST'],
      },
      // TFG: transports explícitos para compatibilidad con clientes Flutter
      transports: ['websocket', 'polling'],
      // Decisión #223 / F11-FOLLOWUP: timeouts agresivos para que el server
      // detecte rápidamente sockets huérfanos (app cerrada en móvil sin
      // disconnect limpio). Defaults socket.io: 25 s/20 s → ~45 s para
      // declarar offline. Con 15 s/10 s declaramos offline en ~25 s, lo
      // que reduce la ventana en la que un mensaje se envía via socket a
      // un proceso pausado en lugar de via push FCM. La defensa principal
      // es el `didChangeAppLifecycleState` del frontend (disconnect
      // explícito en `paused`); estos timeouts son backup por si el
      // observer no llegase a disparar (proceso killed sin lifecycle).
      pingInterval: 15000,
      pingTimeout:  10000,
    });

    logger.info('SocketService inicializado y adjunto al servidor HTTP');
  }

  /**
   * Devuelve la instancia del servidor Socket.IO.
   * Retorna null si init() no ha sido llamado todavía.
   *
   * @returns Instancia de Server o null.
   */
  getIO(): Server | null {
    return this.io;
  }

  /**
   * Registra la asociación userId → socketId cuando un usuario se conecta.
   *
   * @param userId — ID del usuario autenticado.
   * @param socket — Socket conectado.
   */
  registerSocket(userId: string, socket: Socket): void {
    if (!this.userSockets.has(userId)) {
      this.userSockets.set(userId, new Set());
    }
    this.userSockets.get(userId)!.add(socket.id);
    logger.debug(`Socket registrado: user=${userId} socket=${socket.id}`);
  }

  /**
   * Elimina la asociación userId → socketId cuando un usuario se desconecta.
   *
   * @param userId — ID del usuario autenticado.
   * @param socketId — ID del socket desconectado.
   */
  removeSocket(userId: string, socketId: string): void {
    const sockets = this.userSockets.get(userId);
    if (sockets) {
      sockets.delete(socketId);
      if (sockets.size === 0) {
        this.userSockets.delete(userId);
      }
    }
    logger.debug(`Socket eliminado: user=${userId} socket=${socketId}`);
  }

  /**
   * Emite un evento a todos los sockets activos de un usuario concreto.
   * Si el usuario no tiene sockets conectados, la operación es un no-op.
   *
   * @param userId — ID del usuario destinatario.
   * @param event — Nombre del evento Socket.IO.
   * @param payload — Datos del evento.
   */
  emitToUser(userId: string, event: string, payload: unknown): void {
    if (!this.io) {
      logger.warn(`emitToUser ignorado: SocketService no inicializado (userId=${userId}, event=${event})`);
      return;
    }

    const sockets = this.userSockets.get(userId);
    if (!sockets || sockets.size === 0) {
      // El usuario no está conectado — el mensaje se servirá en el siguiente polling
      logger.debug(`Usuario ${userId} sin sockets activos — evento '${event}' no emitido en tiempo real`);
      return;
    }

    for (const socketId of sockets) {
      this.io.to(socketId).emit(event, payload);
    }
    logger.debug(`Evento '${event}' emitido a ${sockets.size} socket(s) del usuario ${userId}`);
  }

  /**
   * Emite un evento a todos los sockets conectados (broadcast global).
   * Útil para notificar cambios de estado público (likes, comentarios, etc.).
   *
   * @param event — Nombre del evento Socket.IO.
   * @param payload — Datos del evento.
   */
  broadcast(event: string, payload: unknown): void {
    if (!this.io) {
      logger.warn(`broadcast ignorado: SocketService no inicializado (event=${event})`);
      return;
    }
    this.io.emit(event, payload);
    logger.debug(`Broadcast '${event}' emitido a todos los clientes`);
  }

  /**
   * Comprueba si un usuario tiene al menos un socket conectado.
   *
   * @param userId — ID del usuario.
   * @returns true si el usuario está online.
   */
  isOnline(userId: string): boolean {
    const sockets = this.userSockets.get(userId);
    return !!sockets && sockets.size > 0;
  }
}
