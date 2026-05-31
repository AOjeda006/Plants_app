/**
 * @file container.ts
 * @description Contenedor de inyección de dependencias (Inversify).
 * Registra todos los singletons, repositorios, mappers, use cases y controllers.
 * Este archivo se actualiza incrementalmente conforme se implementan las capas.
 * @module Core
 * @layer Core
 */

import 'reflect-metadata';
import { Container } from 'inversify';
import { TYPES } from './types.js';
import { opsConfig } from './config/ops.config.js';
import { createLogger } from './logger.js';

// ─── Infraestructura ────────────────────────────────────────────────────────
import { MongoDBConnection } from '../data/datasources/mongodb/MongoDBConnection.js';

// ─── Lock Service ─────────────────────────────────────────────────────────────
import { ILockService } from '../presentation/services/LockService.js';
import { InMemoryLockService } from '../presentation/services/InMemoryLockService.js';

// ─── Mappers ─────────────────────────────────────────────────────────────────
import { UserMapper } from '../data/mappers/user_mapper.js';
import { PlantMapper } from '../data/mappers/plant_mapper.js';
import { PlantSpeciesMapper } from '../data/mappers/plant_species_mapper.js';
import { WeatherMapper } from '../data/mappers/weather_mapper.js';
import { ReminderMapper } from '../data/mappers/reminder_mapper.js';
import { ReminderHistoryMapper } from '../data/mappers/reminder_history_mapper.js';
import { PostMapper } from '../data/mappers/post_mapper.js';
import { CommentMapper } from '../data/mappers/comment_mapper.js';
import { ConversationMapper } from '../data/mappers/conversation_mapper.js';
import { MessageMapper } from '../data/mappers/message_mapper.js';
import { NotificationMapper } from '../data/mappers/notification_mapper.js';

// ─── Repositorios ─────────────────────────────────────────────────────────────
import { UserRepositoryImpl } from '../data/repositories/user_repository_impl.js';
import { PlantRepositoryImpl } from '../data/repositories/plant_repository_impl.js';
import { PlantSpeciesRepositoryImpl } from '../data/repositories/plant_species_repository_impl.js';
import { WeatherCacheRepositoryImpl } from '../data/repositories/weather_cache_repository_impl.js';
import { ReminderRepositoryImpl } from '../data/repositories/reminder_repository_impl.js';
import { ReminderHistoryRepositoryImpl } from '../data/repositories/reminder_history_repository_impl.js';
import { PostRepositoryImpl } from '../data/repositories/post_repository_impl.js';
import { PostLikeRepositoryImpl } from '../data/repositories/post_like_repository_impl.js';
import { CommentRepositoryImpl } from '../data/repositories/comment_repository_impl.js';
import { ConversationRepositoryImpl } from '../data/repositories/conversation_repository_impl.js';
import { MessageRepositoryImpl } from '../data/repositories/message_repository_impl.js';
import { NotificationRepositoryImpl } from '../data/repositories/notification_repository_impl.js';

// ─── Datasources externos ─────────────────────────────────────────────────────
import { CloudinaryDataSource } from '../data/datasources/external/CloudinaryDataSource.js';
import { WeatherAPIDataSource } from '../data/datasources/external/WeatherAPIDataSource.js';
import { FirebaseAdminDataSource } from '../data/datasources/external/FirebaseAdminDataSource.js';

// ─── Servicios de presentación ────────────────────────────────────────────────
import { HashService } from '../presentation/services/HashService.js';
import { JwtService } from '../presentation/services/JwtService.js';
import { WeatherService } from '../presentation/services/WeatherService.js';
import { ReminderService } from '../presentation/services/ReminderService.js';
import { NotificationService } from '../presentation/services/NotificationService.js';
import { SocketService } from '../presentation/services/SocketService.js';

// ─── Use Cases — Auth ─────────────────────────────────────────────────────────
import { RegisterUserUseCase } from '../domain/usecases/auth/RegisterUserUseCase.js';
import { LoginUserUseCase } from '../domain/usecases/auth/LoginUserUseCase.js';
import { ValidateTokenUseCase } from '../domain/usecases/auth/ValidateTokenUseCase.js';
import { RefreshTokenUseCase } from '../domain/usecases/auth/RefreshTokenUseCase.js';

