/**
 * @file PostController.ts
 * @description Controlador HTTP de la comunidad (posts y comentarios).
 * Depende exclusivamente de interfaces de use cases, nunca de implementaciones concretas.
 * @module Community
 * @layer Presentation
 *
 * @injectable
 * @dependencies IGetFeedUseCase, IGetPostByIdUseCase, ICreatePostUseCase,
 *               ILikePostUseCase, IUnlikePostUseCase,
 *               IGetPostCommentsUseCase, ICreateCommentUseCase, SocketService
 */

import { injectable, inject } from 'inversify';
import { Request, Response, NextFunction, Router } from 'express';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import type { IGetFeedUseCase } from '../../domain/interfaces/usecases/community/IGetFeedUseCase.js';
import type { IGetPostByIdUseCase } from '../../domain/interfaces/usecases/community/IGetPostByIdUseCase.js';
import type { ICreatePostUseCase } from '../../domain/interfaces/usecases/community/ICreatePostUseCase.js';
import type { ILikePostUseCase } from '../../domain/interfaces/usecases/community/ILikePostUseCase.js';
import type { IUnlikePostUseCase } from '../../domain/interfaces/usecases/community/IUnlikePostUseCase.js';
import type { IGetPostCommentsUseCase } from '../../domain/interfaces/usecases/community/IGetPostCommentsUseCase.js';
import type { ICreateCommentUseCase } from '../../domain/interfaces/usecases/community/ICreateCommentUseCase.js';
import type { IDeletePostUseCase } from '../../domain/interfaces/usecases/community/IDeletePostUseCase.js';
import type { IDeleteCommentUseCase } from '../../domain/interfaces/usecases/community/IDeleteCommentUseCase.js';
import { CreatePostRequestDto } from '../../domain/dtos/community/create-post-request.dto.js';
import { CreateCommentRequestDto } from '../../domain/dtos/community/create-comment-request.dto.js';
import { TYPES } from '../../core/types.js';
import { ValidationException, ValidationError } from '../../core/exceptions/ValidationException.js';
import { createLogger } from '../../core/logger.js';
import { SocketService } from '../services/SocketService.js';

const logger = createLogger('PostController');

/** Tipo auxiliar para requests autenticados */
type AuthRequest = Request & { user: { userId: string } };

/**
 * Valida un DTO con class-validator y lanza ValidationException si hay errores.
 * @private
 */
async function validateDTO<T extends object>(DtoClass: new () => T, body: unknown): Promise<T> {
  const instance = plainToInstance(DtoClass, body);
  const errors = await validate(instance as object);
  if (errors.length > 0) {
    const validationErrors: ValidationError[] = errors.map(e => ({
      field: e.property,
      message: Object.values(e.constraints ?? {}).join(', '),
    }));
    throw new ValidationException(validationErrors);
  }
  return instance;
}

/**
 * Controlador de rutas de la comunidad (posts y comentarios).
 *
 * @injectable
 * @dependencies IGetFeedUseCase, IGetPostByIdUseCase, ICreatePostUseCase,
 *               ILikePostUseCase, IUnlikePostUseCase,
 *               IGetPostCommentsUseCase, ICreateCommentUseCase,
 *               IDeletePostUseCase, IDeleteCommentUseCase, SocketService
 */
@injectable()
export class PostController {
  constructor(
    @inject(TYPES.IGetFeedUseCase)         private readonly getFeed: IGetFeedUseCase,
    @inject(TYPES.IGetPostByIdUseCase)     private readonly getPostById: IGetPostByIdUseCase,
    @inject(TYPES.ICreatePostUseCase)      private readonly createPost: ICreatePostUseCase,
    @inject(TYPES.ILikePostUseCase)        private readonly likePost: ILikePostUseCase,
    @inject(TYPES.IUnlikePostUseCase)      private readonly unlikePost: IUnlikePostUseCase,
    @inject(TYPES.IGetPostCommentsUseCase) private readonly getComments: IGetPostCommentsUseCase,
    @inject(TYPES.IAddCommentUseCase)      private readonly addComment: ICreateCommentUseCase,
    @inject(TYPES.IDeletePostUseCase)      private readonly deletePost: IDeletePostUseCase,
    @inject(TYPES.IDeleteCommentUseCase)   private readonly deleteComment: IDeleteCommentUseCase,
    @inject(TYPES.SocketService)           private readonly socketService: SocketService,
  ) {}

