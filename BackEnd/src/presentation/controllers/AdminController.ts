/**
 * @file AdminController.ts
 * @description Controlador HTTP del panel de administración.
 * Expone estadísticas, elementos eliminados, restauración, diagnósticos
 * y el endpoint de forzado del cron de recordatorios.
 * Todos los endpoints requieren rol 'admin' (verificado via policyMatrix).
 * TFG: en NODE_ENV=development, POST /trigger-reminders permite cualquier usuario autenticado.
 * @module User
 * @layer Presentation
 *
 * @injectable
 * @dependencies MongoDBConnection, IProcessPendingRemindersUseCase
 */

import { injectable, inject } from 'inversify';
import { Request, Response, NextFunction, Router } from 'express';
import { ObjectId } from 'mongodb';
import { MongoDBConnection } from '../../data/datasources/mongodb/MongoDBConnection.js';
import { TYPES } from '../../core/types.js';
import { hasPermission } from '../../core/policies/policyMatrix.js';
import { ForbiddenException } from '../../core/exceptions/ForbiddenException.js';
import { HttpException } from '../../core/exceptions/HttpException.js';
import { NotFoundException } from '../../core/exceptions/NotFoundException.js';
import { createLogger } from '../../core/logger.js';
import { opsConfig } from '../../core/config/ops.config.js';
import type { IProcessPendingRemindersUseCase } from '../../domain/interfaces/usecases/reminders/IProcessPendingRemindersUseCase.js';
import { SocketService } from '../services/SocketService.js';
import { NotificationService } from '../services/NotificationService.js';
import { NotificationMessages } from '../../core/notifications/notification-messages.es.js';

const logger = createLogger('AdminController');

/** Tipos de recurso restaurables */
type RestorableType = 'users' | 'plants' | 'posts' | 'comments';

/** Mapa de tipo → nombre de colección MongoDB */
const COLLECTION_MAP: Record<RestorableType, string> = {
  users:    'users',
  plants:   'plants',
  posts:    'posts',
  comments: 'comments',
};

/** Tipo auxiliar para acceder a req.user sin augmentación global */
type AuthRequest = Request & { user: { userId: string; role: string } };

/**
 * Controlador del panel de administración.
 * TFG: usa MongoDBConnection directamente para evitar crear use cases de admin sin valor pedagógico.
 * Delega en IProcessPendingRemindersUseCase para el endpoint de forzado del cron.
 *
 * @injectable
 * @dependencies MongoDBConnection, IProcessPendingRemindersUseCase
 */
@injectable()
export class AdminController {
  constructor(
    @inject(TYPES.MongoDBConnection)              private readonly db:              MongoDBConnection,
    @inject(TYPES.IProcessPendingRemindersUseCase) private readonly processReminders: IProcessPendingRemindersUseCase,
    @inject(TYPES.SocketService)                   private readonly socketService:    SocketService,
    @inject(TYPES.NotificationService)             private readonly notificationService: NotificationService,
  ) {}

  /**
   * Helper privado: envía push FCM agrupado al usuario.
   *
   * Una sola push por usuario por evento, en lugar de N pushes
   * individuales si tiene varias plantas. Previene spam — Android agrupa
   * también automáticamente notifs del mismo `tag`, pero enviar múltiples
   * FCM consume cuota y satura la barra del sistema. El payload `data`
   * incluye `count` y `type: 'aviso'` para que el frontend navegue a la
   * pestaña Avisos al tocar.
   *
   * @param userId   — ID del usuario destinatario.
   * @param title    — Título del push (mismo para toda la batch).
   * @param body     — Cuerpo del push (resumen "Tienes N alertas de X").
   * @param tag      — Identificador opcional para que Android reemplace
   *                   notifs anteriores del mismo tag (collapse key).
   */
  private async _pushSummaryToUser(
    userId:       string,
    title:        string,
    body:         string,
    tag?:         string,
    firstPlantId?: string,
  ): Promise<void> {
    try {
      const userDoc = await this.db.getDatabase()
        .collection('users')
        .findOne(
          { _id: new ObjectId(userId) },
          { projection: { fcmToken: 1 } },
        );
      const fcmToken = (userDoc?.['fcmToken'] as string | undefined) ?? '';
      if (!fcmToken) return;
      // Deep link: si solo hay UNA planta afectada en la batch, pasamos
      // plantId para que al tocar abra el detalle. Si hay varias,
      // omitimos id (el frontend no navega a planta, abre la app en home).
      const data: Record<string, string> = firstPlantId
        ? { type: 'plant', id: firstPlantId }
        : { type: 'aviso' };
      if (tag) data['tag'] = tag;
      await this.notificationService.sendToUser(fcmToken, {
        title,
        body,
        data,
        userId,
      });
    } catch (err) {
      logger.warn(`Push agrupado omitido por error: ${(err as Error).message}`);
    }
  }

