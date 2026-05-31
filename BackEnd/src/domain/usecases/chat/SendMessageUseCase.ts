/**
 * @file SendMessageUseCase.ts
 * @description Caso de uso para enviar un mensaje en una conversación.
 * Persiste el mensaje, actualiza lastMessageAt de la conversación,
 * emite el evento Socket.IO al destinatario en tiempo real y, si el
 * destinatario está offline, envía una notificación push via FCM.
 * @module Chat
 * @layer Domain
 *
 * @implements {ISendMessageUseCase}
 * @injectable
 * @dependencies IConversationRepository, IMessageRepository, IUserRepository,
 *              IMessageMapper, SocketService, NotificationService
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { ISendMessageUseCase } from '../../interfaces/usecases/chat/ISendMessageUseCase.js';
import type { IConversationRepository } from '../../repositories/IConversationRepository.js';
import type { IMessageRepository } from '../../repositories/IMessageRepository.js';
import type { IUserRepository } from '../../repositories/IUserRepository.js';
import type { IMessageMapper } from '../../../data/IMappers/IMessageMapper.js';
import type { SendMessageRequestDto } from '../../dtos/chat/send-message-request.dto.js';
import type { MessageResponseDTO } from '../../dtos/chat/message-response.dto.js';
import { SocketService } from '../../../presentation/services/SocketService.js';
import { NotificationService } from '../../../presentation/services/NotificationService.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';
import { ForbiddenException } from '../../../core/exceptions/ForbiddenException.js';
import { createLogger } from '../../../core/logger.js';

const logger = createLogger('SendMessageUseCase');

/**
 * Envía un mensaje en una conversación.
 * Persiste, actualiza lastMessageAt, emite en tiempo real y,
 * si el destinatario está offline y tiene FCM token, envía push.
 *
 * @implements {ISendMessageUseCase}
 * @injectable
 * @dependencies IConversationRepository, IMessageRepository, IUserRepository,
 *              IMessageMapper, SocketService, NotificationService
 */
@injectable()
export class SendMessageUseCase implements ISendMessageUseCase {
  constructor(
    @inject(TYPES.IConversationRepository) private readonly conversationRepo: IConversationRepository,
    @inject(TYPES.IMessageRepository)      private readonly messageRepo: IMessageRepository,
    @inject(TYPES.IUserRepository)         private readonly userRepo: IUserRepository,
    @inject(TYPES.IMessageMapper)          private readonly mapper: IMessageMapper,
    @inject(TYPES.SocketService)           private readonly socketService: SocketService,
    @inject(TYPES.NotificationService)     private readonly notificationService: NotificationService,
  ) {}

  /**
   * @param conversationId — ID de la conversación donde se envía el mensaje.
   * @param senderId — ID del usuario emisor.
   * @param dto — Datos del mensaje (texto, contentMeta, tempId).
   * @returns MessageResponseDTO del mensaje persistido.
   * @throws {NotFoundException} Si la conversación no existe.
   * @throws {ForbiddenException} Si el emisor no es participante.
   */
  async execute(
    conversationId: string,
    senderId: string,
    dto: SendMessageRequestDto,
  ): Promise<MessageResponseDTO> {
    // Descompuesto en helpers privados para mantener `execute` < 25 líneas.
    // Cada helper tiene una responsabilidad clara y se puede leer y
    // testear aislado.
    const conversation = await this._loadAndAuthorize(conversationId, senderId);
    const receiverId   = conversation.getOtherParticipantId(senderId) ?? '';
    const sender       = await this.userRepo.findById(senderId);

    const message = await this.messageRepo.create({
      conversationId,
      senderId,
      receiverId,
      text:        dto.text,
      contentMeta: dto.contentMeta as Record<string, unknown> | undefined,
      tempId:      dto.tempId,
    });
    await this.conversationRepo.updateLastMessageAt(conversationId, message.createdAt);

    const responseDTO = this.mapper.toResponseDTO(message, sender?.name ?? 'Usuario eliminado');
    this.socketService.emitToUser(receiverId, 'message:received', responseDTO);

    const recipientOnline = this.socketService.isOnline(receiverId);
    if (recipientOnline) {
      await this._markAsDelivered(message.id, responseDTO);
    } else {
      await this._pushIfReceiverOffline(receiverId, sender?.name, conversationId, senderId);
    }
    return responseDTO;
  }

