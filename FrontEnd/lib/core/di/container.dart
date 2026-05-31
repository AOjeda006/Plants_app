/// @file container.dart
/// @description Configuración del contenedor de inyección de dependencias con get_it.
/// Registra todos los singletons y factories de la app: infraestructura core,
/// datasources, repositorios, use cases e interfaces.
/// Los módulos de dominio (community, chat…) añadirán sus registros
/// en fases posteriores siguiendo el mismo patrón.
/// @module Core
/// @layer Core
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../app.dart' show appNavigatorKey;
import '../services/firebase_messaging_service.dart';
import '../../data/datasources/remote/auth_remote_data_source.dart';
import '../../data/datasources/remote/plant_remote_data_source.dart';
import '../../data/datasources/remote/reminder_remote_data_source.dart';
import '../../data/datasources/remote/weather_remote_data_source.dart';
import '../../data/datasources/remote/chat_remote_data_source.dart';
import '../../data/datasources/remote/post_remote_data_source.dart';
import '../../data/i_mappers/i_comment_mapper.dart';
import '../../data/i_mappers/i_conversation_mapper.dart';
import '../../data/i_mappers/i_message_mapper.dart';
import '../../data/i_mappers/i_plant_mapper.dart';
import '../../data/i_mappers/i_plant_species_mapper.dart';
import '../../data/i_mappers/i_post_mapper.dart';
import '../../data/i_mappers/i_reminder_mapper.dart';
import '../../data/i_mappers/i_user_mapper.dart';
import '../../data/i_mappers/i_weather_mapper.dart';
import '../../data/mappers/comment_mapper.dart';
import '../../data/mappers/conversation_mapper.dart';
import '../../data/mappers/message_mapper.dart';
import '../../data/mappers/plant_mapper.dart';
import '../../data/mappers/plant_species_mapper.dart';
import '../../data/mappers/post_mapper.dart';
import '../../data/mappers/reminder_mapper.dart';
import '../../data/mappers/user_mapper.dart';
import '../../data/mappers/weather_mapper.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/repositories/post_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/plant_repository_impl.dart';
import '../../data/repositories/reminder_repository_impl.dart';
import '../../data/repositories/weather_repository_impl.dart';
import '../../domain/interfaces/usecases/chat/i_create_conversation_use_case.dart';
import '../../domain/interfaces/usecases/chat/i_get_conversations_use_case.dart';
import '../../domain/interfaces/usecases/chat/i_get_messages_use_case.dart';
import '../../domain/interfaces/usecases/chat/i_mark_messages_as_read_use_case.dart';
import '../../domain/interfaces/usecases/chat/i_send_message_use_case.dart';
import '../../domain/interfaces/usecases/community/i_create_comment_use_case.dart';
import '../../domain/interfaces/usecases/community/i_create_post_use_case.dart';
import '../../domain/interfaces/usecases/community/i_get_feed_use_case.dart';
import '../../domain/interfaces/usecases/community/i_get_post_by_id_use_case.dart';
import '../../domain/interfaces/usecases/community/i_get_post_comments_use_case.dart';
import '../../domain/interfaces/usecases/community/i_like_post_use_case.dart';
import '../../domain/interfaces/usecases/community/i_unlike_post_use_case.dart';
import '../../domain/interfaces/usecases/auth/i_login_use_case.dart';
import '../../domain/interfaces/usecases/auth/i_logout_use_case.dart';
import '../../domain/interfaces/usecases/auth/i_refresh_token_use_case.dart';
import '../../domain/interfaces/usecases/auth/i_register_use_case.dart';
import '../../domain/interfaces/usecases/auth/i_validate_token_use_case.dart';
import '../../domain/interfaces/usecases/plants/i_create_plant_use_case.dart';
import '../../domain/interfaces/usecases/plants/i_delete_plant_use_case.dart';
import '../../domain/interfaces/usecases/plants/i_get_plant_by_id_use_case.dart';
import '../../domain/interfaces/usecases/plants/i_get_user_plants_use_case.dart';
import '../../domain/interfaces/usecases/plants/i_search_species_use_case.dart';
import '../../domain/interfaces/usecases/plants/i_update_plant_use_case.dart';
import '../../data/datasources/remote/notification_remote_data_source.dart';
import '../../data/i_mappers/i_notification_mapper.dart';
import '../../data/mappers/notification_mapper.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/interfaces/usecases/notifications/i_delete_notifications_use_case.dart';
import '../../domain/interfaces/usecases/notifications/i_get_user_notifications_use_case.dart';
import '../../domain/interfaces/usecases/notifications/i_mark_notifications_read_use_case.dart';
import '../../domain/interfaces/usecases/reminders/i_get_user_reminders_use_case.dart';
import '../../domain/interfaces/usecases/reminders/i_mark_reminder_completed_use_case.dart';
import '../../domain/repositories/i_notification_repository.dart';
import '../../domain/usecases/notifications/delete_notifications_use_case.dart';
import '../../domain/usecases/notifications/get_user_notifications_use_case.dart';
import '../../domain/usecases/notifications/mark_notifications_read_use_case.dart';
import '../../domain/interfaces/usecases/weather/i_get_current_weather_use_case.dart';
import '../../domain/interfaces/usecases/weather/i_get_weather_forecast_use_case.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/repositories/i_chat_repository.dart';
import '../../domain/repositories/i_plant_repository.dart';
import '../../domain/repositories/i_post_repository.dart';
import '../../domain/repositories/i_reminder_repository.dart';
import '../../domain/repositories/i_weather_repository.dart';
import '../../domain/usecases/chat/create_conversation_use_case.dart';
import '../../domain/usecases/chat/get_conversation_messages_use_case.dart';
import '../../domain/usecases/chat/get_user_conversations_use_case.dart';
import '../../domain/usecases/chat/mark_messages_as_read_use_case.dart';
import '../../domain/usecases/chat/send_message_use_case.dart';
import '../../domain/usecases/community/create_comment_use_case.dart';
import '../../domain/usecases/community/create_post_use_case.dart';
import '../../domain/usecases/community/get_feed_use_case.dart';
import '../../domain/usecases/community/get_post_by_id_use_case.dart';
import '../../domain/usecases/community/get_post_comments_use_case.dart';
import '../../domain/usecases/community/like_post_use_case.dart';
import '../../domain/usecases/community/unlike_post_use_case.dart';
import '../../domain/usecases/auth/login_use_case.dart';
import '../../domain/usecases/auth/logout_use_case.dart';
import '../../domain/usecases/auth/refresh_token_use_case.dart';
import '../../domain/usecases/auth/register_use_case.dart';
import '../../domain/usecases/auth/validate_token_use_case.dart';
import '../../domain/usecases/plants/create_plant_use_case.dart';
import '../../domain/usecases/plants/delete_plant_use_case.dart';
import '../../domain/usecases/plants/get_plant_by_id_use_case.dart';
import '../../domain/usecases/plants/get_user_plants_use_case.dart';
import '../../domain/usecases/plants/search_species_use_case.dart';
import '../../domain/usecases/plants/update_plant_use_case.dart';
import '../../domain/usecases/reminders/get_user_reminders_use_case.dart';
import '../../domain/usecases/reminders/mark_reminder_completed_use_case.dart';
import '../../domain/usecases/weather/get_current_weather_use_case.dart';
import '../../domain/usecases/weather/get_weather_forecast_use_case.dart';
import '../../data/datasources/remote/user_remote_data_source.dart';
import '../../data/datasources/remote/location_remote_data_source.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/interfaces/usecases/user/i_change_password_use_case.dart';
import '../../domain/interfaces/usecases/user/i_delete_user_account_use_case.dart';
import '../../domain/interfaces/usecases/user/i_export_user_data_use_case.dart';
import '../../domain/interfaces/usecases/user/i_get_my_profile_use_case.dart';
import '../../domain/interfaces/usecases/user/i_get_user_by_id_use_case.dart';
import '../../domain/interfaces/usecases/user/i_update_user_preferences_use_case.dart';
import '../../domain/interfaces/usecases/user/i_update_user_profile_use_case.dart';
import '../../domain/repositories/i_settings_repository.dart';
import '../../domain/repositories/i_user_repository.dart';
import '../../domain/usecases/user/change_password_use_case.dart';
import '../../domain/usecases/user/delete_user_account_use_case.dart';
import '../../domain/usecases/user/export_user_data_use_case.dart';
import '../../domain/usecases/user/get_my_profile_use_case.dart';
import '../../domain/usecases/user/get_user_by_id_use_case.dart';
import '../../domain/usecases/user/update_user_preferences_use_case.dart';
import '../../domain/usecases/user/update_user_profile_use_case.dart';
import '../../presentation/viewmodels/auth/auth_viewmodel.dart';
import '../../presentation/viewmodels/chat/chat_viewmodel.dart';
import '../../presentation/viewmodels/chat/conversations_viewmodel.dart';
import '../../presentation/viewmodels/community/feed_viewmodel.dart';
import '../../presentation/viewmodels/community/post_viewmodel.dart';
import '../../presentation/viewmodels/community/user_profile_viewmodel.dart';
import '../../presentation/viewmodels/plants/calendar_viewmodel.dart';
import '../../presentation/viewmodels/plants/plant_detail_viewmodel.dart';
import '../../presentation/viewmodels/plants/plant_form_viewmodel.dart';
import '../../presentation/viewmodels/plants/plants_list_viewmodel.dart';
import '../../presentation/viewmodels/plants/species_info_viewmodel.dart';
import '../../data/datasources/remote/admin_remote_data_source.dart';
import '../../presentation/viewmodels/admin/admin_viewmodel.dart';
import '../../presentation/viewmodels/profile/account_management_viewmodel.dart';
import '../../presentation/viewmodels/profile/edit_profile_viewmodel.dart';
import '../../presentation/viewmodels/profile/my_profile_viewmodel.dart';
import '../../presentation/viewmodels/profile/settings_viewmodel.dart';
import '../../presentation/viewmodels/reminders/notifications_viewmodel.dart';
import '../network/api_client.dart';
import '../network/socket_client.dart';
import '../storage/auth_local_data_source.dart';
import '../storage/cache_local_data_source.dart';
import '../utils/connectivity/connectivity_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// INSTANCIA GLOBAL
// ═══════════════════════════════════════════════════════════════════════════════