  /**
   * Devuelve un Router de Express con todas las rutas de admin.
   * Usar en bootstrap(): app.use('/admin', requireAuth, adminController.router()).
   */
  router(): Router {
    const router = Router();
    router.get('/users/search',              this.handleSearchUsers.bind(this));
    router.get('/reports',                   this.handleReports.bind(this));
    // incident-reports antes de /deleted-items para evitar colisiones de ruta.
    router.get('/incident-reports',          this.handleIncidentReports.bind(this));
    router.put('/incident-reports/:id',      this.handleResolveReport.bind(this));
    router.get('/deleted-items',             this.handleDeletedItems.bind(this));
    router.post('/restore/:type/:id',        this.handleRestore.bind(this));
    // Eliminar post/comment por admin (soft-delete + notificación al propietario).
    router.delete('/posts/:id',              this.handleDeletePost.bind(this));
    router.delete('/comments/:id',           this.handleDeleteComment.bind(this));
    router.put('/users/:id/ban',             this.handleBanUser.bind(this));
    router.put('/users/:id/warn',            this.handleWarnUser.bind(this));
    router.get('/diagnostics',               this.handleDiagnostics.bind(this));
    router.post('/trigger-reminders',        this.handleTriggerReminders.bind(this));
    router.post('/run-cron',                 this.handleRunCron.bind(this));
    router.post('/simulate-rain',            this.handleSimulateRain.bind(this));
    router.post('/simulate-storm',           this.handleSimulateStorm.bind(this));
    return router;
  }

