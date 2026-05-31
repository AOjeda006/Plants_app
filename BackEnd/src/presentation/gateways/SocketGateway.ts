/**
 * @file SocketGateway.ts
 * @description Gateway de Socket.IO que gestiona los eventos en tiempo real del chat.
 * Autentica cada conexión vía JWT y delega el procesamiento de eventos al SocketService
 * y los use cases correspondientes.
 * @module Chat
 * @layer Presentation
 *
 * @injectable
 * @dependencies SocketService, JwtService, ISendMessageUseCase, IMarkMessagesReadUseCase
 */

import { injectable, inject } from 'inversify';
import type { Socket } from 'socket.io';
import { TYPES } from '../../core/types.js';
import { SocketService } from '../services/SocketService.js';
import { JwtService } from '../services/JwtService.js';
import type { ISendMessageUseCase } from '../../domain/interfaces/usecases/chat/ISendMessageUseCase.js';
import type { IMarkMessagesAsReadUseCase } from '../../domain/interfaces/usecases/chat/IMarkMessagesAsReadUseCase.js';
import type { IMessageRepository } from '../../domain/repositories/IMessageRepository.js';
import type { IUserRepository } from '../../domain/repositories/IUserRepository.js';
import type { SendMessageRequestDto } from '../../domain/dtos/chat/send-message-request.dto.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('SocketGateway');

/**
 * Payload del evento 'message:send' emitido por el cliente.
 */
interface MessageSendPayload {
  conversationId: string;
  text?: string;
  contentMeta?: Record<string, unknown>;
  tempId?: string;
}

/**
 * Payload del evento 'message:ack' emitido por el cliente para confirmar entrega.
 */
interface MessageAckPayload {
  messageId: string;
  conversationId: string;
}

/**
 * Payload del evento 'typing' emitido por el cliente.
 */
interface TypingPayload {
  conversationId: string;
  receiverId: string;
  isTyping: boolean;
}

/**
 * Gateway de Socket.IO para eventos de chat en tiempo real.
 *
 * Responsabilidades:
 * - Autenticar el handshake con JWT.
 * - Registrar y eliminar sockets en SocketService.
 * - Procesar eventos: message:send, message:ack, typing.
 * - Emitir eventos de presencia a otros usuarios.
 *
 * TFG: No se implementa persistencia de presencia — el estado online es solo en memoria.
 *
 * @injectable
 * @dependencies SocketService, JwtService, ISendMessageUseCase, IMarkMessagesReadUseCase, IMessageRepository
 */
@injectable()
export class SocketGateway {
  constructor(
    @inject(TYPES.SocketService)             private readonly socketService: SocketService,
    @inject(TYPES.JwtService)               private readonly jwtService: JwtService,
    @inject(TYPES.ISendMessageUseCase)      private readonly sendMessage: ISendMessageUseCase,
    @inject(TYPES.IMarkMessagesReadUseCase) private readonly markRead: IMarkMessagesAsReadUseCase,
    @inject(TYPES.IMessageRepository)       private readonly messageRepo: IMessageRepository,
    @inject(TYPES.IUserRepository)          private readonly userRepo: IUserRepository,
  ) {}

  /**
   * Inicializa los listeners de eventos sobre la instancia io de SocketService.
   * Debe llamarse en bootstrap() después de socketService.init(httpServer).
   */
  init(): void {
    const io = this.socketService.getIO();
    if (!io) {
      logger.error('SocketGateway.init() llamado antes de SocketService.init() — abortando');
      return;
    }

    // Middleware de autenticación para cada conexión nueva.
    // Acepta el token desde `auth.token` (modo recomendado socket.io v3+)
    // O desde `query.token` (compatibilidad con clientes que usan setQuery,
    // p.ej. socket_io_client de Flutter). Imprescindible que ambos modos
    // funcionen — fix del chat en tiempo real.
    io.use((socket, next) => {
      const authToken  = socket.handshake.auth['token']  as string | undefined;
      const queryToken = socket.handshake.query['token'] as string | undefined;
      const token      = authToken ?? queryToken;
      if (!token) {
        logger.warn(`Conexión rechazada — sin token (socketId=${socket.id})`);
        return next(new Error('Token no proporcionado'));
      }

      try {
        const payload = this.jwtService.verify(token);
        // Adjuntar el userId al socket para uso en handlers
        (socket as Socket & { userId: string }).userId = payload.userId;
        next();
      } catch {
        logger.warn(`Conexión rechazada — token inválido (socketId=${socket.id})`);
        next(new Error('Token inválido o expirado'));
      }
    });

    io.on('connection', (socket) => {
      this.handleConnection(socket as Socket & { userId: string });
    });

    logger.info('SocketGateway inicializado — listeners activos');
  }