// ─── Use Cases — Plants ───────────────────────────────────────────────────────
import { GetUserPlantsUseCase } from '../domain/usecases/plants/GetUserPlantsUseCase.js';
import { GetPlantByIdUseCase } from '../domain/usecases/plants/GetPlantByIdUseCase.js';
import { CreatePlantUseCase } from '../domain/usecases/plants/CreatePlantUseCase.js';
import { UpdatePlantUseCase } from '../domain/usecases/plants/UpdatePlantUseCase.js';
import { DeletePlantUseCase } from '../domain/usecases/plants/DeletePlantUseCase.js';
import { SearchSpeciesUseCase } from '../domain/usecases/plants/SearchSpeciesUseCase.js';

// ─── Use Cases — Weather ──────────────────────────────────────────────────────
import { GetCurrentWeatherUseCase } from '../domain/usecases/weather/GetCurrentWeatherUseCase.js';
import { GetWeatherForecastUseCase } from '../domain/usecases/weather/GetWeatherForecastUseCase.js';

// ─── Use Cases — Reminders ────────────────────────────────────────────────────
import { GetUserRemindersUseCase } from '../domain/usecases/reminders/GetUserRemindersUseCase.js';
import { MarkReminderCompletedUseCase } from '../domain/usecases/reminders/MarkReminderCompletedUseCase.js';
import { ProcessPendingRemindersUseCase } from '../domain/usecases/reminders/ProcessPendingRemindersUseCase.js';

// ─── Use Cases — Notifications ────────────────────────────────────────────────
import { GetUserNotificationsUseCase } from '../domain/usecases/notifications/GetUserNotificationsUseCase.js';
import { MarkNotificationsReadUseCase } from '../domain/usecases/notifications/MarkNotificationsReadUseCase.js';
import { DeleteNotificationsUseCase } from '../domain/usecases/notifications/DeleteNotificationsUseCase.js';

// ─── Use Cases — Community ────────────────────────────────────────────────────
import { GetFeedUseCase } from '../domain/usecases/community/GetFeedUseCase.js';
import { GetPostByIdUseCase } from '../domain/usecases/community/GetPostByIdUseCase.js';
import { CreatePostUseCase } from '../domain/usecases/community/CreatePostUseCase.js';
import { LikePostUseCase } from '../domain/usecases/community/LikePostUseCase.js';
import { UnlikePostUseCase } from '../domain/usecases/community/UnlikePostUseCase.js';
import { GetPostCommentsUseCase } from '../domain/usecases/community/GetPostCommentsUseCase.js';
import { CreateCommentUseCase } from '../domain/usecases/community/CreateCommentUseCase.js';
import { DeletePostUseCase } from '../domain/usecases/community/DeletePostUseCase.js';
import { DeleteCommentUseCase } from '../domain/usecases/community/DeleteCommentUseCase.js';

// ─── Use Cases — Chat ─────────────────────────────────────────────────────────
import { GetOrCreateConversationUseCase } from '../domain/usecases/chat/GetOrCreateConversationUseCase.js';
import { GetUserConversationsUseCase } from '../domain/usecases/chat/GetUserConversationsUseCase.js';
import { GetConversationMessagesUseCase } from '../domain/usecases/chat/GetConversationMessagesUseCase.js';
import { SendMessageUseCase } from '../domain/usecases/chat/SendMessageUseCase.js';
import { MarkMessagesAsReadUseCase } from '../domain/usecases/chat/MarkMessagesAsReadUseCase.js';

// ─── Controllers ─────────────────────────────────────────────────────────────
import { AuthController } from '../presentation/controllers/AuthController.js';
import { PlantController } from '../presentation/controllers/PlantController.js';
import { SpeciesController } from '../presentation/controllers/SpeciesController.js';
import { UploadController } from '../presentation/controllers/UploadController.js';
import { WeatherController } from '../presentation/controllers/WeatherController.js';
import { ReminderController } from '../presentation/controllers/ReminderController.js';
import { PostController } from '../presentation/controllers/PostController.js';
import { ChatController } from '../presentation/controllers/ChatController.js';
import { SocketGateway } from '../presentation/gateways/SocketGateway.js';

// ─── Use Cases — User ─────────────────────────────────────────────────────────
import { GetUserByIdUseCase } from '../domain/usecases/user/GetUserByIdUseCase.js';
import { UpdateUserProfileUseCase } from '../domain/usecases/user/UpdateUserProfileUseCase.js';
import { UpdateUserPreferencesUseCase } from '../domain/usecases/user/UpdateUserPreferencesUseCase.js';
import { ChangePasswordUseCase } from '../domain/usecases/user/ChangePasswordUseCase.js';
import { DeleteUserAccountUseCase } from '../domain/usecases/user/DeleteUserAccountUseCase.js';
import { ExportUserDataUseCase } from '../domain/usecases/user/ExportUserDataUseCase.js';

