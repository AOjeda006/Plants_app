/**
 * @file GetConversationMessagesUseCase.ts
 * @description Caso de uso para obtener los mensajes paginados de una conversación.
 * Verifica que el usuario sea participante antes de devolver los mensajes.
 * @module Chat
 * @layer Domain
 *
 * @implements {IGetMessagesUseCase}
 * @injectable
 * @dependencies IConversationRepository, IMessageRepository, IUserRepository, IMessageMapper
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { IGetMessagesUseCase } from '../../interfaces/usecases/chat/IGetMessagesUseCase.js';
import type { IConversationRepository } from '../../repositories/IConversationRepository.js';
import type { IMessageRepository } from '../../repositories/IMessageRepository.js';
import type { IUserRepository } from '../../repositories/IUserRepository.js';
import type { IMessageMapper } from '../../../data/IMappers/IMessageMapper.js';
import type { MessageResponseDTO } from '../../dtos/chat/message-response.dto.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';
import { ForbiddenException } from '../../../core/exceptions/ForbiddenException.js';

/**
 * Obtiene los mensajes paginados de una conversación, verificando participación.
 *
 * @implements {IGetMessagesUseCase}
 * @injectable
 * @dependencies IConversationRepository, IMessageRepository, IUserRepository, IMessageMapper
 */
@injectable()
export class GetConversationMessagesUseCase implements IGetMessagesUseCase {
  constructor(
    @inject(TYPES.IConversationRepository) private readonly conversationRepo: IConversationRepository,
    @inject(TYPES.IMessageRepository)      private readonly messageRepo: IMessageRepository,
    @inject(TYPES.IUserRepository)         private readonly userRepo: IUserRepository,
    @inject(TYPES.IMessageMapper)          private readonly mapper: IMessageMapper,
  ) {}

  /**
   * @param conversationId — ID de la conversación.
   * @param userId — ID del usuario solicitante.
   * @param page — Número de página (base 1). Por defecto 1.
   * @param limit — Elementos por página. Por defecto 30.
   * @returns Lista paginada de MessageResponseDTOs.
   * @throws {NotFoundException} Si la conversación no existe.
   * @throws {ForbiddenException} Si el usuario no es participante.
   */
  async execute(conversationId: string, userId: string, page = 1, limit = 30): Promise<MessageResponseDTO[]> {
    const conversation = await this.conversationRepo.findById(conversationId);
    if (!conversation) throw new NotFoundException('Conversation', conversationId);

    if (!conversation.participants.includes(userId)) {
      throw new ForbiddenException('No eres participante de esta conversación');
    }

    const messages = await this.messageRepo.findByConversationId(conversationId, page, limit);

    // TFG: N+1 para enriquecimiento del nombre del emisor.
    const result: MessageResponseDTO[] = [];
    for (const msg of messages) {
      const sender = await this.userRepo.findById(msg.senderId);
      result.push(this.mapper.toResponseDTO(msg, sender?.name ?? 'Usuario eliminado'));
    }

    return result;
  }
}
