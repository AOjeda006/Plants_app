/**
 * @file GetUserConversationsUseCase.ts
 * @description Caso de uso para obtener todas las conversaciones activas del usuario.
 * Enriquece cada conversación con datos del otro participante, último mensaje
 * y contador de mensajes no leídos (N+1 — aceptable para TFG).
 * @module Chat
 * @layer Domain
 *
 * @implements {IGetConversationsUseCase}
 * @injectable
 * @dependencies IConversationRepository, IMessageRepository, IUserRepository, IConversationMapper, IMessageMapper
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { IGetConversationsUseCase } from '../../interfaces/usecases/chat/IGetConversationsUseCase.js';
import type { IConversationRepository } from '../../repositories/IConversationRepository.js';
import type { IMessageRepository } from '../../repositories/IMessageRepository.js';
import type { IUserRepository } from '../../repositories/IUserRepository.js';
import type { IConversationMapper } from '../../../data/IMappers/IConversationMapper.js';
import type { IMessageMapper } from '../../../data/IMappers/IMessageMapper.js';
import type { ConversationResponseDTO } from '../../dtos/chat/conversation-response.dto.js';

/**
 * Obtiene las conversaciones del usuario con datos enriquecidos.
 *
 * @implements {IGetConversationsUseCase}
 * @injectable
 * @dependencies IConversationRepository, IMessageRepository, IUserRepository, IConversationMapper, IMessageMapper
 */
@injectable()
export class GetUserConversationsUseCase implements IGetConversationsUseCase {
  constructor(
    @inject(TYPES.IConversationRepository) private readonly conversationRepo: IConversationRepository,
    @inject(TYPES.IMessageRepository)      private readonly messageRepo: IMessageRepository,
    @inject(TYPES.IUserRepository)         private readonly userRepo: IUserRepository,
    @inject(TYPES.IConversationMapper)     private readonly conversationMapper: IConversationMapper,
    @inject(TYPES.IMessageMapper)          private readonly messageMapper: IMessageMapper,
  ) {}

  /**
   * @param userId — ID del usuario autenticado.
   * @returns Lista de ConversationResponseDTOs ordenada por actividad reciente.
   */
  async execute(userId: string): Promise<ConversationResponseDTO[]> {
    const conversations = await this.conversationRepo.findByUserId(userId);

    // TFG: N+1 aceptable para conversaciones. En producción usar $lookup con agregación.
    const result: ConversationResponseDTO[] = [];
    for (const conv of conversations) {
      const otherId = conv.getOtherParticipantId(userId);
      if (!otherId) continue;

      const [otherUser, lastMessage, unreadCount] = await Promise.all([
        this.userRepo.findById(otherId),
        this.messageRepo.findLastByConversationId(conv.id),
        this.messageRepo.countUnread(conv.id, userId),
      ]);

      const lastMsgDTO = lastMessage
        ? this.messageMapper.toResponseDTO(lastMessage, otherUser?.name ?? 'Usuario eliminado')
        : undefined;

      // Si el participante fue eliminado, marcamos la conversación como solo lectura.
      result.push({
        ...this.conversationMapper.toResponseDTO(
          conv,
          { id: otherId, name: otherUser?.name ?? 'Usuario eliminado', photo: otherUser?.photo },
          lastMsgDTO,
          unreadCount,
        ),
        isParticipantDeleted: otherUser === null,
      });
    }

    return result;
  }
}