// ─── Controllers — User / Admin / Locations ───────────────────────────────────
import { UserController } from '../presentation/controllers/UserController.js';
import { AdminController } from '../presentation/controllers/AdminController.js';
import { LocationController } from '../presentation/controllers/LocationController.js';
import { NotificationController } from '../presentation/controllers/NotificationController.js';
import { ReportController } from '../presentation/controllers/ReportController.js';

// ─── Jobs ─────────────────────────────────────────────────────────────────────
import { ReminderCronJob } from '../presentation/jobs/ReminderCronJob.js';
import { CleanupExpiredWeatherCacheJob } from '../presentation/jobs/CleanupExpiredWeatherCacheJob.js';
import { PurgeSoftDeletedJob } from '../presentation/jobs/PurgeSoftDeletedJob.js';

const logger = createLogger('Container');

/**
 * Registra `InMemoryLockService` como implementación de `ILockService`.
 *
 * TFG: el proyecto opera siempre en modo single-instance (Render Free Tier),
 * por lo que el lock en memoria es suficiente. Una alternativa basada en
 * Redis estaría justificada en producción multi-instancia; si en el futuro
 * se necesitase, se añadiría aquí un bind condicional basado en
 * `opsConfig.REDIS_URL`.
 *
 * @param container — Instancia del contenedor Inversify.
 * @private
 */
function bindLocks(container: Container): void {
  container.bind<ILockService>(TYPES.LockService).to(InMemoryLockService).inSingletonScope();
  if (opsConfig.REDIS_URL) {
    logger.warn('REDIS_URL definida pero RedisLockService no implementado — usando InMemoryLockService');
  }
}

/**
 * Registra metadatos de limitaciones TFG en el container para trazabilidad.
 *
 * @param container — Instancia del contenedor Inversify.
 * @private
 */
function registerTFGLimits(container: Container): void {
  // TFG: anotar en metadata que el sistema asume single-instance
  logger.info('TFG mode: single-instance assumptions activas (LockService en memoria, sin replica set requerido)');
}

/**
 * Configura y devuelve el contenedor Inversify con todas las dependencias registradas.
 * Se llama una vez en bootstrap() antes de iniciar el servidor HTTP.
 *
 * @param options.isProduction — Si true, aplica configuraciones de producción.
 * @returns {Container} Contenedor configurado.
 */
