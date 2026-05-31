/**
 * @file UserController.ts
 * @description Controlador HTTP de perfil y cuenta de usuario.
 * Gestiona el perfil propio, preferencias, cambio de contraseña y eliminación de cuenta.
 * Depende exclusivamente de interfaces de use cases, nunca de implementaciones concretas.
 * @module User
 * @layer Presentation
 *
 * @injectable
 * @dependencies IGetUserByIdUseCase, IUpdateUserProfileUseCase, IUpdateUserPreferencesUseCase,
 *              IChangePasswordUseCase, IDeleteUserAccountUseCase
 */

import { injectable, inject } from 'inversify';
import { Request, Response, NextFunction, Router } from 'express';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import type { IGetUserByIdUseCase } from '../../domain/interfaces/usecases/user/IGetUserByIdUseCase.js';
import type { IUpdateUserProfileUseCase } from '../../domain/interfaces/usecases/user/IUpdateUserProfileUseCase.js';
import type { IUpdateUserPreferencesUseCase } from '../../domain/interfaces/usecases/user/IUpdateUserPreferencesUseCase.js';
import type { IChangePasswordUseCase } from '../../domain/interfaces/usecases/user/IChangePasswordUseCase.js';
import type { IDeleteUserAccountUseCase } from '../../domain/interfaces/usecases/user/IDeleteUserAccountUseCase.js';
import type { IExportUserDataUseCase } from '../../domain/interfaces/usecases/user/IExportUserDataUseCase.js';
import { UpdateProfileRequestDto } from '../../domain/dtos/user/update-profile-request.dto.js';
import { UpdatePreferencesRequestDto } from '../../domain/dtos/user/update-preferences-request.dto.js';
import { ChangePasswordRequestDto } from '../../domain/dtos/user/change-password-request.dto.js';
import { ObjectId } from 'mongodb';
import { MongoDBConnection } from '../../data/datasources/mongodb/MongoDBConnection.js';
import { TYPES } from '../../core/types.js';
import { ValidationException, ValidationError } from '../../core/exceptions/ValidationException.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('UserController');

/** Tipo auxiliar para acceder a req.user sin augmentación global */
type AuthRequest = Request & { user: { userId: string; role: string } };

/**
 * Valida un DTO con class-validator y lanza ValidationException si hay errores.
 * @private
 */
async function validateDTO<T extends object>(DtoClass: new () => T, body: unknown): Promise<T> {
  const instance = plainToInstance(DtoClass, body);
  const errors = await validate(instance as object);
  if (errors.length > 0) {
    const validationErrors: ValidationError[] = errors.map(e => ({
      field:   e.property,
      message: Object.values(e.constraints ?? {}).join(', '),
    }));
    throw new ValidationException(validationErrors);
  }
  return instance;
}

/**
 * Controlador de rutas de usuario (perfil y cuenta).
 *
 * @injectable
 * @dependencies IGetUserByIdUseCase, IUpdateUserProfileUseCase, IUpdateUserPreferencesUseCase,
 *              IChangePasswordUseCase, IDeleteUserAccountUseCase, IExportUserDataUseCase
 */
@injectable()
export class UserController {
  constructor(
    @inject(TYPES.IGetUserProfileUseCase)          private readonly getUser:           IGetUserByIdUseCase,
    @inject(TYPES.IUpdateUserProfileUseCase)        private readonly updateProfile:     IUpdateUserProfileUseCase,
    @inject(TYPES.IUpdateUserPreferencesUseCase)    private readonly updatePreferences: IUpdateUserPreferencesUseCase,
    @inject(TYPES.IChangePasswordUseCase)           private readonly changePassword:    IChangePasswordUseCase,
    @inject(TYPES.IDeleteAccountUseCase)            private readonly deleteAccount:     IDeleteUserAccountUseCase,
    @inject(TYPES.IExportUserDataUseCase)           private readonly exportData:        IExportUserDataUseCase,
    @inject(TYPES.MongoDBConnection)                private readonly db:                MongoDBConnection,
  ) {}