  /**
   * Devuelve un Router de Express con todas las rutas de la comunidad.
   * Usar en bootstrap(): app.use('/community', requireAuth, postController.router()).
   */
  router(): Router {
    const router = Router();

    // Feed y posts — /mine debe registrarse ANTES de /:id para no ser capturado como param.
    router.get('/',               this.handleGetFeed.bind(this));
    router.get('/mine',           this.handleGetMyPosts.bind(this));
    router.get('/:id',            this.handleGetPostById.bind(this));
    router.post('/',              this.handleCreatePost.bind(this));
    router.post('/:id/like',      this.handleLikePost.bind(this));
    router.delete('/:id/like',    this.handleUnlikePost.bind(this));
    router.delete('/:id',         this.handleDeletePost.bind(this));

    // Comentarios de un post
    router.get('/:id/comments',   this.handleGetComments.bind(this));
    router.post('/:id/comments',  this.handleAddComment.bind(this));
    router.delete('/:id/comments/:commentId', this.handleDeleteComment.bind(this));

    return router;
  }

  /**
   * GET /community?page=1&limit=20 — Devuelve el feed paginado.
   *
   * @param req — Request con req.user.userId y query params opcionales.
   * @param res — Response con array de PostResponseDTO.
   * @param next — Manejador de errores.
   */
  private async handleGetFeed(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId   = (req as AuthRequest).user.userId;
      const page     = parseInt((req.query['page']  as string) ?? '1',  10) || 1;
      const limit    = parseInt((req.query['limit'] as string) ?? '20', 10) || 20;
      // `authorId` opcional: si está presente, filtra el feed a posts de
      // ese autor concreto (utilizado por UserProfilePage para ver el
      // perfil de otro usuario). Antes el frontend lo enviaba pero el
      // backend lo ignoraba aquí, lo que producía un perfil vacío.
      const authorId = (req.query['authorId'] as string | undefined) || undefined;

      const feed = await this.getFeed.execute(userId, page, limit, authorId);
      res.json(feed);
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /community/mine — Posts del usuario autenticado (para su perfil propio).
   *
   * @param req — Request con req.user.userId y query params opcionales.
   * @param res — Response con array de PostResponseDTO del propio usuario.
   * @param next — Manejador de errores.
   */
  private async handleGetMyPosts(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = (req as AuthRequest).user.userId;
      const page   = parseInt((req.query['page']  as string) ?? '1',  10) || 1;
      const limit  = parseInt((req.query['limit'] as string) ?? '50', 10) || 50;

      const posts = await this.getFeed.execute(userId, page, limit, userId);
      res.json(posts);
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /community/:id — Detalle de un post.
   *
   * @param req — Request con req.params['id'] as string y req.user.userId.
   * @param res — Response con PostResponseDTO (isLikedByMe correcto para el solicitante).
   * @param next — Manejador de errores.
   */
  private async handleGetPostById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = (req as AuthRequest).user.userId;
      const post   = await this.getPostById.execute(req.params['id'] as string, userId);
      res.json(post);
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /community — Crea un nuevo post.
   *
   * @param req — Request con body JSON (CreatePostRequestDto).
   * @param res — Response 201 con PostResponseDTO.
   * @param next — Manejador de errores.
   */
  private async handleCreatePost(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = (req as AuthRequest).user.userId;
      const dto    = await validateDTO(CreatePostRequestDto, req.body);
      const post   = await this.createPost.execute(userId, dto);
      res.status(201).json(post);
      // Notificar a todos los clientes que el feed ha cambiado (nuevo post).
      this.socketService.broadcast('feed:updated', { action: 'created', postId: post.id });
      logger.info(`Post creado por usuario ${userId}: ${post.id}`);
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /community/:id/like — Da like a un post (idempotente).
   *
   * @param req — Request con req.params['id'] as string y req.user.userId.
   * @param res — Response 204 No Content.
   * @param next — Manejador de errores.
   */
  private async handleLikePost(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = (req as AuthRequest).user.userId;
      const postId = req.params['id'] as string;
      await this.likePost.execute(postId, userId);
      res.status(204).send();
      // Notificar a todos los clientes conectados el nuevo recuento de likes.
      void this._broadcastPostUpdated(postId, userId);
    } catch (error) {
      next(error);
    }
  }

  /**
   * DELETE /community/:id/like — Quita el like de un post (idempotente).
   *
   * @param req — Request con req.params['id'] as string y req.user.userId.
   * @param res — Response 204 No Content.
   * @param next — Manejador de errores.
   */
  private async handleUnlikePost(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = (req as AuthRequest).user.userId;
      const postId = req.params['id'] as string;
      await this.unlikePost.execute(postId, userId);
      res.status(204).send();
      // Notificar a todos los clientes conectados el nuevo recuento de likes.
      void this._broadcastPostUpdated(postId, userId);
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /community/:id/comments — Obtiene los comentarios activos de un post.
   *
   * @param req — Request con req.params['id'] as string.
   * @param res — Response con array de CommentResponseDTO.
   * @param next — Manejador de errores.
   */
  private async handleGetComments(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const comments = await this.getComments.execute(req.params['id'] as string);
      res.json(comments);
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /community/:id/comments — Añade un comentario a un post.
   *
   * @param req — Request con req.params['id'] as string, body JSON (CreateCommentRequestDto) y req.user.userId.
   * @param res — Response 201 con CommentResponseDTO.
   * @param next — Manejador de errores.
   */
  private async handleAddComment(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId  = (req as AuthRequest).user.userId;
      const postId  = req.params['id'] as string;
      const dto     = await validateDTO(CreateCommentRequestDto, req.body);
      const comment = await this.addComment.execute(postId, userId, dto.content);
      res.status(201).json(comment);
      logger.info(`Comentario añadido por usuario ${userId} en post ${postId}`);
      // Notificar a todos los clientes conectados el nuevo recuento de comentarios.
      void this._broadcastPostUpdated(postId, userId);
    } catch (error) {
      next(error);
    }
  }

  /**
   * DELETE /community/:id — Elimina un post propio (soft-delete).
   * Valida que el usuario autenticado sea el autor del post.
   *
   * @param req — Request con req.params['id'] y req.user.userId.
   * @param res — Response 204 No Content.
   * @param next — Manejador de errores.
   */
  private async handleDeletePost(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = (req as AuthRequest).user.userId;
      const postId = req.params['id'] as string;
      await this.deletePost.execute(postId, userId);
      res.status(204).send();
      // Notificar a todos los clientes que el feed ha cambiado (post eliminado).
      this.socketService.broadcast('feed:updated', { action: 'deleted', postId });
      logger.info(`Usuario ${userId} eliminó su post ${postId}`);
    } catch (error) {
      next(error);
    }
  }

  /**
   * DELETE /community/:id/comments/:commentId — Elimina un comentario propio (soft-delete).
   * Valida que el usuario autenticado sea el autor del comentario.
   * Decrementa el contador commentsCount del post padre.
   *
   * @param req — Request con req.params['id'], req.params['commentId'] y req.user.userId.
   * @param res — Response 204 No Content.
   * @param next — Manejador de errores.
   */
  private async handleDeleteComment(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId    = (req as AuthRequest).user.userId;
      const commentId = req.params['commentId'] as string;
      const postId    = req.params['id'] as string;
      await this.deleteComment.execute(commentId, userId);
      res.status(204).send();
      // Notificar a todos los clientes el nuevo recuento de comentarios.
      void this._broadcastPostUpdated(postId, userId);
      logger.info(`Usuario ${userId} eliminó su comentario ${commentId}`);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Obtiene los contadores actualizados del post y emite 'post:updated' a todos los clientes.
   * Se llama de forma fire-and-forget tras like/unlike/comment para no bloquear la respuesta HTTP.
   *
   * @param postId — Id del post cuya cuenta de likes/comments ha cambiado.
   * @param userId — Id del usuario que realizó la acción (necesario para isLikedByMe).
   * @private
   */
  private async _broadcastPostUpdated(postId: string, userId: string): Promise<void> {
    try {
      const post = await this.getPostById.execute(postId, userId);
      this.socketService.broadcast('post:updated', {
        postId:        post.id,
        likesCount:    post.likesCount,
        commentsCount: post.commentsCount,
      });
    } catch {
      // No propagar errores de broadcast — la respuesta HTTP ya fue enviada.
      logger.warn(`_broadcastPostUpdated fallido para postId=${postId}`);
    }
  }
}