export async function configureContainer(
  options: { isProduction: boolean } = { isProduction: false },
): Promise<Container> {
  const container = new Container({ defaultScope: 'Singleton' });

  // ─── Infraestructura ──────────────────────────────────────────────────────
  container.bind<MongoDBConnection>(TYPES.MongoDBConnection)
    .to(MongoDBConnection)
    .inSingletonScope();

  // ─── Lock Service ─────────────────────────────────────────────────────────
  bindLocks(container);

  // ─── Datasources externos ─────────────────────────────────────────────────
  container.bind(TYPES.CloudinaryDataSource).to(CloudinaryDataSource).inSingletonScope();
  container.bind(TYPES.WeatherDataSource).to(WeatherAPIDataSource).inSingletonScope();
  container.bind(TYPES.FirebaseDataSource).to(FirebaseAdminDataSource).inSingletonScope();

  // ─── Mappers ──────────────────────────────────────────────────────────────
  container.bind(TYPES.IUserMapper).to(UserMapper).inSingletonScope();
  container.bind(TYPES.IPlantMapper).to(PlantMapper).inSingletonScope();
  container.bind(TYPES.IPlantSpeciesMapper).to(PlantSpeciesMapper).inSingletonScope();
  container.bind(TYPES.IWeatherCacheMapper).to(WeatherMapper).inSingletonScope();
  container.bind(TYPES.IReminderMapper).to(ReminderMapper).inSingletonScope();
  container.bind(TYPES.IReminderHistoryMapper).to(ReminderHistoryMapper).inSingletonScope();
  container.bind(TYPES.IPostMapper).to(PostMapper).inSingletonScope();
  container.bind(TYPES.ICommentMapper).to(CommentMapper).inSingletonScope();
  container.bind(TYPES.IConversationMapper).to(ConversationMapper).inSingletonScope();
  container.bind(TYPES.IMessageMapper).to(MessageMapper).inSingletonScope();
  container.bind(TYPES.INotificationMapper).to(NotificationMapper).inSingletonScope();

  // ─── Repositorios ─────────────────────────────────────────────────────────
  container.bind(TYPES.IUserRepository).to(UserRepositoryImpl).inSingletonScope();
  container.bind(TYPES.IPlantRepository).to(PlantRepositoryImpl).inSingletonScope();
  container.bind(TYPES.IPlantSpeciesRepository).to(PlantSpeciesRepositoryImpl).inSingletonScope();
  container.bind(TYPES.IWeatherCacheRepository).to(WeatherCacheRepositoryImpl).inSingletonScope();
  container.bind(TYPES.IReminderRepository).to(ReminderRepositoryImpl).inSingletonScope();
  container.bind(TYPES.IReminderHistoryRepository).to(ReminderHistoryRepositoryImpl).inSingletonScope();
  container.bind(TYPES.IPostRepository).to(PostRepositoryImpl).inSingletonScope();
  container.bind(TYPES.IPostLikeRepository).to(PostLikeRepositoryImpl).inSingletonScope();
  container.bind(TYPES.ICommentRepository).to(CommentRepositoryImpl).inSingletonScope();
  container.bind(TYPES.IConversationRepository).to(ConversationRepositoryImpl).inSingletonScope();
  container.bind(TYPES.IMessageRepository).to(MessageRepositoryImpl).inSingletonScope();
  container.bind(TYPES.INotificationRepository).to(NotificationRepositoryImpl).inSingletonScope();

  // ─── Servicios de presentación ────────────────────────────────────────────
  container.bind(TYPES.HashService).to(HashService).inSingletonScope();
  container.bind(TYPES.JwtService).to(JwtService).inSingletonScope();
  container.bind(TYPES.WeatherService).to(WeatherService).inSingletonScope();
  container.bind(TYPES.ReminderService).to(ReminderService).inSingletonScope();
  container.bind(TYPES.NotificationService).to(NotificationService).inSingletonScope();
  container.bind(TYPES.SocketService).to(SocketService).inSingletonScope();

  // ─── Use Cases — Auth ─────────────────────────────────────────────────────
  container.bind(TYPES.IRegisterUserUseCase).to(RegisterUserUseCase).inTransientScope();
  container.bind(TYPES.ILoginUserUseCase).to(LoginUserUseCase).inTransientScope();
  container.bind(TYPES.IValidateTokenUseCase).to(ValidateTokenUseCase).inTransientScope();
  container.bind(TYPES.IRefreshTokenUseCase).to(RefreshTokenUseCase).inTransientScope();

  // ─── Use Cases — Plants ───────────────────────────────────────────────────
  container.bind(TYPES.IGetUserPlantsUseCase).to(GetUserPlantsUseCase).inTransientScope();
  container.bind(TYPES.IGetPlantByIdUseCase).to(GetPlantByIdUseCase).inTransientScope();
  container.bind(TYPES.ICreatePlantUseCase).to(CreatePlantUseCase).inTransientScope();
  container.bind(TYPES.IUpdatePlantUseCase).to(UpdatePlantUseCase).inTransientScope();
  container.bind(TYPES.IDeletePlantUseCase).to(DeletePlantUseCase).inTransientScope();
  container.bind(TYPES.ISearchSpeciesUseCase).to(SearchSpeciesUseCase).inTransientScope();

  // ─── Use Cases — Weather ──────────────────────────────────────────────────
  container.bind(TYPES.IGetCurrentWeatherUseCase).to(GetCurrentWeatherUseCase).inTransientScope();
  container.bind(TYPES.IGetWeatherForecastUseCase).to(GetWeatherForecastUseCase).inTransientScope();

  // ─── Use Cases — Reminders ────────────────────────────────────────────────
  container.bind(TYPES.IGetUserRemindersUseCase).to(GetUserRemindersUseCase).inTransientScope();
  container.bind(TYPES.IMarkReminderCompletedUseCase).to(MarkReminderCompletedUseCase).inTransientScope();
  container.bind(TYPES.IProcessPendingRemindersUseCase).to(ProcessPendingRemindersUseCase).inSingletonScope();

  // ─── Use Cases — Notifications ─────────────────────────────────────────────
  container.bind(TYPES.IGetUserNotificationsUseCase).to(GetUserNotificationsUseCase).inTransientScope();
  container.bind(TYPES.IMarkNotificationsReadUseCase).to(MarkNotificationsReadUseCase).inTransientScope();
  container.bind(TYPES.IDeleteNotificationsUseCase).to(DeleteNotificationsUseCase).inTransientScope();

  // ─── Use Cases — Chat ─────────────────────────────────────────────────────
  container.bind(TYPES.IGetOrCreateConversationUseCase).to(GetOrCreateConversationUseCase).inTransientScope();
  container.bind(TYPES.IGetConversationsUseCase).to(GetUserConversationsUseCase).inTransientScope();
  container.bind(TYPES.IGetMessagesUseCase).to(GetConversationMessagesUseCase).inTransientScope();
  container.bind(TYPES.ISendMessageUseCase).to(SendMessageUseCase).inTransientScope();
  container.bind(TYPES.IMarkMessagesReadUseCase).to(MarkMessagesAsReadUseCase).inTransientScope();

  // ─── Use Cases — User ─────────────────────────────────────────────────────
  container.bind(TYPES.IGetUserProfileUseCase).to(GetUserByIdUseCase).inTransientScope();
  container.bind(TYPES.IUpdateUserProfileUseCase).to(UpdateUserProfileUseCase).inTransientScope();
  container.bind(TYPES.IUpdateUserPreferencesUseCase).to(UpdateUserPreferencesUseCase).inTransientScope();
  container.bind(TYPES.IChangePasswordUseCase).to(ChangePasswordUseCase).inTransientScope();
  container.bind(TYPES.IDeleteAccountUseCase).to(DeleteUserAccountUseCase).inTransientScope();
  container.bind(TYPES.IExportUserDataUseCase).to(ExportUserDataUseCase).inTransientScope();

  // ─── Use Cases — Community ────────────────────────────────────────────────
  container.bind(TYPES.IGetFeedUseCase).to(GetFeedUseCase).inTransientScope();
  container.bind(TYPES.IGetPostByIdUseCase).to(GetPostByIdUseCase).inTransientScope();
  container.bind(TYPES.ICreatePostUseCase).to(CreatePostUseCase).inTransientScope();
  container.bind(TYPES.ILikePostUseCase).to(LikePostUseCase).inTransientScope();
  container.bind(TYPES.IUnlikePostUseCase).to(UnlikePostUseCase).inTransientScope();
  container.bind(TYPES.IGetPostCommentsUseCase).to(GetPostCommentsUseCase).inTransientScope();
  container.bind(TYPES.IAddCommentUseCase).to(CreateCommentUseCase).inTransientScope();
  container.bind(TYPES.IDeletePostUseCase).to(DeletePostUseCase).inTransientScope();
  container.bind(TYPES.IDeleteCommentUseCase).to(DeleteCommentUseCase).inTransientScope();

  // ─── Controllers ──────────────────────────────────────────────────────────
  container.bind(TYPES.AuthController).to(AuthController).inTransientScope();
  container.bind(TYPES.PlantController).to(PlantController).inTransientScope();
  container.bind(TYPES.SpeciesController).to(SpeciesController).inTransientScope();
  container.bind(TYPES.UploadController).to(UploadController).inTransientScope();
  container.bind(TYPES.WeatherController).to(WeatherController).inTransientScope();
  container.bind(TYPES.ReminderController).to(ReminderController).inTransientScope();
  container.bind(TYPES.PostController).to(PostController).inTransientScope();
  container.bind(TYPES.ChatController).to(ChatController).inTransientScope();
  container.bind(TYPES.UserController).to(UserController).inTransientScope();
  container.bind(TYPES.AdminController).to(AdminController).inTransientScope();
  container.bind(TYPES.LocationController).to(LocationController).inTransientScope();
  container.bind(TYPES.NotificationController).to(NotificationController).inTransientScope();
  container.bind(TYPES.ReportController).to(ReportController).inTransientScope();
  container.bind(SocketGateway).to(SocketGateway).inSingletonScope();

  // ─── Jobs ─────────────────────────────────────────────────────────────────
  container.bind(ReminderCronJob).to(ReminderCronJob).inSingletonScope();
  container.bind(CleanupExpiredWeatherCacheJob).to(CleanupExpiredWeatherCacheJob).inSingletonScope();
  container.bind(PurgeSoftDeletedJob).to(PurgeSoftDeletedJob).inSingletonScope();

  registerTFGLimits(container);

  logger.info(`Contenedor DI configurado [${options.isProduction ? 'producción' : 'desarrollo'}]`);

  return container;
}
