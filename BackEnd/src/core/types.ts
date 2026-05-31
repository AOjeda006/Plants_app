/**
 * @file types.ts
 * @description Constantes de identificadores para el contenedor de inyección de dependencias (Inversify).
 * Cada símbolo corresponde a una interfaz o clase registrada en container.ts.
 * @module Core
 * @layer Core
 */

export const TYPES = {

  // ─── Infraestructura ────────────────────────────────────────────────────────

  MongoDBConnection: Symbol.for('MongoDBConnection'),

  // ─── Repositorios ───────────────────────────────────────────────────────────

  IUserRepository:            Symbol.for('IUserRepository'),
  IPlantRepository:           Symbol.for('IPlantRepository'),
  IPlantSpeciesRepository:    Symbol.for('IPlantSpeciesRepository'),
  IReminderRepository:        Symbol.for('IReminderRepository'),
  IReminderHistoryRepository: Symbol.for('IReminderHistoryRepository'),
  IPostRepository:            Symbol.for('IPostRepository'),
  IPostLikeRepository:        Symbol.for('IPostLikeRepository'),
  ICommentRepository:         Symbol.for('ICommentRepository'),
  IConversationRepository:    Symbol.for('IConversationRepository'),
  IMessageRepository:         Symbol.for('IMessageRepository'),
  IWeatherCacheRepository:    Symbol.for('IWeatherCacheRepository'),
  INotificationRepository:    Symbol.for('INotificationRepository'),

  // ─── Servicios de presentación ──────────────────────────────────────────────

  HashService:         Symbol.for('HashService'),
  JwtService:          Symbol.for('JwtService'),
  NotificationService: Symbol.for('NotificationService'),
  WeatherService:      Symbol.for('WeatherService'),
  ReminderService:     Symbol.for('ReminderService'),
  SocketService:       Symbol.for('SocketService'),
  LockService:         Symbol.for('LockService'),

  // ─── Datasources externos ───────────────────────────────────────────────────

  CloudinaryDataSource: Symbol.for('CloudinaryDataSource'),
  WeatherDataSource:    Symbol.for('WeatherDataSource'),
  FirebaseDataSource:   Symbol.for('FirebaseDataSource'),

  // ─── IMappers ───────────────────────────────────────────────────────────────

  IUserMapper:            Symbol.for('IUserMapper'),
  IPlantMapper:           Symbol.for('IPlantMapper'),
  IPlantSpeciesMapper:    Symbol.for('IPlantSpeciesMapper'),
  IReminderMapper:        Symbol.for('IReminderMapper'),
  IReminderHistoryMapper: Symbol.for('IReminderHistoryMapper'),
  IPostMapper:            Symbol.for('IPostMapper'),
  ICommentMapper:         Symbol.for('ICommentMapper'),
  IConversationMapper:    Symbol.for('IConversationMapper'),
  IMessageMapper:         Symbol.for('IMessageMapper'),
  IWeatherCacheMapper:    Symbol.for('IWeatherCacheMapper'),
  INotificationMapper:    Symbol.for('INotificationMapper'),

  // ─── Use Cases — Auth ────────────────────────────────────────────────────────

  IRegisterUserUseCase:  Symbol.for('IRegisterUserUseCase'),
  ILoginUserUseCase:     Symbol.for('ILoginUserUseCase'),
  IValidateTokenUseCase: Symbol.for('IValidateTokenUseCase'),
  IRefreshTokenUseCase:  Symbol.for('IRefreshTokenUseCase'),

  // ─── Use Cases — Plants ──────────────────────────────────────────────────────

  IGetUserPlantsUseCase:    Symbol.for('IGetUserPlantsUseCase'),
  IGetPlantByIdUseCase:     Symbol.for('IGetPlantByIdUseCase'),
  ICreatePlantUseCase:      Symbol.for('ICreatePlantUseCase'),
  IUpdatePlantUseCase:      Symbol.for('IUpdatePlantUseCase'),
  IDeletePlantUseCase:      Symbol.for('IDeletePlantUseCase'),
  IGetPlantSpeciesUseCase:  Symbol.for('IGetPlantSpeciesUseCase'),
  ISearchSpeciesUseCase:    Symbol.for('ISearchSpeciesUseCase'),

  // ─── Use Cases — Reminders ───────────────────────────────────────────────────

  IGetUserRemindersUseCase:         Symbol.for('IGetUserRemindersUseCase'),
  IProcessPendingRemindersUseCase:  Symbol.for('IProcessPendingRemindersUseCase'),
  IMarkReminderCompletedUseCase:    Symbol.for('IMarkReminderCompletedUseCase'),

  // ─── Use Cases — Notifications ───────────────────────────────────────────────

  IGetUserNotificationsUseCase:     Symbol.for('IGetUserNotificationsUseCase'),
  IMarkNotificationsReadUseCase:    Symbol.for('IMarkNotificationsReadUseCase'),
  IDeleteNotificationsUseCase:      Symbol.for('IDeleteNotificationsUseCase'),

  // ─── Use Cases — Community ───────────────────────────────────────────────────

  IGetFeedUseCase:        Symbol.for('IGetFeedUseCase'),
  IGetPostByIdUseCase:    Symbol.for('IGetPostByIdUseCase'),
  ICreatePostUseCase:     Symbol.for('ICreatePostUseCase'),
  ILikePostUseCase:       Symbol.for('ILikePostUseCase'),
  IUnlikePostUseCase:     Symbol.for('IUnlikePostUseCase'),
  IGetPostCommentsUseCase: Symbol.for('IGetPostCommentsUseCase'),
  IAddCommentUseCase:     Symbol.for('IAddCommentUseCase'),
  IDeletePostUseCase:     Symbol.for('IDeletePostUseCase'),
  IDeleteCommentUseCase:  Symbol.for('IDeleteCommentUseCase'),

  // ─── Use Cases — Chat ────────────────────────────────────────────────────────

  IGetConversationsUseCase:  Symbol.for('IGetConversationsUseCase'),
  IGetMessagesUseCase:       Symbol.for('IGetMessagesUseCase'),
  ISendMessageUseCase:       Symbol.for('ISendMessageUseCase'),
  IMarkMessagesReadUseCase:  Symbol.for('IMarkMessagesReadUseCase'),
  IGetOrCreateConversationUseCase: Symbol.for('IGetOrCreateConversationUseCase'),

  // ─── Use Cases — User ────────────────────────────────────────────────────────

  IGetUserProfileUseCase:       Symbol.for('IGetUserProfileUseCase'),
  IUpdateUserProfileUseCase:    Symbol.for('IUpdateUserProfileUseCase'),
  IUpdateUserPreferencesUseCase: Symbol.for('IUpdateUserPreferencesUseCase'),
  IChangePasswordUseCase:       Symbol.for('IChangePasswordUseCase'),
  IDeleteAccountUseCase:        Symbol.for('IDeleteAccountUseCase'),
  IExportUserDataUseCase:       Symbol.for('IExportUserDataUseCase'),

  // ─── Use Cases — Weather ─────────────────────────────────────────────────────

  IGetCurrentWeatherUseCase:  Symbol.for('IGetCurrentWeatherUseCase'),
  IGetWeatherForecastUseCase: Symbol.for('IGetWeatherForecastUseCase'),

  // ─── Controllers ─────────────────────────────────────────────────────────────

  AuthController:     Symbol.for('AuthController'),
  PlantController:    Symbol.for('PlantController'),
  SpeciesController:  Symbol.for('SpeciesController'),
  ReminderController: Symbol.for('ReminderController'),
  PostController:     Symbol.for('PostController'),
  ChatController:     Symbol.for('ChatController'),
  WeatherController:  Symbol.for('WeatherController'),
  UserController:     Symbol.for('UserController'),
  UploadController:   Symbol.for('UploadController'),
  AdminController:        Symbol.for('AdminController'),
  LocationController:     Symbol.for('LocationController'),
  NotificationController: Symbol.for('NotificationController'),
  ReportController:       Symbol.for('ReportController'),

} as const;