  /**
   * Carga la conversación y verifica que `senderId` sea participante.
   * @private
   */
  private async _loadAndAuthorize(conversationId: string, senderId: string) {
    const conversation = await this.conversationRepo.findById(conversationId);
    if (!conversation) throw new NotFoundException('Conversation', conversationId);
    if (!conversation.participants.includes(senderId)) {
      throw new ForbiddenException('No eres participante de esta conversación');
    }
    return conversation;
  }

  /**
   * Si el destinatario está online vía socket, persiste el status
   * 'delivered' y lo refleja en la respuesta REST. Esto evita race
   * conditions con el `message:received` ya emitido.
   * @private
   */
  private async _markAsDelivered(
    messageId: string,
    responseDTO: MessageResponseDTO,
  ): Promise<void> {
    await this.messageRepo.updateStatus(messageId, 'delivered');
    responseDTO.status = 'delivered';
    logger.debug(`Mensaje ${messageId} → delivered (destinatario online)`);
  }

  /**
   * Envía push FCM agrupado al receptor si está offline y tiene
   * preferencia push activada. Agrega por sender (un único push por
   * receptor con título "[Nombre]" o "Varios usuarios") y envía cuerpo
   * vacío por privacidad (el contenido del mensaje nunca sale del backend).
   * Best-effort: cualquier fallo solo se loguea.
   * @private
   */
  private async _pushIfReceiverOffline(
    receiverId: string,
    senderName: string | undefined,
    conversationId: string,
    senderId: string,
  ): Promise<void> {
    const receiver = await this.userRepo.findById(receiverId);
    if (!receiver?.canReceiveNotifications()) {
      logger.debug(`Usuario ${receiverId} offline sin FCM token — push omitida`);
      return;
    }

    const title = await this._buildAggregatedPushTitle(receiverId, senderId, senderName);

    // Dedup por título: si el receptor ya recibió un push con este mismo
    // título mientras estaba offline, no volver a enviar (evita spam de
    // vibraciones cuando llegan varios mensajes seguidos del mismo sender
    // o cuando "Varios usuarios" ya es la respuesta correcta y nada
    // cambia). El reset a null lo hace `SocketGateway.handleConnection`
    // cuando el usuario vuelve a abrir la app.
    if (receiver.lastChatPushTitle === title) {
      logger.debug(
        `Push omitida (dedup): título "${title}" ya enviado a userId=${receiverId} desde la última apertura de la app`,
      );
      return;
    }

    const collapseKey = `chat_${receiverId}`;

    // Pasamos userId para que `sendToUser` re-verifique
    // `preferences.pushNotifications` con el user freshly fetched antes
    // de llamar a FCM (defensa en profundidad).
    await this.notificationService.sendToUser(receiver.fcmToken!, {
      title,
      body:        '',
      data:        { conversationId, type: 'chat_message' },
      userId:      receiverId,
      collapseKey,
    }).catch((err) => {
      // TFG: no bloquear el flujo de envío si falla la notificación push
      logger.warn(`Push omitida para usuario ${receiverId}: ${(err as Error).message}`);
    });

    // Persistir el título enviado para la dedup. Best-effort: si falla,
    // el siguiente push podría duplicar pero no rompe el flujo de envío.
    await this.userRepo.update(receiverId, { lastChatPushTitle: title }).catch((err) => {
      logger.warn(`No se pudo persistir lastChatPushTitle para ${receiverId}: ${(err as Error).message}`);
    });
  }

  /**
   * Calcula el título del push agregando los senders pendientes. Si el
   * receptor solo tiene mensajes sin leer de este sender → "Tienes nuevos
   * mensajes de [Nombre]". Si hay otros pendientes → "Tienes nuevos
   * mensajes de Varios usuarios". Tolerante a fallo del repo: degrada a
   * "[Nombre]" usando solo el sender actual.
   * @private
   */
  private async _buildAggregatedPushTitle(
    receiverId: string,
    senderId: string,
    senderName: string | undefined,
  ): Promise<string> {
    const unreadSenderIds = await this.messageRepo
      .findDistinctUnreadSenderIds(receiverId)
      .catch(() => [senderId]);
    const distinctSenders = new Set<string>(unreadSenderIds);
    distinctSenders.add(senderId); // el mensaje recién creado cuenta como pendiente
    const safeName = senderName?.trim() || 'Usuario';
    return distinctSenders.size > 1
      ? 'Tienes nuevos mensajes de Varios usuarios'
      : `Tienes nuevos mensajes de ${safeName}`;
  }
}
