/**
 * @file ChatController.ts
 * @description Controlador HTTP del módulo de chat (conversaciones y mensajes).
 * Depende exclusivamente de interfaces de use cases, nunca de implementaciones concretas.
 * @module Chat
 * @layer Presentation
 *
 * @injectable
 * @dependencies IGetConversationsUseCase, IGetMessagesUseCase, ISendMessageUseCase,
 *               IGetOrCreateConversationUseCase, IMarkMessagesAsReadUseCase
 */

import { injectable, inject } from 'inversify';
import { Request, Response, NextFunction, Router } from 'express';
import { TYPES } from '../../core/types.js';
import type { IGetConversationsUseCase } from '../../domain/interfaces/usecases/chat/IGetConversationsUseCase.js';
import type { IGetMessagesUseCase } from '../../domain/interfaces/usecases/chat/IGetMessagesUseCase.js';
import type { ISendMessageUseCase } from '../../domain/interfaces/usecases/chat/ISendMessageUseCase.js';
import type { ICreateConversationUseCase } from '../../domain/interfaces/usecases/chat/ICreateConversationUseCase.js';
import type { IMarkMessagesAsReadUseCase } from '../../domain/interfaces/usecases/chat/IMarkMessagesAsReadUseCase.js';
import type { SendMessageRequestDto } from '../../domain/dtos/chat/send-message-request.dto.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('ChatController');

/** Tipo auxiliar para requests autenticados */
type AuthRequest = Request & { user: { userId: string } };

/**
 * Controlador de rutas del chat (conversaciones y mensajes).
 *
 * @injectable
 * @dependencies IGetConversationsUseCase, IGetMessagesUseCase, ISendMessageUseCase,
 *               IGetOrCreateConversationUseCase, IMarkMessagesAsReadUseCase
 */
@injectable()
export class ChatController {
  constructor(
    @inject(TYPES.IGetConversationsUseCase)      private readonly getConversations: IGetConversationsUseCase,
    @inject(TYPES.IGetMessagesUseCase)           private readonly getMessages: IGetMessagesUseCase,
    @inject(TYPES.ISendMessageUseCase)           private readonly sendMessage: ISendMessageUseCase,
    @inject(TYPES.IGetOrCreateConversationUseCase) private readonly getOrCreateConversation: ICreateConversationUseCase,
    @inject(TYPES.IMarkMessagesReadUseCase)      private readonly markRead: IMarkMessagesAsReadUseCase,
  ) {}

  /**
   * Devuelve un Router de Express con todas las rutas del chat.
   * Usar en bootstrap(): app.use('/chat', requireAuth, chatController.router()).
   */
  router(): Router {
    const router = Router();

    router.get('/',                          this.handleGetConversations.bind(this));
    router.post('/',                         this.handleGetOrCreateConversation.bind(this));
    router.get('/:id/messages',              this.handleGetMessages.bind(this));
    router.post('/:id/messages',             this.handleSendMessage.bind(this));
    router.post('/:id/read',                 this.handleMarkAsRead.bind(this));

    return router;
  }

  /**
   * GET /chat — Devuelve todas las conversaciones activas del usuario autenticado.
   *
   * @param req — Request con req.user.userId.
   * @param res — Response con array de ConversationResponseDTO.
   * @param next — Manejador de errores.
   */
  private async handleGetConversations(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = (req as AuthRequest).user.userId;
      const conversations = await this.getConversations.execute(userId);
      res.json(conversations);
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /chat — Obtiene o crea una conversación 1:1 con otro usuario.
   * Body: { participantId: string }
   *
   * @param req — Request con body.participantId y req.user.userId.
   * @param res — Response 200/201 con ConversationResponseDTO.
   * @param next — Manejador de errores.
   */
  private async handleGetOrCreateConversation(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId      = (req as AuthRequest).user.userId;
      const participantId = (req.body as { participantId: string }).participantId;

      const conversation = await this.getOrCreateConversation.execute(participantId, userId);
      res.status(200).json(conversation);
      logger.info(`Conversación obtenida/creada: userId=${userId} participantId=${participantId} convId=${conversation.id}`);
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /chat/:id/messages?page=1&limit=30 — Devuelve los mensajes paginados de una conversación.
   *
   * @param req — Request con req.params['id'] as string, req.user.userId y query params opcionales.
   * @param res — Response con array de MessageResponseDTO.
   * @param next — Manejador de errores.
   */
  private async handleGetMessages(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId         = (req as AuthRequest).user.userId;
      const conversationId = req.params['id'] as string;
      const page           = parseInt((req.query['page']  as string) ?? '1',  10) || 1;
      const limit          = parseInt((req.query['limit'] as string) ?? '30', 10) || 30;

      const messages = await this.getMessages.execute(conversationId, userId, page, limit);
      res.json(messages);
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /chat/:id/messages — Envía un mensaje en una conversación.
   * Body: SendMessageRequestDto { text?, contentMeta?, tempId? }
   *
   * @param req — Request con req.params['id'] as string, body JSON y req.user.userId.
   * @param res — Response 201 con MessageResponseDTO.
   * @param next — Manejador de errores.
   */
  private async handleSendMessage(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId         = (req as AuthRequest).user.userId;
      const conversationId = req.params['id'] as string;
      const dto            = req.body as SendMessageRequestDto;

      const message = await this.sendMessage.execute(conversationId, userId, dto);
      res.status(201).json(message);
      logger.info(`Mensaje enviado: conversationId=${conversationId} senderId=${userId}`);
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /chat/:id/read — Marca todos los mensajes no leídos de la conversación como leídos.
   *
   * @param req — Request con req.params['id'] as string y req.user.userId.
   * @param res — Response 204 No Content.
   * @param next — Manejador de errores.
   */
  private async handleMarkAsRead(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId         = (req as AuthRequest).user.userId;
      const conversationId = req.params['id'] as string;

      await this.markRead.execute(conversationId, userId);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  }
}
