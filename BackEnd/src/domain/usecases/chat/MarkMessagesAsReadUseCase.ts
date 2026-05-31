/**
 * @file MarkMessagesAsReadUseCase.ts
 * @description Caso de uso para marcar todos los mensajes no leídos de una conversación como leídos.
 * Registrado con el símbolo TYPES.IMarkMessagesReadUseCase.
 * @module Chat
 * @layer Domain
 *
 * @implements {IMarkMessagesAsReadUseCase}
 * @injectable
 * @dependencies IConversationRepository, IMessageRepository
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { IMarkMessagesAsReadUseCase } from '../../interfaces/usecases/chat/IMarkMessagesAsReadUseCase.js';
import type { IConversationRepository } from '../../repositories/IConversationRepository.js';
import type { IMessageRepository } from '../../repositories/IMessageRepository.js';
import { SocketService } from '../../../presentation/services/SocketService.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';
import { ForbiddenException } from '../../../core/exceptions/ForbiddenException.js';
import { createLogger } from '../../../core/logger.js';

const logger = createLogger('MarkMessagesAsReadUseCase');

/**
 * Marca como leídos todos los mensajes no leídos de una conversación para el usuario.
 * Emite un evento Socket.IO 'message:read' al otro participante para que
 * actualice los ticks de lectura en su UI.
 *
 * @implements {IMarkMessagesAsReadUseCase}
 * @injectable
 * @dependencies IConversationRepository, IMessageRepository, SocketService
 */
@injectable()
export class MarkMessagesAsReadUseCase implements IMarkMessagesAsReadUseCase {
  constructor(
    @inject(TYPES.IConversationRepository) private readonly conversationRepo: IConversationRepository,
    @inject(TYPES.IMessageRepository)      private readonly messageRepo: IMessageRepository,
    @inject(TYPES.SocketService)           private readonly socketService: SocketService,
  ) {}

  /**
   * @param conversationId — ID de la conversación.
   * @param userId — ID del usuario que marca como leídos.
   * @throws {NotFoundException} Si la conversación no existe.
   * @throws {ForbiddenException} Si el usuario no es participante.
   */
  async execute(conversationId: string, userId: string): Promise<void> {
    const conversation = await this.conversationRepo.findById(conversationId);
    if (!conversation) throw new NotFoundException('Conversation', conversationId);

    if (!conversation.participants.includes(userId)) {
      throw new ForbiddenException('No eres participante de esta conversación');
    }

    await this.messageRepo.markAsRead(conversationId, userId);

    // Emitir evento 'message:read' al otro participante para actualizar ticks azules
    const otherUserId = conversation.getOtherParticipantId(userId);
    if (otherUserId) {
      this.socketService.emitToUser(otherUserId, 'message:read', { conversationId });
      logger.debug(`message:read emitido a ${otherUserId} para conversación ${conversationId}`);
    }
  }
}
