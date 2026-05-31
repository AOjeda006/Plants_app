/// @file notification_repository_impl.dart
/// @description Implementación del repositorio de notificaciones in-app.
/// Coordina NotificationRemoteDataSource (API) sin capa de caché
/// (las notificaciones deben estar siempre actualizadas).
/// @module Reminders
/// @layer Data
library;

import '../../domain/entities/notification.dart';
import '../../domain/repositories/i_notification_repository.dart';
import '../datasources/remote/notification_remote_data_source.dart';
import '../i_mappers/i_notification_mapper.dart';
import '../models/notification_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION REPOSITORY IMPL
// ═══════════════════════════════════════════════════════════════════════════════

/// Implementación concreta de [INotificationRepository].
///
/// Sin caché: las notificaciones se leen siempre frescas del servidor para
/// garantizar que el badge de no leídas sea preciso.
///
/// [implements] INotificationRepository
/// [injectable] registrar en container.dart.
/// [dependencies] NotificationRemoteDataSource, INotificationMapper.
class NotificationRepositoryImpl implements INotificationRepository {
  final NotificationRemoteDataSource _remote;
  final INotificationMapper          _mapper;

  const NotificationRepositoryImpl({
    required NotificationRemoteDataSource remote,
    required INotificationMapper          mapper,
  })  : _remote = remote,
        _mapper = mapper;

  // ─── Get user notifications ────────────────────────────────────────────────

  @override
  Future<List<AppNotification>> getUserNotifications() async {
    final rawList = await _remote.getUserNotifications();
    return rawList
        .map((json) => _mapper.toEntity(NotificationModel.fromJson(json)))
        .toList();
  }

  // ─── Mark all read ─────────────────────────────────────────────────────────

  @override
  Future<void> markAllRead({List<String>? ids}) async {
    await _remote.markAllRead(ids: ids);
  }

  // ─── Delete all ────────────────────────────────────────────────────────────

  @override
  Future<void> deleteAll({List<String>? ids}) async {
    await _remote.deleteAll(ids: ids);
  }
}
