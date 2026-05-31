/// @file notifications_viewmodel.dart
/// @description ViewModel de la pantalla de notificaciones in-app.
/// Gestiona la carga, marcado como leídas y eliminación de notificaciones.
/// Expone [unreadCount] para el badge del BottomNav.
/// Depende SOLO de interfaces de use cases.
/// @module Reminders
/// @layer Presentation
library;

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../domain/entities/notification.dart';
import '../../../domain/interfaces/usecases/notifications/i_delete_notifications_use_case.dart';
import '../../../domain/interfaces/usecases/notifications/i_get_user_notifications_use_case.dart';
import '../../../domain/interfaces/usecases/notifications/i_mark_notifications_read_use_case.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// NOTIFICATIONS VIEWMODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// ViewModel de la pantalla de notificaciones in-app del usuario.
///
/// Estado gestionado:
///  - [notifications]  — lista completa de notificaciones cargadas.
///  - [isLoading]      — true durante la carga inicial.
///  - [isProcessing]   — true mientras se ejecuta una acción de servidor.
///  - [error]          — último error ocurrido (null si no hay).
///  - [unreadCount]    — número de notificaciones no leídas (para badge).
///
/// Registrar en container.dart como singleton para que MainTabsPage pueda
/// leer [unreadCount] sin necesitar un Provider adicional.
class NotificationsViewModel extends ChangeNotifier {
  final IGetUserNotificationsUseCase  _getNotifications;
  final IMarkNotificationsReadUseCase _markRead;
  final IDeleteNotificationsUseCase   _delete;

  NotificationsViewModel({
    required IGetUserNotificationsUseCase  getNotificationsUseCase,
    required IMarkNotificationsReadUseCase markNotificationsReadUseCase,
    required IDeleteNotificationsUseCase   deleteNotificationsUseCase,
  })  : _getNotifications = getNotificationsUseCase,
        _markRead         = markNotificationsReadUseCase,
        _delete           = deleteNotificationsUseCase;

  // ─── Estado ───────────────────────────────────────────────────────────────────

  List<AppNotification>  _notifications = [];
  bool                   _isLoading     = false;
  bool                   _isProcessing  = false;
  AppError?              _error;

  List<AppNotification>  get notifications => _notifications;
  bool                   get isLoading     => _isLoading;
  bool                   get isProcessing  => _isProcessing;
  AppError?              get error         => _error;

  /// Número de notificaciones no leídas — usado para el badge del BottomNav.
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // ─── Cargar notificaciones ────────────────────────────────────────────────────

  /// Carga las notificaciones del usuario autenticado desde el backend.
  Future<void> load() async {
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      _notifications = await _getNotifications.execute();
    } on AppError catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Marcar todo como leído ───────────────────────────────────────────────────

  /// Marca todas las notificaciones como leídas en el servidor y actualiza la lista local.
  Future<void> markAllAsRead() async {
    if (_notifications.every((n) => n.isRead)) return;

    _isProcessing = true;
    notifyListeners();

    try {
      await _markRead.execute();
      // Actualizar estado local: todos marcados como leídos.
      _notifications = _notifications
          .map((n) => AppNotification(
                id:         n.id,
                userId:     n.userId,
                type:       n.type,
                message:    n.message,
                reminderId: n.reminderId,
                plantId:    n.plantId,
                isRead:     true,
                createdAt:  n.createdAt,
              ))
          .toList();
    } on AppError catch (e) {
      _error = e;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ─── Eliminar todas ───────────────────────────────────────────────────────────

  /// Elimina todas las notificaciones del usuario en el servidor y vacía la lista local.
  Future<void> deleteAll() async {
    if (_notifications.isEmpty) return;

    _isProcessing = true;
    notifyListeners();

    try {
      await _delete.execute();
      _notifications = [];
    } on AppError catch (e) {
      _error = e;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ─── Operaciones sobre selección ──────────────────────────────────────────────

  /// Marca como leídas las notificaciones cuyos IDs están en [ids].
  /// Envía solo los IDs seleccionados al backend.
  Future<void> markSelectedAsRead(Set<String> ids) async {
    if (ids.isEmpty) return;

    // Actualización optimista local.
    _notifications = _notifications.map((n) {
      if (!ids.contains(n.id) || n.isRead) return n;
      return AppNotification(
        id:         n.id,
        userId:     n.userId,
        type:       n.type,
        message:    n.message,
        reminderId: n.reminderId,
        plantId:    n.plantId,
        isRead:     true,
        createdAt:  n.createdAt,
      );
    }).toList();
    notifyListeners();

    // Persistir en backend solo los IDs seleccionados.
    try {
      await _markRead.execute(ids: ids.toList());
    } on AppError catch (e) {
      _error = e;
      notifyListeners();
    }
  }

  /// Elimina las notificaciones cuyos IDs están en [ids].
  /// Envía solo los IDs seleccionados al backend.
  Future<void> deleteSelected(Set<String> ids) async {
    if (ids.isEmpty) return;

    // Actualización optimista local.
    _notifications = _notifications.where((n) => !ids.contains(n.id)).toList();
    notifyListeners();

    // Persistir en backend solo los IDs seleccionados.
    try {
      await _delete.execute(ids: ids.toList());
    } on AppError catch (e) {
      _error = e;
      notifyListeners();
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