  /**
   * Devuelve un Router de Express con todas las rutas de usuario.
   * Usar en bootstrap(): app.use('/users', requireAuth, userController.router()).
   */
  router(): Router {
    const router = Router();
    router.get( '/me',              this.handleGetMe.bind(this));
    // IMPORTANTE: /me/export y /search deben ir antes de /:id para que Express
    // no interprete 'export'/'search' como un :id param.
    router.get( '/me/export',      this.handleExportData.bind(this));
    router.get( '/search',         this.handleSearchUsers.bind(this));
    router.get( '/:id',            this.handleGetById.bind(this));
    router.put( '/me',              this.handleUpdateProfile.bind(this));
    router.put( '/me/preferences',  this.handleUpdatePreferences.bind(this));
    router.put( '/me/password',     this.handleChangePassword.bind(this));
    // Registro/actualización del fcmToken del dispositivo. El frontend lo
    // llama tras obtener el token de FCM.
    router.put(   '/me/fcm-token',  this.handleSetFcmToken.bind(this));
    // Desregistro explícito del fcmToken (logout).
    router.delete('/me/fcm-token',  this.handleDeleteFcmToken.bind(this));
    router.delete('/me',            this.handleDeleteAccount.bind(this));
    return router;
  }

  /**
   * PUT /users/me/fcm-token — Registra o actualiza el token FCM del
   * dispositivo del usuario autenticado.
   *
   * Si el mismo `fcmToken` ya estaba asociado a otros usuarios
   * (transferencia de dispositivo entre cuentas), primero los limpia
   * antes de asignar al actual. De este modo Firebase ya no envía al
   * usuario anterior cuando se reutiliza el mismo dispositivo.
   *
   * Body: `{ fcmToken: string }` (string vacío para borrar el token).
   * Respuesta: 204 No Content.
   */
  private async handleSetFcmToken(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = (req as AuthRequest).user.userId;
      const fcmToken = (req.body?.fcmToken as string | undefined)?.trim() ?? '';
      if (typeof fcmToken !== 'string') {
        res.status(400).json({ code: 'VALIDATION', message: 'fcmToken debe ser string' });
        return;
      }
      const users = this.db.getDatabase().collection('users');

      // Desasociación cross-cuenta: si el token ya existe en otros
      // usuarios, limpiarlo antes de asignarlo al actual. Solo tiene
      // sentido si el token no está vacío.
      if (fcmToken !== '') {
        await users.updateMany(
          { _id: { $ne: new ObjectId(userId) }, fcmToken },
          { $set: { fcmToken: '', updatedAt: new Date() } },
        );
      }

      await users.updateOne(
        { _id: new ObjectId(userId) },
        { $set: { fcmToken, updatedAt: new Date() } },
      );
      res.status(204).end();
    } catch (error) {
      next(error);
    }
  }

  /**
   * DELETE /users/me/fcm-token — Borra el fcmToken del usuario autenticado.
   * Idempotente: si ya estaba vacío, igualmente devuelve 204. Lo invoca el
   * frontend en el flujo de logout profundo para que las push pendientes no
   * lleguen al dispositivo asociado a una sesión cerrada.
   *
   * Respuesta: 204 No Content.
   */
  private async handleDeleteFcmToken(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = (req as AuthRequest).user.userId;
      await this.db.getDatabase().collection('users').updateOne(
        { _id: new ObjectId(userId) },
        { $set: { fcmToken: '', updatedAt: new Date() } },
      );
      res.status(204).end();
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /users/me — Devuelve el perfil del usuario autenticado.
   *
   * @param req — Request con req.user.userId del AuthMiddleware.
   * @param res — Response con UserResponseDTO.
   * @param next — Manejador de errores.
   */
  private async handleGetMe(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = (req as AuthRequest).user.userId;
      const user = await this.getUser.execute(userId);
      res.json(user);
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /users/:id — Devuelve el perfil público de cualquier usuario.
   * Usado desde la pantalla de comunidad para ver perfil ajeno.
   *
   * @param req — Request con req.params.id.
   * @param res — Response con UserResponseDTO.
   * @param next — Manejador de errores.
   */
  private async handleGetById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = await this.getUser.execute(req.params['id'] as string);
      res.json(user);
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /users/me — Actualiza nombre, bio y ubicación del usuario autenticado.
   *
   * @param req — Request con body UpdateProfileRequestDto.
   * @param res — Response con UserResponseDTO actualizado.
   * @param next — Manejador de errores.
   */
  private async handleUpdateProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = (req as AuthRequest).user.userId;
      const dto = await validateDTO(UpdateProfileRequestDto, req.body);
      const user = await this.updateProfile.execute(userId, dto);
      res.json(user);
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /users/me/preferences — Actualiza las preferencias del usuario autenticado.
   *
   * @param req — Request con body UpdatePreferencesRequestDto.
   * @param res — Response con UserResponseDTO actualizado.
   * @param next — Manejador de errores.
   */
  private async handleUpdatePreferences(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = (req as AuthRequest).user.userId;
      const dto = await validateDTO(UpdatePreferencesRequestDto, req.body);
      const user = await this.updatePreferences.execute(userId, dto);
      res.json(user);
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /users/me/password — Cambia la contraseña del usuario autenticado.
   *
   * @param req — Request con body ChangePasswordRequestDto.
   * @param res — 204 No Content.
   * @param next — Manejador de errores.
   */
  private async handleChangePassword(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = (req as AuthRequest).user.userId;
      const dto = await validateDTO(ChangePasswordRequestDto, req.body);
      await this.changePassword.execute(userId, dto.currentPassword, dto.newPassword);
      res.status(204).send();
      logger.info(`Contraseña cambiada para usuario ${userId}`);
    } catch (error) {
      next(error);
    }
  }

  /**
   * DELETE /users/me — Elimina la cuenta del usuario autenticado (soft-delete).
   * Requiere la contraseña actual en el body como confirmación.
   *
   * @param req — Request con body { password: string }.
   * @param res — 204 No Content.
   * @param next — Manejador de errores.
   */
  private async handleDeleteAccount(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = (req as AuthRequest).user.userId;
      const body = req.body as { password?: string; preserveContent?: boolean };
      const password         = body.password ?? '';
      const preserveContent  = body.preserveContent === true;
      await this.deleteAccount.execute(userId, password, preserveContent);
      res.status(204).send();
      logger.info(`Cuenta eliminada (soft): ${userId} — preserveContent: ${preserveContent}`);
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /users/me/export — Exporta todos los datos personales del usuario (RGPD).
   *
   * @param req — Request con req.user.userId del AuthMiddleware.
   * @param res — Response 200 con JSON exportado.
   * @param next — Manejador de errores.
   */
  private async handleExportData(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = (req as AuthRequest).user.userId;
      const data = await this.exportData.execute(userId);
      res.json(data);
      logger.info(`Datos exportados para usuario ${userId}`);
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /users/search?q=... — Buscador público de usuarios por nombre.
   * Cualquier usuario autenticado puede buscar; admin ve todos, usuario
   * normal solo ve usuarios con isPrivate=false. Devuelve máx. 20
   * resultados con { id, name, photo }. TFG: acceso directo a MongoDB
   * (mismo patrón que AdminController.handleSearchUsers).
   *
   * @param req — Query: q (string de búsqueda).
   * @param res — Array de usuarios coincidentes.
   * @param next — Manejador de errores.
   */
  private async handleSearchUsers(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const role      = (req as AuthRequest).user.role;
      const requester = (req as AuthRequest).user.userId;
      const q         = ((req.query['q'] as string) ?? '').trim();
      if (!q) {
        res.json([]);
        return;
      }

      // Escapar caracteres especiales de regex para evitar inyección.
      const escaped = q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const regex   = { $regex: escaped, $options: 'i' };

      const filter: Record<string, unknown> = {
        deletedAt: null,
        name:      regex,
      };
      // Usuario normal: excluir privados (pero permitirse a sí mismo).
      if (role !== 'admin') {
        filter['$or'] = [
          { 'preferences.isPrivate': { $ne: true } },
          { 'preferences.isPrivate': { $exists: false } },
        ];
      }

      const users = await this.db
        .getDatabase()
        .collection('users')
        .find(filter)
        .project({ _id: 1, name: 1, photo: 1 })
        .limit(20)
        .toArray();

      res.json(
        users
          .filter((u) => u['_id'].toHexString() !== requester)
          .map((u) => ({
            id:    u['_id'].toHexString(),
            name:  u['name'],
            photo: u['photo'] ?? null,
          })),
      );
    } catch (error) {
      next(error);
    }
  }
}
