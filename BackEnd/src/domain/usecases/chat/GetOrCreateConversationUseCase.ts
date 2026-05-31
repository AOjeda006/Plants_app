/**
 * @file GetOrCreateConversationUseCase.ts
 * @description Caso de uso para obtener o crear una conversación 1-a-1 entre dos usuarios.
 * Si ya existe una conversación entre ellos, la devuelve; si no, la crea.
 * @module Chat
 * @layer Domain
 *
 * @implements {ICreateConversationUseCase}
 * @injectable
 * @dependencies IConversationRepository, IUserRepository, IConversationMapper
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { ICreateConversationUseCase } from '../../interfaces/usecases/chat/ICreateConversationUseCase.js';
import type { IConversationRepository } from '../../repositories/IConversationRepository.js';
import type { IUserRepository } from '../../repositories/IUserRepository.js';
import type { IConversationMapper } from '../../../data/IMappers/IConversationMapper.js';
import type { ConversationResponseDTO } from '../../dtos/chat/conversation-response.dto.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';
import { ForbiddenException } from '../../../core/exceptions/ForbiddenException.js';

/**
 * Obtiene o crea una conversación entre el usuario autenticado y otro usuario.
 * Garantiza unicidad del par: no crea duplicados.
 *
 * @implements {ICreateConversationUseCase}
 * @injectable
 * @dependencies IConversationRepository, IUserRepository, IConversationMapper
 */
@injectable()
export class GetOrCreateConversationUseCase implements ICreateConversationUseCase {
  constructor(
    @inject(TYPES.IConversationRepository) private readonly conversationRepo: IConversationRepository,
    @inject(TYPES.IUserRepository)         private readonly userRepo: IUserRepository,
    @inject(TYPES.IConversationMapper)     private readonly mapper: IConversationMapper,
  ) {}

  /**
   * @param participantId — ID del otro usuario con quien iniciar la conversación.
   * @param userId — ID del usuario autenticado.
   * @returns ConversationResponseDTO (existente o nueva).
   * @throws {NotFoundException} Si el otro participante no existe.
   */
  async execute(participantId: string, userId: string): Promise<ConversationResponseDTO> {
    const participant = await this.userRepo.findById(participantId);
    if (!participant) throw new NotFoundException('User', participantId);

    // Buscar conversación existente entre los dos usuarios
    let conversation = await this.conversationRepo.findByParticipants(userId, participantId);

    if (!conversation) {
      // Si el destinatario tiene perfil privado no se puede iniciar nueva conversación.
      // Los admins están exentos: necesitan poder contactar a cualquier usuario para moderar.
      const requestingUser = await this.userRepo.findById(userId);
      const isAdmin = requestingUser?.role === 'admin';
      if (participant.preferences?.isPrivate && !isAdmin) {
        throw new ForbiddenException('No puedes iniciar una conversación con un perfil privado.');
      }
      conversation = await this.conversationRepo.create(userId, participantId);
    }

    return this.mapper.toResponseDTO(
      conversation,
      { id: participant.id, name: participant.name, photo: participant.photo },
      undefined,
      0,
    );
  }
}