  /**
   * GET /admin/reports — Devuelve estadísticas globales de la plataforma.
   * Requiere permiso 'view_admin_reports' en 'users'.
   *
   * @param req — Request con req.user.role.
   * @param res — Response con objeto de estadísticas.
   * @param next — Manejador de errores.
   */
  private async handleReports(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const role = (req as AuthRequest).user.role as 'admin' | 'user';
      if (!hasPermission(role, 'view_admin_reports', 'users')) {
        throw new ForbiddenException('Se requiere rol admin');
      }

      const database = this.db.getDatabase();
      const [users, plants, posts, comments, messages] = await Promise.all([
        database.collection('users').countDocuments({ deletedAt: null }),
        database.collection('plants').countDocuments({ deletedAt: null }),
        database.collection('posts').countDocuments({ deletedAt: null }),
        database.collection('comments').countDocuments({ deletedAt: null }),
        database.collection('messages').countDocuments({}),
      ]);

      res.json({
        generatedAt: new Date().toISOString(),
        counts: { users, plants, posts, comments, messages },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /admin/users/search?q=... — Busca usuarios por nombre o email (regex).
   * Requiere permiso 'manage_users'.
   * Devuelve máximo 20 resultados con id, name, email y photo.
   *
   * @param req — Query: q (string de búsqueda).
   * @param res — Array de usuarios coincidentes.
   * @param next — Manejador de errores.
   */
  private async handleSearchUsers(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const role = (req as AuthRequest).user.role as 'admin' | 'user';
      if (!hasPermission(role, 'manage_users', 'users')) {
        throw new ForbiddenException('Se requiere rol admin');
      }

      const q = ((req.query['q'] as string) ?? '').trim();
      if (!q) {
        res.json([]);
        return;
      }

      // Escapar caracteres especiales de regex para evitar inyección.
      const escaped = q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const regex   = { $regex: escaped, $options: 'i' };

      const users = await this.db
        .getDatabase()
        .collection('users')
        .find({
          deletedAt: null,
          $or: [{ name: regex }, { email: regex }],
        })
        .project({ _id: 1, name: 1, email: 1, photo: 1 })
        .limit(20)
        .toArray();

      res.json(
        users.map((u) => ({
          id:    u['_id'].toHexString(),
          name:  u['name'],
          email: u['email'],
          photo: u['photo'] ?? null,
        })),
      );
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /admin/deleted-items — Lista elementos eliminados lógicamente (soft-deleted).
   * Requiere permiso 'manage_users'.
   *
   * @param req — Request con query ?type=users|plants|posts|comments.
   * @param res — Response con array de elementos eliminados.
   * @param next — Manejador de errores.
   */
  private async handleDeletedItems(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const role = (req as AuthRequest).user.role as 'admin' | 'user';
      if (!hasPermission(role, 'manage_users', 'users')) {
        throw new ForbiddenException('Se requiere rol admin');
      }

      const db = this.db.getDatabase();

      // Sin ?type: devuelve todos los tipos. Posts y comments filtrados por deletedByAdmin.
      if (!req.query['type']) {
        const [users, plants, posts, comments] = await Promise.all([
          db.collection('users').find({ deletedAt: { $ne: null } }).project({ passwordHash: 0, fcmToken: 0 }).limit(100).toArray(),
          db.collection('plants').find({ deletedAt: { $ne: null } }).limit(100).toArray(),
          db.collection('posts').find({ deletedAt: { $ne: null }, deletedByAdmin: true }).limit(100).toArray(),
          db.collection('comments').find({ deletedAt: { $ne: null }, deletedByAdmin: true }).limit(100).toArray(),
        ]);
        res.json({ users, plants, posts, comments });
        return;
      }

      const type = req.query['type'] as string;
      if (!(type in COLLECTION_MAP)) {
        throw new HttpException(`Tipo inválido: ${type}`, 400, 'VALIDATION_ERROR');
      }

      const collectionName = COLLECTION_MAP[type as RestorableType];
      const items = await db
        .collection(collectionName)
        .find({ deletedAt: { $ne: null } })
        .project({ passwordHash: 0, fcmToken: 0 })
        .limit(100)
        .toArray();

      res.json({ type, count: items.length, items });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /admin/restore/:type/:id — Restaura un elemento eliminado lógicamente.
   * Requiere permiso 'restore_deleted'.
   *
   * @param req — Request con req.params.type y req.params.id.
   * @param res — 200 con el elemento restaurado.
   * @param next — Manejador de errores.
   */
  private async handleRestore(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const role = (req as AuthRequest).user.role as 'admin' | 'user';
      if (!hasPermission(role, 'restore_deleted', 'users')) {
        throw new ForbiddenException('Se requiere rol admin');
      }

      const type = req.params['type'] as string;
      const id   = req.params['id'] as string;

      if (!(type in COLLECTION_MAP)) {
        throw new HttpException(`Tipo inválido: ${type}`, 400, 'VALIDATION_ERROR');
      }
      if (!ObjectId.isValid(id)) {
        throw new HttpException(`ID inválido: ${id}`, 400, 'VALIDATION_ERROR');
      }

      const collectionName = COLLECTION_MAP[type as RestorableType];

      // Para posts y comments: solo restaurar los eliminados por el admin.
      // Los eliminados por borrado de cuenta (preserveContent=false o cascada) no son
      // restaurables desde el panel — pertenecen al flujo de eliminación de usuario.
      if (type === 'posts' || type === 'comments') {
        const existing = await this.db.getDatabase()
          .collection(collectionName)
          .findOne({ _id: new ObjectId(id), deletedAt: { $ne: null } });
        if (!existing) {
          throw new HttpException(`Elemento no encontrado o no está eliminado: ${type}/${id}`, 404, 'NOT_FOUND');
        }
        if (!existing['deletedByAdmin']) {
          throw new ForbiddenException('Solo se pueden restaurar publicaciones eliminadas por el administrador');
        }
      }

      const result = await this.db.getDatabase()
        .collection(collectionName)
        .findOneAndUpdate(
          { _id: new ObjectId(id), deletedAt: { $ne: null } },
          { $set: { deletedAt: null, updatedAt: new Date() } },
          { returnDocument: 'after' },
        );

      if (!result) {
        throw new HttpException(`Elemento no encontrado o no está eliminado: ${type}/${id}`, 404, 'NOT_FOUND');
      }

      // Limpiar la marca de borrado por admin.
      await this.db.getDatabase()
        .collection(collectionName)
        .updateOne({ _id: new ObjectId(id) }, { $unset: { deletedByAdmin: '' } });

      // Notificar al propietario si es post o comment, con detalle del contenido restaurado.
      const ownerId = result['userId'];
      if ((type === 'posts' || type === 'comments') && ownerId) {
        let restoreMsg: string;

        if (type === 'posts') {
          const postContent  = (result['content'] as string | undefined) ?? '';
          const postImageUrl = (result['imageUrl'] as string | undefined) ?? '';
          const hasImage     = postImageUrl.length > 0;
          const hasText      = postContent.length > 0;
          const truncated    = postContent.length > 60 ? postContent.substring(0, 60) + '…' : postContent;

          let description: string;
          if (hasImage && hasText)       description = `con foto y texto '${truncated}'`;
          else if (hasImage && !hasText) description = 'con foto';
          else if (hasText)             description = `'${truncated}'`;
          else                          description = '';

          restoreMsg = description
            ? `Tu publicación ${description} ha sido aprobada tras revisión y vuelve a estar visible.`
            : 'Tu publicación ha sido aprobada tras revisión y vuelve a estar visible.';
        } else {
          const commentContent = (result['content'] as string | undefined) ?? '';
          const truncated      = commentContent.length > 60 ? commentContent.substring(0, 60) + '…' : commentContent;
          restoreMsg = truncated
            ? `Tu comentario '${truncated}' ha sido aprobado tras revisión y vuelve a estar visible.`
            : 'Tu comentario ha sido aprobado tras revisión y vuelve a estar visible.';
        }

        await this.db.getDatabase().collection('notifications').insertOne({
          userId: ownerId instanceof ObjectId ? ownerId : new ObjectId(String(ownerId)),
          isRead:    false,
          createdAt: new Date(),
          type:      'custom',
          message:   restoreMsg,
        });
        // Notificar vía socket para que el badge se actualice en tiempo real.
        this.socketService.emitToUser(String(ownerId), 'notification:new', {});
      }

      // Para comentarios restaurados: incrementar commentsCount del post.
      if (type === 'comments') {
        const postId = result['postId'];
        if (postId) {
          await this.db.getDatabase().collection('posts').updateOne(
            { _id: postId instanceof ObjectId ? postId : new ObjectId(String(postId)) },
            { $inc: { commentsCount: 1 } },
          );
        }
      }

      logger.info(`Admin restauró ${type}/${id}`);
      res.json({ message: 'Restaurado correctamente', item: result });
    } catch (error) {
      next(error);
    }
  }

  /**
   * DELETE /admin/posts/:id — Soft-delete de un post por admin.
   * Notifica al propietario y marca deletedByAdmin: true.
   *
   * @param req — Params: id.
   * @param res — 204 No Content.
   * @param next — Manejador de errores.
   */
  private async handleDeletePost(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const role = (req as AuthRequest).user.role as 'admin' | 'user';
      if (!hasPermission(role, 'delete', 'posts')) {
        throw new ForbiddenException('Se requiere rol admin');
      }

      const id = req.params['id'] as string;
      if (!ObjectId.isValid(id)) {
        throw new HttpException(`ID inválido: ${id}`, 400, 'VALIDATION_ERROR');
      }

      const db   = this.db.getDatabase();
      const post = await db.collection('posts').findOne({ _id: new ObjectId(id), deletedAt: null });
      if (!post) throw new NotFoundException(`Post ${id} no encontrado`);

      await db.collection('posts').updateOne(
        { _id: new ObjectId(id) },
        { $set: { deletedAt: new Date(), deletedByAdmin: true, updatedAt: new Date() } },
      );

      // Notificar al propietario del post con detalle del contenido eliminado.
      const ownerId = post['userId'];
      if (ownerId) {
        const postContent  = (post['content'] as string | undefined) ?? '';
        const postImageUrl = (post['imageUrl'] as string | undefined) ?? '';
        const hasImage     = postImageUrl.length > 0;
        const hasText      = postContent.length > 0;
        const truncated    = postContent.length > 60 ? postContent.substring(0, 60) + '…' : postContent;

        let description: string;
        if (hasImage && hasText)      description = `con foto y texto '${truncated}'`;
        else if (hasImage && !hasText) description = 'con foto';
        else if (hasText)             description = `'${truncated}'`;
        else                          description = '';

        const msg = description
          ? `Tu publicación ${description} ha sido eliminada por infringir las normas de la comunidad.`
          : 'Tu publicación ha sido eliminada por infringir las normas de la comunidad.';

        await db.collection('notifications').insertOne({
          userId:    ownerId instanceof ObjectId ? ownerId : new ObjectId(String(ownerId)),
          isRead:    false,
          createdAt: new Date(),
          type:      'custom',
          message:   msg,
        });
        // Notificar vía socket para que el badge se actualice en tiempo real.
        this.socketService.emitToUser(String(ownerId), 'notification:new', {});
      }

      // Notificar a todos los clientes que el feed ha cambiado (post eliminado por admin).
      this.socketService.broadcast('feed:updated', { action: 'deleted', postId: id });
      logger.info(`Admin eliminó post ${id}`);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  }

  /**
   * DELETE /admin/comments/:id — Soft-delete de un comentario por admin.
   * Notifica al propietario, decrementa commentsCount del post y marca deletedByAdmin: true.
   *
   * @param req — Params: id.
   * @param res — 204 No Content.
   * @param next — Manejador de errores.
   */
  private async handleDeleteComment(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const role = (req as AuthRequest).user.role as 'admin' | 'user';
      if (!hasPermission(role, 'delete', 'comments')) {
        throw new ForbiddenException('Se requiere rol admin');
      }

      const id = req.params['id'] as string;
      if (!ObjectId.isValid(id)) {
        throw new HttpException(`ID inválido: ${id}`, 400, 'VALIDATION_ERROR');
      }

      const db      = this.db.getDatabase();
      const comment = await db.collection('comments').findOne({ _id: new ObjectId(id), deletedAt: null });
      if (!comment) throw new NotFoundException(`Comentario ${id} no encontrado`);

      await db.collection('comments').updateOne(
        { _id: new ObjectId(id) },
        { $set: { deletedAt: new Date(), deletedByAdmin: true, updatedAt: new Date() } },
      );

      // Decrementar commentsCount del post padre.
      const postId = comment['postId'];
      if (postId) {
        // Prevenir contadores negativos: solo decrementar si commentsCount > 0.
        await db.collection('posts').updateOne(
          { _id: postId instanceof ObjectId ? postId : new ObjectId(String(postId)), commentsCount: { $gt: 0 } },
          { $inc: { commentsCount: -1 } },
        );
      }

      // Notificar al propietario del comentario con detalle del contenido eliminado.
      const ownerId = comment['userId'];
      if (ownerId) {
        const commentContent = (comment['content'] as string | undefined) ?? '';
        const truncated      = commentContent.length > 60 ? commentContent.substring(0, 60) + '…' : commentContent;
        const msg = truncated
          ? `Tu comentario '${truncated}' ha sido eliminado por infringir las normas de la comunidad.`
          : 'Tu comentario ha sido eliminado por infringir las normas de la comunidad.';

        await db.collection('notifications').insertOne({
          userId:    ownerId instanceof ObjectId ? ownerId : new ObjectId(String(ownerId)),
          isRead:    false,
          createdAt: new Date(),
          type:      'custom',
          message:   msg,
        });
        // Notificar vía socket para que el badge se actualice en tiempo real.
        this.socketService.emitToUser(String(ownerId), 'notification:new', {});
      }

      logger.info(`Admin eliminó comentario ${id}`);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /admin/trigger-reminders — Fuerza la ejecución del cron de recordatorios.
   * En producción requiere permiso 'trigger_reminders' (rol admin).
   * En NODE_ENV=development permite cualquier usuario autenticado (TFG: facilita pruebas).
   *
   * Si se indica body.username o query.username, genera TODAS las notificaciones posibles
   * para ese usuario (mocking de clima incluido) sin pasar por el lock del cron.
   * Si no se indica username, ejecuta el cron normal (processReminders.execute()).
   *
   * @param req — Request con body { username? } o query ?username=...
   * @param res — 200 con notificaciones generadas o confirmación del cron.
   * @param next — Manejador de errores.
   */
  private async handleTriggerReminders(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const role = (req as AuthRequest).user.role as 'admin' | 'user';
      const isDev = opsConfig.NODE_ENV !== 'production';

      // TFG: en desarrollo cualquier usuario puede disparar el cron para pruebas.
      if (!isDev && !hasPermission(role, 'trigger_reminders', 'reminders')) {
        throw new ForbiddenException('Se requiere rol admin para forzar el cron de recordatorios');
      }

      const username = (req.body?.username ?? req.query['username']) as string | undefined;

      // Sin username: comportamiento original — ejecutar el cron completo.
      if (!username) {
        logger.info(`handleTriggerReminders: cron completo forzado por rol '${role}'`);
        await this.processReminders.execute();
        res.json({ message: 'Cron de recordatorios ejecutado correctamente', triggeredAt: new Date().toISOString() });
        return;
      }

      // Con username: generar TODAS las notificaciones posibles para ese usuario.
      logger.info(`handleTriggerReminders: generando todas las notificaciones para '${username}'`);

      const db  = this.db.getDatabase();
      const now = new Date();

      // Buscar usuario por nombre (case-insensitive, no eliminado).
      const userDoc = await db.collection('users').findOne({
        name:      { $regex: `^${username}$`, $options: 'i' },
        deletedAt: null,
      });

      if (!userDoc) {
        throw new HttpException(`Usuario '${username}' no encontrado`, 404, 'NOT_FOUND');
      }

      const userId     = userDoc._id.toString();
      const generated: Array<{ type: string; plantName: string; message: string }> = [];

      // Obtener todas las plantas activas del usuario.
      // userId se almacena como ObjectId en MongoDB (ver PlantRepositoryImpl).
      const plants = await db.collection('plants')
        .find({ userId: new ObjectId(userId), deletedAt: null })
        .toArray();

      for (const plant of plants) {
        const plantId   = plant._id.toString();
        const plantName = plant.name as string;
        const location  = (plant.plantLocation as string | undefined) ?? 'tu zona';

        // Obtener especie asociada (speciesId se almacena como ObjectId en MongoDB).
        let species: Record<string, unknown> | null = null;
        if (plant.speciesId) {
          species = await db.collection('plant_species').findOne({ _id: plant.speciesId });
        }

        // userId y plantId se almacenan como ObjectId en la colección notifications.
        const notifBase = { userId: new ObjectId(userId), plantId: new ObjectId(plantId), isRead: false, createdAt: now };

        // 1. Riego (siempre).
        const wateringMsg = `Riego forzado para "${plantName}"`;
        await db.collection('notifications').insertOne({ ...notifBase, type: 'watering', message: wateringMsg });
        generated.push({ type: 'watering', plantName, message: wateringMsg });

        // 2. Poda (solo si la especie requiere poda).
        if (species?.requiresPruning) {
          const pruneMsg = `Poda forzada para "${plantName}" (${species['name']})`;
          await db.collection('notifications').insertOne({ ...notifBase, type: 'pruning', message: pruneMsg });
          generated.push({ type: 'pruning', plantName, message: pruneMsg });
        }

        // 3. Cosecha (solo si la especie produce fruto).
        if (species?.produceFruit) {
          const harvestMsg = `Cosecha forzada para "${plantName}" (${species['name']})`;
          await db.collection('notifications').insertOne({ ...notifBase, type: 'harvest', message: harvestMsg });
          generated.push({ type: 'harvest', plantName, message: harvestMsg });
        }

        // 4. Alerta de lluvia (mock: probabilidad 80%).
        const rainMsg = `Lluvia prevista en ${location} (80%). Se recomienda no regar "${plantName}" hoy.`;
        await db.collection('notifications').insertOne({ ...notifBase, type: 'watering', message: rainMsg });
        generated.push({ type: 'weather_rain', plantName, message: rainMsg });

        // 5. Alerta de tormenta (mock).
        const stormMsg = `Tormenta prevista mañana en ${location}. Considera proteger "${plantName}".`;
        await db.collection('notifications').insertOne({ ...notifBase, type: 'watering', message: stormMsg });
        generated.push({ type: 'weather_storm', plantName, message: stormMsg });
      }

      // Emit socket único por usuario tras generar todas sus notificaciones,
      // para que la pestaña Avisos del frontend refresque en caliente.
      // Si el usuario no está online es no-op.
      if (generated.length > 0) {
        try {
          this.socketService.emitToUser(userId, 'notification:new', {});
        } catch (err) {
          logger.warn(`emit notification:new failed for trigger-reminders/${userId}: ${(err as Error).message}`);
        }
      }

      logger.info(`handleTriggerReminders: ${generated.length} notificaciones generadas para '${username}'`);

      res.json({
        message:       `${generated.length} notificación(es) generada(s) para '${username}'`,
        username,
        userId,
        triggeredAt:   now.toISOString(),
        notifications: generated,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /admin/run-cron — Ejecuta la lógica completa del cron job de las 00:00.
   * Procesa riego, poda, cosecha y clima para TODOS los usuarios, exactamente
   * igual que el ReminderCronJob programado a medianoche.
   * Requiere permiso 'trigger_reminders' (en producción).
   *
   * @param req — Request con req.user.role.
   * @param res — 200 con confirmación y timestamp.
   * @param next — Manejador de errores.
   */
  private async handleRunCron(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const role = (req as AuthRequest).user.role as 'admin' | 'user';
      const isDev = opsConfig.NODE_ENV !== 'production';

      if (!isDev && !hasPermission(role, 'trigger_reminders', 'reminders')) {
        throw new ForbiddenException('Se requiere rol admin para ejecutar el cron');
      }

      const startedAt = new Date();
      logger.info(`handleRunCron: ejecución completa del cron forzada por rol '${role}'`);

      const summary = await this.processReminders.execute();

      const finishedAt = new Date();
      const durationMs = finishedAt.getTime() - startedAt.getTime();

      logger.info(
        `handleRunCron: summary total=${summary.created.total}, ` +
        `diagnostics=[${summary.diagnostics.join(', ')}]`,
      );

      res.json({
        message:    'Cron job ejecutado correctamente (lógica completa de 00:00)',
        startedAt:  startedAt.toISOString(),
        finishedAt: finishedAt.toISOString(),
        durationMs,
        summary,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /admin/simulate-rain — Genera notificaciones de lluvia simulada
   * para TODAS las plantas activas de TODOS los usuarios.
   * No llama a WeatherAPI; inserta directamente notificaciones de tipo 'watering'
   * con un mensaje de lluvia al 80%.
   * Requiere permiso 'trigger_reminders' (en producción).
   *
   * @param req — Request con req.user.role.
   * @param res — 200 con notificaciones generadas.
   * @param next — Manejador de errores.
   */
  private async handleSimulateRain(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const role = (req as AuthRequest).user.role as 'admin' | 'user';
      const isDev = opsConfig.NODE_ENV !== 'production';

      if (!isDev && !hasPermission(role, 'trigger_reminders', 'reminders')) {
        throw new ForbiddenException('Se requiere rol admin para simular lluvia');
      }

      const db  = this.db.getDatabase();
      const now = new Date();
      const generated: Array<{ plantName: string; userId: string; message: string }> = [];

      // Solo plantas de exterior reciben alertas de lluvia.
      const plants = await db.collection('plants')
        .find({ deletedAt: null, location: 'Exterior' })
        .toArray();

      // Agrupar plantas por usuario para enviar un único push agregado
      // por usuario en lugar de N pushes individuales (anti-spam).
      const plantsByUser = new Map<string, Array<{ plantId: string; plantName: string; location: string }>>();

      for (const plant of plants) {
        const plantId   = plant._id.toString();
        const userId    = plant.userId.toString();
        const plantName = plant.name as string;
        const location  = (plant.plantLocation as string | undefined) ?? 'tu zona';

        const message = NotificationMessages.watering.simulatedRain(plantName, location);
        await db.collection('notifications').insertOne({
          userId:    new ObjectId(userId),
          plantId:   new ObjectId(plantId),
          type:      'watering',
          message,
          isRead:    false,
          createdAt: now,
        });
        generated.push({ plantName, userId, message });

        const list = plantsByUser.get(userId) ?? [];
        list.push({ plantId, plantName, location });
        plantsByUser.set(userId, list);
      }

      // Push agrupado: 1 push por usuario. plantId solo si hay 1 alerta.
      // Emit socket `notification:new` por usuario para refrescar la
      // pestaña Avisos en caliente.
      for (const [userId, items] of plantsByUser.entries()) {
        const count = items.length;
        const body  = count === 1
          ? `Lluvia prevista en ${items[0]!.location}. No riegues "${items[0]!.plantName}" hoy.`
          : NotificationMessages.dailySummary.multipleAlertsRain(count);
        const firstPlantId = count === 1 ? items[0]!.plantId : undefined;
        await this._pushSummaryToUser(userId, '🌧 Lluvia prevista', body, 'rain_alert', firstPlantId);
        try {
          this.socketService.emitToUser(userId, 'notification:new', {});
        } catch (err) {
          logger.warn(`emit notification:new failed for simulate-rain/${userId}: ${(err as Error).message}`);
        }
      }

      logger.info(`handleSimulateRain: ${generated.length} notificaciones de lluvia generadas`);

      res.json({
        message:       `${generated.length} notificación(es) de lluvia generada(s)`,
        triggeredAt:   now.toISOString(),
        count:         generated.length,
        notifications: generated,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /admin/simulate-storm — Genera notificaciones de tormenta simulada
   * para TODAS las plantas activas de TODOS los usuarios.
   * No llama a WeatherAPI; inserta directamente notificaciones de tipo 'watering'
   * con un mensaje de alerta de tormenta.
   * Requiere permiso 'trigger_reminders' (en producción).
   *
   * @param req — Request con req.user.role.
   * @param res — 200 con notificaciones generadas.
   * @param next — Manejador de errores.
   */
  private async handleSimulateStorm(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const role = (req as AuthRequest).user.role as 'admin' | 'user';
      const isDev = opsConfig.NODE_ENV !== 'production';

      if (!isDev && !hasPermission(role, 'trigger_reminders', 'reminders')) {
        throw new ForbiddenException('Se requiere rol admin para simular tormenta');
      }

      const db  = this.db.getDatabase();
      const now = new Date();
      const generated: Array<{ plantName: string; userId: string; message: string }> = [];

      // Solo plantas de exterior reciben alertas de tormenta.
      const plants = await db.collection('plants')
        .find({ deletedAt: null, location: 'Exterior' })
        .toArray();

      // Agrupar plantas por usuario para enviar UN push agregado por
      // usuario en lugar de N pushes individuales (anti-spam).
      const plantsByUser = new Map<string, Array<{ plantId: string; plantName: string; location: string }>>();

      for (const plant of plants) {
        const plantId   = plant._id.toString();
        const userId    = plant.userId.toString();
        const plantName = plant.name as string;
        const location  = (plant.plantLocation as string | undefined) ?? 'tu zona';

        const message = NotificationMessages.watering.simulatedStorm(plantName, location);
        await db.collection('notifications').insertOne({
          userId:    new ObjectId(userId),
          plantId:   new ObjectId(plantId),
          type:      'watering',
          message,
          isRead:    false,
          createdAt: now,
        });
        generated.push({ plantName, userId, message });

        const list = plantsByUser.get(userId) ?? [];
        list.push({ plantId, plantName, location });
        plantsByUser.set(userId, list);
      }

      // Push agrupado: 1 push por usuario. Si solo hay 1 planta, pasamos
      // su plantId para que el tap abra el detalle (deep link directo).
      // Emit socket `notification:new` por usuario para refrescar Avisos
      // en caliente.
      for (const [userId, items] of plantsByUser.entries()) {
        const count = items.length;
        const body  = count === 1
          ? `Tormenta prevista en ${items[0]!.location}. Revisa "${items[0]!.plantName}".`
          : NotificationMessages.dailySummary.multipleAlertsStorm(count);
        const firstPlantId = count === 1 ? items[0]!.plantId : undefined;
        await this._pushSummaryToUser(userId, '⚡ Tormenta prevista', body, 'storm_alert', firstPlantId);
        try {
          this.socketService.emitToUser(userId, 'notification:new', {});
        } catch (err) {
          logger.warn(`emit notification:new failed for simulate-storm/${userId}: ${(err as Error).message}`);
        }
      }

      logger.info(`handleSimulateStorm: ${generated.length} notificaciones de tormenta generadas`);

      res.json({
        message:       `${generated.length} notificación(es) de tormenta generada(s)`,
        triggeredAt:   now.toISOString(),
        count:         generated.length,
        notifications: generated,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /admin/users/:id/ban — Banea temporalmente a un usuario.
   * Requiere permiso 'manage_users'.
   *
   * @param req — Params: id; Body: { duration: number } (días).
   * @param res — 200 con la fecha de desbaneo.
   * @param next — Manejador de errores.
   */
  private async handleBanUser(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const role = (req as AuthRequest).user.role as 'admin' | 'user';
      if (!hasPermission(role, 'manage_users', 'users')) {
        throw new ForbiddenException('Se requiere rol admin');
      }

      const id       = req.params['id'] as string;
      const duration = (req.body as { duration?: number }).duration;

      if (!ObjectId.isValid(id)) {
        throw new HttpException(`ID inválido: ${id}`, 400, 'VALIDATION_ERROR');
      }
      if (!duration || typeof duration !== 'number' || duration < 1) {
        throw new HttpException('duration debe ser un número >= 1 (días)', 400, 'VALIDATION_ERROR');
      }

      const bannedUntil = new Date();
      bannedUntil.setDate(bannedUntil.getDate() + duration);

      const result = await this.db.getDatabase()
        .collection('users')
        .updateOne(
          { _id: new ObjectId(id), deletedAt: null },
          { $set: { bannedUntil, updatedAt: new Date() } },
        );

      if (result.matchedCount === 0) {
        throw new NotFoundException(`Usuario ${id} no encontrado`);
      }

      // Notificar al usuario baneado.
      await this.db.getDatabase().collection('notifications').insertOne({
        userId:    new ObjectId(id),
        isRead:    false,
        createdAt: new Date(),
        type:      'admin_warning',
        message:   `Tu cuenta ha sido suspendida temporalmente hasta el ${bannedUntil.toLocaleDateString('es-ES')}. Durante este período no podrás publicar, comentar ni dar like.`,
      });
      // Notificar vía socket para que el badge se actualice en tiempo real.
      this.socketService.emitToUser(id, 'notification:new', {});

      logger.info(`Admin baneó a usuario ${id} por ${duration} día(s)`);
      res.json({ message: `Usuario baneado hasta ${bannedUntil.toISOString()}`, bannedUntil });
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /admin/users/:id/warn — Envía un aviso/notificación a un usuario.
   * Requiere permiso 'manage_users'.
   *
   * @param req — Params: id; Body: { message: string }.
   * @param res — 204 No Content.
   * @param next — Manejador de errores.
   */
  private async handleWarnUser(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const role = (req as AuthRequest).user.role as 'admin' | 'user';
      if (!hasPermission(role, 'manage_users', 'users')) {
        throw new ForbiddenException('Se requiere rol admin');
      }

      const id      = req.params['id'] as string;
      const message = ((req.body as { message?: string }).message ?? '').trim();

      if (!ObjectId.isValid(id)) {
        throw new HttpException(`ID inválido: ${id}`, 400, 'VALIDATION_ERROR');
      }
      if (!message) {
        throw new HttpException('El mensaje del aviso es obligatorio', 400, 'VALIDATION_ERROR');
      }

      // Verificar que el usuario existe.
      const userDoc = await this.db.getDatabase()
        .collection('users')
        .findOne({ _id: new ObjectId(id), deletedAt: null });
      if (!userDoc) {
        throw new NotFoundException(`Usuario ${id} no encontrado`);
      }

      await this.db.getDatabase().collection('notifications').insertOne({
        userId:    new ObjectId(id),
        isRead:    false,
        createdAt: new Date(),
        type:      'admin_warning',
        message:   `Aviso del administrador: ${message}`,
      });
      // Notificar vía socket para que el badge se actualice en tiempo real.
      this.socketService.emitToUser(id, 'notification:new', {});

      logger.info(`Admin envió aviso a usuario ${id}`);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /admin/diagnostics — Información del sistema y estado de servicios.
   * Requiere permiso 'view_admin_reports'.
   *
   * @param req — Request con req.user.role.
   * @param res — Response con info de Node.js, uptime y memoria.
   * @param next — Manejador de errores.
   */
  private async handleDiagnostics(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const role = (req as AuthRequest).user.role as 'admin' | 'user';
      if (!hasPermission(role, 'view_admin_reports', 'users')) {
        throw new ForbiddenException('Se requiere rol admin');
      }

      const mem = process.memoryUsage();

      // Verificar conectividad MongoDB
      let dbStatus = 'disconnected';
      try {
        await this.db.getDatabase().command({ ping: 1 });
        dbStatus = 'connected';
      } catch {
        dbStatus = 'error';
      }

      res.json({
        timestamp:    new Date().toISOString(),
        nodeVersion:  process.version,
        uptime:       Math.floor(process.uptime()),
        memoryMb: {
          rss:       Math.round(mem.rss / 1024 / 1024),
          heapUsed:  Math.round(mem.heapUsed / 1024 / 1024),
          heapTotal: Math.round(mem.heapTotal / 1024 / 1024),
        },
        database: { status: dbStatus },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /admin/incident-reports — Lista todos los reportes de incidencias.
   * Devuelve los reportes ordenados por createdAt desc (más recientes primero).
   *
   * @param req — Request con req.user.role.
   * @param res — Array de reportes serializados.
   * @param next — Manejador de errores.
   */
  private async handleIncidentReports(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const role = (req as AuthRequest).user.role as 'admin' | 'user';
      if (!hasPermission(role, 'view_admin_reports', 'users')) {
        throw new ForbiddenException('Se requiere rol admin');
      }

      // ── Filtros opcionales por query params ──
      const { ticketNumber, status, from, to } = req.query as {
        ticketNumber?: string;
        status?:       string;
        from?:         string;
        to?:           string;
      };

      const filter: Record<string, unknown> = {};

      if (ticketNumber) {
        const num = parseInt(ticketNumber, 10);
        if (!isNaN(num)) filter['ticketNumber'] = num;
      }

      if (status && ['pending', 'resolved', 'dismissed'].includes(status)) {
        filter['status'] = status;
      }

      if (from || to) {
        const dateFilter: Record<string, Date> = {};
        if (from) dateFilter['$gte'] = new Date(from);
        if (to) {
          // Ajustar al final del día para incluir todas las incidencias del día 'to'.
          // new Date('2026-04-08') → 00:00:00 excluiría el día completo.
          const toDate = new Date(to);
          toDate.setHours(23, 59, 59, 999);
          dateFilter['$lte'] = toDate;
        }
        if (Object.keys(dateFilter).length > 0) {
          filter['createdAt'] = dateFilter;
        }
      }

      const db      = this.db.getDatabase();
      const reports = await db
        .collection('reports')
        .find(filter)
        .sort({ createdAt: -1 })
        .limit(200)
        .toArray();

      // Para reportes de tipo 'comment', obtener el postId del comentario
      // para que el frontend pueda navegar al post padre.
      const commentTargetIds = reports
        .filter((r) => r['type'] === 'comment' && r['targetId'])
        .map((r) => r['targetId'] as ObjectId);

      const commentPostMap = new Map<string, string>();
      if (commentTargetIds.length > 0) {
        const comments = await db
          .collection('comments')
          .find({ _id: { $in: commentTargetIds } })
          .project({ _id: 1, postId: 1 })
          .toArray();
        for (const c of comments) {
          commentPostMap.set(
            c['_id'].toHexString(),
            (c['postId'] as ObjectId).toHexString(),
          );
        }
      }

      res.json(
        reports.map((r) => {
          const targetHex  = r['targetId']?.toHexString?.();
          const resolvedBy = r['resolvedBy'] as
            | { adminId: string; adminName: string; resolvedAt: Date }
            | undefined;
          return {
            id:           r['_id'].toHexString(),
            userId:       r['userId']?.toHexString?.() ?? String(r['userId']),
            type:         r['type'],
            targetId:     targetHex,
            // postId del comentario reportado (para navegación al post padre).
            ...(r['type'] === 'comment' && targetHex
              ? { postId: commentPostMap.get(targetHex) }
              : {}),
            text:         r['text'],
            imageUrl:     r['imageUrl'],
            status:       r['status'],
            ticketNumber: r['ticketNumber'] as number | undefined,
            resolvedBy:   resolvedBy
              ? {
                  adminId:    resolvedBy.adminId,
                  adminName:  resolvedBy.adminName,
                  resolvedAt: (resolvedBy.resolvedAt as Date)?.toISOString?.(),
                }
              : undefined,
            createdAt:    (r['createdAt'] as Date)?.toISOString?.(),
          };
        }),
      );
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /admin/incident-reports/:id — Actualiza el estado de un reporte.
   * Acepta status: 'resolved' | 'dismissed' | 'pending' (reabrir).
   * Almacena resolvedBy con datos del admin al resolver/descartar.
   * Al reabrir (pending), limpia resolvedBy.
   *
   * @param req — Params: id; Body: { status }.
   * @param res — 204 No Content.
   * @param next — Manejador de errores.
   */
  private async handleResolveReport(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const authUser = (req as AuthRequest).user;
      const role     = authUser.role as 'admin' | 'user';
      if (!hasPermission(role, 'view_admin_reports', 'users')) {
        throw new ForbiddenException('Se requiere rol admin');
      }

      const { id }     = req.params;
      const { status } = req.body as { status: string };

      if (!['resolved', 'dismissed', 'pending'].includes(status)) {
        throw new HttpException(
          'Estado inválido: debe ser "resolved", "dismissed" o "pending"',
          400,
          'VALIDATION_ERROR',
        );
      }

      const db = this.db.getDatabase();

      // Construir actualización según el nuevo estado.
      let updateOp: Record<string, unknown>;

      if (status === 'pending') {
        // Reabrir: limpiar resolvedBy.
        updateOp = { $set: { status }, $unset: { resolvedBy: '' } };
      } else {
        // Resolver/descartar: almacenar quién lo hizo.
        // Obtener nombre del admin desde la colección users.
        const adminDoc = await db
          .collection('users')
          .findOne(
            { _id: new ObjectId(authUser.userId) },
            { projection: { name: 1 } },
          );
        const adminName = (adminDoc?.['name'] as string) ?? 'Admin';

        updateOp = {
          $set: {
            status,
            resolvedBy: {
              adminId:    authUser.userId,
              adminName,
              resolvedAt: new Date(),
            },
          },
        };
      }

      const result = await db
        .collection('reports')
        .updateOne(
          { _id: new ObjectId(id as string) },
          updateOp,
        );

      if (result.matchedCount === 0) {
        throw new NotFoundException(`Reporte ${id} no encontrado`);
      }

      res.status(204).send();
    } catch (error) {
      next(error);
    }
  }
}