  /**
   * Gestiona una nueva conexión autenticada.
   * Registra el socket y adjunta handlers de eventos.
   *
   * @param socket — Socket autenticado con userId adjunto.
   * @private
   */
  private handleConnection(socket: Socket & { userId: string }): void {
    const { userId } = socket;
    this.socketService.registerSocket(userId, socket);
    logger.info(`Usuario conectado: userId=${userId} socketId=${socket.id}`);

    // Resetear `lastChatPushTitle` cuando el usuario abre la app (socket
    // conecta). Esto permite que el siguiente push de chat se envíe aunque
    // sea el mismo título que el último — el "ciclo de dedup" termina
    // aquí. Best-effort: si falla, la próxima push podría duplicarse pero
    // no rompe el chat.
    this.userRepo.update(userId, { lastChatPushTitle: null }).catch((err) => {
      logger.warn(`No se pudo resetear lastChatPushTitle para ${userId}: ${(err as Error).message}`);
    });

    // Notificar presencia online al propio cliente
    socket.emit('presence:online', { userId });

    // Eventos del ciclo de vida del socket
    socket.on('disconnect', () => this.handleDisconnect(socket));
    socket.on('message:send', (payload: MessageSendPayload) => this.handleMessageSend(socket, payload));
    socket.on('message:ack',  (payload: MessageAckPayload)  => this.handleMessageAck(socket, payload));
    socket.on('typing',       (payload: TypingPayload)      => this.handleTyping(socket, payload));
  }

  /**
   * Gestiona la desconexión de un socket.
   * Elimina el socket del mapa de presencia.
   *
   * @param socket — Socket desconectado.
   * @private
   */
  private handleDisconnect(socket: Socket & { userId: string }): void {
    const { userId } = socket;
    this.socketService.removeSocket(userId, socket.id);
    logger.info(`Usuario desconectado: userId=${userId} socketId=${socket.id}`);
  }

  /**
   * Gestiona el evento 'message:send' del cliente.
   * Persiste el mensaje vía SendMessageUseCase y confirma al emisor.
   *
   * @param socket — Socket del emisor.
   * @param payload — Datos del mensaje a enviar.
   * @private
   */
  private async handleMessageSend(
    socket: Socket & { userId: string },
    payload: MessageSendPayload,
  ): Promise<void> {
    const { userId } = socket;
    try {
      const dto: SendMessageRequestDto = {
        text:        payload.text,
        contentMeta: payload.contentMeta,
        tempId:      payload.tempId,
      };

      const message = await this.sendMessage.execute(payload.conversationId, userId, dto);

      // Confirmar al emisor con el mensaje persistido (incluye id real + tempId)
      socket.emit('message:ack', message);
      logger.debug(`message:send procesado: conversationId=${payload.conversationId} senderId=${userId}`);
    } catch (err) {
      const error = err instanceof Error ? err.message : 'Error al enviar mensaje';
      // No se emite `socket.emit('message:error', ...)` porque el envío
      // real de mensajes va por HTTP `POST /chat/:id/messages`, no por
      // socket — handleMessageSend queda como handler defensivo por si en
      // el futuro se reabre el flujo socket. Si eso ocurre, hay que añadir
      // listener frontend ANTES de re-introducir el emit.
      logger.warn(`Error en message:send: userId=${userId} error=${error}`);
    }
  }

  /**
   * Gestiona el evento 'message:ack' del cliente cuando recibe un mensaje.
   * Persiste el estado 'delivered' en BD y notifica al emisor original
   * para que actualice los ticks de entrega en su UI (✓ → ✓✓).
   *
   * @param socket — Socket del receptor que confirma recepción.
   * @param payload — Identificadores del mensaje recibido.
   * @private
   */
  private async handleMessageAck(
    socket: Socket & { userId: string },
    payload: MessageAckPayload,
  ): Promise<void> {
    try {
      await this.messageRepo.updateStatus(payload.messageId, 'delivered');

      // Buscar al emisor original del mensaje para notificarle la entrega
      const msg = await this.messageRepo.findByTempId(payload.messageId);
      if (msg) {
        this.socketService.emitToUser(msg.senderId, 'message:delivered', {
          messageId: payload.messageId,
          conversationId: payload.conversationId,
        });
      }

      logger.debug(
        `message:ack procesado → delivered: userId=${socket.userId} messageId=${payload.messageId}`,
      );
    } catch (err) {
      logger.warn(`Error al procesar message:ack: ${(err as Error).message}`);
    }
  }

  /**
   * Gestiona el evento 'typing' del cliente.
   * Reenvía el indicador de escritura al receptor si está online.
   *
   * @param socket — Socket del usuario que escribe.
   * @param payload — Datos del indicador de escritura.
   * @private
   */
  private handleTyping(
    socket: Socket & { userId: string },
    payload: TypingPayload,
  ): void {
    const { userId } = socket;
    // Emitir el evento de escritura al receptor
    this.socketService.emitToUser(payload.receiverId, 'typing', {
      conversationId: payload.conversationId,
      senderId:       userId,
      isTyping:       payload.isTyping,
    });
    logger.debug(`typing: senderId=${userId} receiverId=${payload.receiverId} isTyping=${payload.isTyping}`);
  }
}