/// Instancia global de GetIt. Usar `sl<T>()` para resolver dependencias.
final GetIt sl = GetIt.instance;

// ═══════════════════════════════════════════════════════════════════════════════
// CONFIGURACIÓN
// ═══════════════════════════════════════════════════════════════════════════════

/// Registra todas las dependencias de la app en el contenedor GetIt.
///
/// Llamar una sola vez desde main.dart ANTES de runApp().
/// El orden importa: registrar primero lo que otros dependen.
Future<void> configureDependencies() async {
  // ─── 1. Infraestructura de almacenamiento (Core Storage) ──────────────────

  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );

  // FirebaseMessagingService como singleton para que MainTabsPage.initState
  // lo recupere via sl<...>(). main.dart usa la misma instancia para
  // inicializar (en lugar de construirla manualmente).
  sl.registerLazySingleton<FirebaseMessagingService>(
    () => FirebaseMessagingService(appNavigatorKey),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSource(storage: sl()),
  );

  sl.registerLazySingleton<CacheLocalDataSource>(
    CacheLocalDataSource.new,
  );

  // ─── 2. Conectividad ──────────────────────────────────────────────────────

  sl.registerLazySingleton<Connectivity>(Connectivity.new);

  sl.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(connectivity: sl()),
  );

  // ─── 3. Red (ApiClient depende de AuthLocalDataSource para tokenProvider) ─

  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(
      tokenProvider: () => sl<AuthLocalDataSource>().getAccessToken(),
    ),
  );

  sl.registerLazySingleton<SocketClient>(
    () => SocketClient(
      tokenProvider: () => sl<AuthLocalDataSource>().getAccessToken(),
    ),
  );

  // ─── 4. Auth: mapper, datasource, repositorio, use cases, viewmodel ──────
  //   (no hay bloque "Cola offline" — los errores de red propagan al
  //    ViewModel/UI.)

  sl.registerLazySingleton<IUserMapper>(UserMapper.new);

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(apiClient: sl()),
  );

  sl.registerLazySingleton<IAuthRepository>(
    () => AuthRepositoryImpl(
      remote: sl(),
      local:  sl(),
      mapper: sl(),
    ),
  );

  sl.registerLazySingleton<IRegisterUseCase>(
    () => RegisterUseCase(repository: sl()),
  );
  sl.registerLazySingleton<ILoginUseCase>(
    () => LoginUseCase(repository: sl()),
  );
  sl.registerLazySingleton<IValidateTokenUseCase>(
    () => ValidateTokenUseCase(repository: sl()),
  );
  // Logout profundo: orquesta DELETE fcm-token remoto, socket.disconnect,
  // cache.clearAll y secure_storage clear. No invoca
  // `firebase.deleteToken()` local porque causaba `getToken()==null` en
  // el siguiente login. IUserRepository se registra más abajo pero
  // registerLazySingleton aplaza el sl() lookup al primer get().
  sl.registerLazySingleton<ILogoutUseCase>(
    () => LogoutUseCase(
      authRepository: sl(),
      userRepository: sl(),
      socketClient:   sl(),
      cache:          sl(),
    ),
  );
  // Auto-refresh del token JWT al arrancar la app si quedan menos de 7
  // días para expirar.
  sl.registerLazySingleton<IRefreshTokenUseCase>(
    () => RefreshTokenUseCase(repository: sl(), local: sl()),
  );

  // Factory: cada Provider crea su propia instancia de AuthViewModel.
  sl.registerFactory<AuthViewModel>(
    () => AuthViewModel(
      loginUseCase:          sl(),
      registerUseCase:       sl(),
      validateTokenUseCase:  sl(),
      logoutUseCase:         sl(),
      refreshTokenUseCase:   sl(),
    ),
  );

  // ─── 6. Plants: mappers, datasource, repositorio, use cases, viewmodels ──

  sl.registerLazySingleton<IPlantMapper>(PlantMapper.new);
  sl.registerLazySingleton<IPlantSpeciesMapper>(PlantSpeciesMapper.new);

  sl.registerLazySingleton<PlantRemoteDataSource>(
    () => PlantRemoteDataSource(apiClient: sl()),
  );

  sl.registerLazySingleton<IPlantRepository>(
    () => PlantRepositoryImpl(
      remote:        sl(),
      cache:         sl(),
      plantMapper:   sl(),
      speciesMapper: sl(),
    ),
  );

  sl.registerLazySingleton<IGetUserPlantsUseCase>(
    () => GetUserPlantsUseCase(repository: sl()),
  );
  sl.registerLazySingleton<IGetPlantByIdUseCase>(
    () => GetPlantByIdUseCase(repository: sl()),
  );
  sl.registerLazySingleton<ICreatePlantUseCase>(
    () => CreatePlantUseCase(repository: sl()),
  );
  sl.registerLazySingleton<IUpdatePlantUseCase>(
    () => UpdatePlantUseCase(repository: sl()),
  );
  sl.registerLazySingleton<IDeletePlantUseCase>(
    () => DeletePlantUseCase(repository: sl()),
  );
  sl.registerLazySingleton<ISearchSpeciesUseCase>(
    () => SearchSpeciesUseCase(repository: sl()),
  );

  // ─── 6b. Weather: mapper, datasource, repositorio, use cases ─────────────
  //   Registrado antes de los viewmodels de plantas porque PlantDetailViewModel
  //   depende de IGetCurrentWeatherUseCase.

  sl.registerLazySingleton<IWeatherMapper>(WeatherMapper.new);

  sl.registerLazySingleton<WeatherRemoteDataSource>(
    () => WeatherRemoteDataSource(apiClient: sl()),
  );

  sl.registerLazySingleton<IWeatherRepository>(
    () => WeatherRepositoryImpl(
      remote: sl(),
      cache:  sl(),
      mapper: sl(),
    ),
  );

  sl.registerLazySingleton<IGetCurrentWeatherUseCase>(
    () => GetCurrentWeatherUseCase(repository: sl()),
  );
  sl.registerLazySingleton<IGetWeatherForecastUseCase>(
    () => GetWeatherForecastUseCase(repository: sl()),
  );

  // Singleton: MainTabsPage.initState() invoca loadPlants() al montar tras cada login.
  // Se usa .value en el Provider para no disponer el singleton al desmontar la página.
  sl.registerLazySingleton<PlantsListViewModel>(
    () => PlantsListViewModel(
      getUserPlantsUseCase: sl(),
      deletePlantUseCase:   sl(),
      searchSpeciesUseCase: sl(),
    ),
  );
  sl.registerFactory<CalendarViewModel>(
    () => CalendarViewModel(
      getUserPlantsUseCase: sl(),
      searchSpeciesUseCase: sl(),
    ),
  );
  sl.registerFactory<PlantDetailViewModel>(
    () => PlantDetailViewModel(
      getPlantByIdUseCase:  sl(),
      deletePlantUseCase:   sl(),
      updatePlantUseCase:   sl(),
      searchSpeciesUseCase: sl(),
      getWeatherUseCase:    sl(),
    ),
  );
  sl.registerFactory<PlantFormViewModel>(
    () => PlantFormViewModel(
      createPlantUseCase:   sl(),
      updatePlantUseCase:   sl(),
      searchSpeciesUseCase: sl(),
    ),
  );
  sl.registerFactory<SpeciesInfoViewModel>(
    () => SpeciesInfoViewModel(searchSpeciesUseCase: sl()),
  );

  // ─── 7. Reminders: mapper, datasource, repositorio, use cases ────────────

  sl.registerLazySingleton<IReminderMapper>(ReminderMapper.new);

  sl.registerLazySingleton<ReminderRemoteDataSource>(
    () => ReminderRemoteDataSource(apiClient: sl()),
  );

  sl.registerLazySingleton<IReminderRepository>(
    () => ReminderRepositoryImpl(
      remote: sl(),
      cache:  sl(),
      mapper: sl(),
    ),
  );

  sl.registerLazySingleton<IGetUserRemindersUseCase>(
    () => GetUserRemindersUseCase(repository: sl()),
  );
  sl.registerLazySingleton<IMarkReminderCompletedUseCase>(
    () => MarkReminderCompletedUseCase(repository: sl()),
  );

  // ─── 7b. Notifications: mapper, datasource, repositorio, use cases, viewmodel

  sl.registerLazySingleton<INotificationMapper>(NotificationMapper.new);

  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSource(apiClient: sl()),
  );

  sl.registerLazySingleton<INotificationRepository>(
    () => NotificationRepositoryImpl(remote: sl(), mapper: sl()),
  );

  sl.registerLazySingleton<IGetUserNotificationsUseCase>(
    () => GetUserNotificationsUseCase(repository: sl()),
  );
  sl.registerLazySingleton<IMarkNotificationsReadUseCase>(
    () => MarkNotificationsReadUseCase(repository: sl()),
  );
  sl.registerLazySingleton<IDeleteNotificationsUseCase>(
    () => DeleteNotificationsUseCase(repository: sl()),
  );

  // ─── 8. Community: mappers, datasource, repositorio, use cases, viewmodels ─

  sl.registerLazySingleton<IPostMapper>(PostMapper.new);
  sl.registerLazySingleton<ICommentMapper>(CommentMapper.new);

  sl.registerLazySingleton<PostRemoteDataSource>(
    () => PostRemoteDataSource(apiClient: sl()),
  );

  sl.registerLazySingleton<IPostRepository>(
    () => PostRepositoryImpl(
      remote:        sl(),
      cache:         sl(),
      postMapper:    sl(),
      commentMapper: sl(),
    ),
  );

  sl.registerLazySingleton<IGetFeedUseCase>(
    () => GetFeedUseCase(repository: sl()),
  );
  sl.registerLazySingleton<IGetPostByIdUseCase>(
    () => GetPostByIdUseCase(repository: sl()),
  );
  sl.registerLazySingleton<ICreatePostUseCase>(
    () => CreatePostUseCase(repository: sl()),
  );
  sl.registerLazySingleton<ILikePostUseCase>(
    () => LikePostUseCase(repository: sl()),
  );
  sl.registerLazySingleton<IUnlikePostUseCase>(
    () => UnlikePostUseCase(repository: sl()),
  );
  sl.registerLazySingleton<IGetPostCommentsUseCase>(
    () => GetPostCommentsUseCase(repository: sl()),
  );
  sl.registerLazySingleton<ICreateCommentUseCase>(
    () => CreateCommentUseCase(repository: sl()),
  );

  // Singleton: MainTabsPage.initState() invoca loadFeed() al montar tras cada login.
  // Se usa .value en el Provider para no disponer el singleton al desmontar la página.
  sl.registerLazySingleton<FeedViewModel>(
    () => FeedViewModel(
      getFeedUseCase:    sl(),
      likePostUseCase:   sl(),
      unlikePostUseCase: sl(),
      createPostUseCase: sl(),
    ),
  );
  sl.registerFactory<PostViewModel>(
    () => PostViewModel(
      getPostByIdUseCase:     sl(),
      getPostCommentsUseCase: sl(),
      createCommentUseCase:   sl(),
      likePostUseCase:        sl(),
      unlikePostUseCase:      sl(),
    ),
  );
  sl.registerFactory<UserProfileViewModel>(
    () => UserProfileViewModel(
      getFeedUseCase:      sl(),
      getUserByIdUseCase:  sl(),
    ),
  );

  // ─── 9. Chat: mappers, datasource, repositorio, use cases, viewmodels ───────

  sl.registerLazySingleton<IConversationMapper>(ConversationMapper.new);
  sl.registerLazySingleton<IMessageMapper>(MessageMapper.new);

  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSource(apiClient: sl()),
  );

  sl.registerLazySingleton<IChatRepository>(
    () => ChatRepositoryImpl(
      remote:             sl(),
      cache:              sl(),
      conversationMapper: sl(),
      messageMapper:      sl(),
    ),
  );

  sl.registerLazySingleton<IGetConversationsUseCase>(
    () => GetUserConversationsUseCase(repository: sl()),
  );
  sl.registerLazySingleton<IGetMessagesUseCase>(
    () => GetConversationMessagesUseCase(repository: sl()),
  );
  sl.registerLazySingleton<ISendMessageUseCase>(
    () => SendMessageUseCase(repository: sl()),
  );
  sl.registerLazySingleton<IMarkMessagesAsReadUseCase>(
    () => MarkMessagesAsReadUseCase(repository: sl()),
  );
  sl.registerLazySingleton<ICreateConversationUseCase>(
    () => CreateConversationUseCase(repository: sl()),
  );

  // ConversationsViewModel se registra como singleton para que el
  // listener `message:received` que MainTabsPage instala pueda invocar
  // `refresh()` aunque la pestaña Mensajes no esté montada. Si fuese
  // factory, el VM se recrearía en cada visita y el listener perdería
  // la referencia tras el primer ciclo.
  sl.registerLazySingleton<ConversationsViewModel>(
    () => ConversationsViewModel(getConversationsUseCase: sl()),
  );
  sl.registerFactory<ChatViewModel>(
    () => ChatViewModel(
      getMessagesUseCase:        sl(),
      sendMessageUseCase:        sl(),
      markMessagesAsReadUseCase: sl(),
      socketClient:              sl(),
    ),
  );

  // ─── 10. User: datasource, repositorios, use cases, viewmodels ───────────

  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSource(apiClient: sl()),
  );
  sl.registerLazySingleton<LocationRemoteDataSource>(
    () => LocationRemoteDataSource(apiClient: sl()),
  );

  sl.registerLazySingleton<IUserRepository>(
    () => UserRepositoryImpl(dataSource: sl(), mapper: sl()),
  );

  sl.registerLazySingleton<ISettingsRepository>(
    () => SettingsRepositoryImpl(dataSource: sl(), mapper: sl()),
  );

  sl.registerLazySingleton<IGetMyProfileUseCase>(
    () => GetMyProfileUseCase(repository: sl()),
  );
  sl.registerLazySingleton<IGetUserByIdUseCase>(
    () => GetUserByIdUseCase(repository: sl()),
  );
  sl.registerLazySingleton<IUpdateUserProfileUseCase>(
    () => UpdateUserProfileUseCase(repository: sl()),
  );
  sl.registerLazySingleton<IUpdateUserPreferencesUseCase>(
    () => UpdateUserPreferencesUseCase(repository: sl()),
  );
  sl.registerLazySingleton<IChangePasswordUseCase>(
    () => ChangePasswordUseCase(repository: sl()),
  );
  sl.registerLazySingleton<IDeleteUserAccountUseCase>(
    () => DeleteUserAccountUseCase(repository: sl()),
  );
  sl.registerLazySingleton<IExportUserDataUseCase>(
    () => ExportUserDataUseCase(repository: sl()),
  );

  sl.registerFactory<MyProfileViewModel>(
    () => MyProfileViewModel(
      getMyProfileUseCase: sl(),
      getFeedUseCase:      sl(),
    ),
  );
  // Singleton: MainTabsPage escucha unreadCount para el badge del BottomNav.
  sl.registerLazySingleton<NotificationsViewModel>(
    () => NotificationsViewModel(
      getNotificationsUseCase:      sl(),
      markNotificationsReadUseCase: sl(),
      deleteNotificationsUseCase:   sl(),
    ),
  );
  sl.registerFactory<EditProfileViewModel>(
    () => EditProfileViewModel(
      updateUserProfileUseCase: sl(),
      locationDataSource:       sl(),
    ),
  );
  sl.registerFactory<SettingsViewModel>(
    () => SettingsViewModel(
      getMyProfileUseCase:          sl(),
      updateUserPreferencesUseCase: sl(),
    ),
  );
  sl.registerFactory<AccountManagementViewModel>(
    () => AccountManagementViewModel(
      changePasswordUseCase:    sl(),
      deleteUserAccountUseCase: sl(),
      exportUserDataUseCase:    sl(),
      logoutUseCase:            sl(),
    ),
  );

  // ─── 11. Admin: datasource, viewmodel ─────────────────────────────────────

  sl.registerLazySingleton<AdminRemoteDataSource>(
    () => AdminRemoteDataSource(apiClient: sl()),
  );

  // Factory: cada pantalla admin crea su propia instancia de AdminViewModel.
  sl.registerFactory<AdminViewModel>(
    () => AdminViewModel(
      dataSource:   sl(),
      socketClient: sl(),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// INICIALIZACIÓN DE SERVICIOS
// ═══════════════════════════════════════════════════════════════════════════════

/// Inicializa los servicios que requieren arranque async tras configurar el DI.
///
/// Llamar desde main.dart después de configureDependencies() y antes de runApp().
Future<void> initializeServices() async {
  // Inicializar almacenamiento Hive (caja `cache` para datos con TTL).
  await sl<CacheLocalDataSource>().initialize();

  // Inicializar conectividad. No hay gestor de cola offline; el banner
  // se alimenta directamente de `ConnectivityService.onConnectivityChanged`.
  await sl<ConnectivityService>().initialize();
}

