/// @file notifications_viewmodel_test.dart
/// @description Tests unitarios para NotificationsViewModel.
/// Verifica la carga de notificaciones, el badge unreadCount,
/// el marcado como leídas, la eliminación y la gestión de errores.
/// @module Reminders
/// @layer Presentation
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:plants_app/core/errors/app_error.dart';
import 'package:plants_app/domain/entities/notification.dart';
import 'package:plants_app/domain/interfaces/usecases/notifications/i_delete_notifications_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/notifications/i_get_user_notifications_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/notifications/i_mark_notifications_read_use_case.dart';
import 'package:plants_app/presentation/viewmodels/reminders/notifications_viewmodel.dart';

// ─── Mocks manuales ───────────────────────────────────────────────────────────

class _MockGetNotifications implements IGetUserNotificationsUseCase {
  List<AppNotification> returnValue = [];
  AppError?             throwError;

  @override
  Future<List<AppNotification>> execute() async {
    if (throwError != null) throw throwError!;
    return returnValue;
  }
}

class _MockMarkRead implements IMarkNotificationsReadUseCase {
  AppError?     throwError;
  int           callCount = 0;
  List<String>? lastIds;

  @override
  Future<void> execute({List<String>? ids}) async {
    callCount++;
    lastIds = ids;
    if (throwError != null) throw throwError!;
  }
}

class _MockDelete implements IDeleteNotificationsUseCase {
  AppError?     throwError;
  int           callCount = 0;
  List<String>? lastIds;

  @override
  Future<void> execute({List<String>? ids}) async {
    callCount++;
    lastIds = ids;
    if (throwError != null) throw throwError!;
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

final _now = DateTime.utc(2026, 3, 17);

AppNotification _makeNotif({
  String id      = 'notif-001',
  bool   isRead  = false,
  String type    = 'watering',
}) =>
    AppNotification(
      id:         id,
      userId:     'user-001',
      type:       type,
      message:    'Es hora de regar tu planta',
      reminderId: 'reminder-001',
      plantId:    'plant-001',
      isRead:     isRead,
      createdAt:  _now,
    );

NotificationsViewModel _makeViewModel({
  _MockGetNotifications? getNotifications,
  _MockMarkRead?         markRead,
  _MockDelete?           delete,
}) =>
    NotificationsViewModel(
      getNotificationsUseCase:      getNotifications ?? _MockGetNotifications(),
      markNotificationsReadUseCase: markRead         ?? _MockMarkRead(),
      deleteNotificationsUseCase:   delete           ?? _MockDelete(),
    );

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  // ── load() ────────────────────────────────────────────────────────────────────

  group('load()', () {
    test('debe cargar las notificaciones y limpiar el error', () async {
      final getNotifs = _MockGetNotifications()
        ..returnValue = [
          _makeNotif(id: 'n1'),
          _makeNotif(id: 'n2', isRead: true),
        ];
      final vm = _makeViewModel(getNotifications: getNotifs);

      await vm.load();

      expect(vm.notifications.length, 2);
      expect(vm.isLoading,            isFalse);
      expect(vm.error,                isNull);
    });

    test('debe devolver lista vacía si el backend no tiene notificaciones', () async {
      final getNotifs = _MockGetNotifications()..returnValue = [];
      final vm        = _makeViewModel(getNotifications: getNotifs);

      await vm.load();

      expect(vm.notifications, isEmpty);
    });

    test('debe establecer error si la carga falla', () async {
      final getNotifs = _MockGetNotifications()..throwError = AppError.network();
      final vm        = _makeViewModel(getNotifications: getNotifs);

      await vm.load();

      expect(vm.error,     isNotNull);
      expect(vm.isLoading, isFalse);
    });
  });

  // ── unreadCount / badge ───────────────────────────────────────────────────────

  group('unreadCount', () {
    test('debe contar solo las notificaciones no leídas', () async {
      final getNotifs = _MockGetNotifications()
        ..returnValue = [
          _makeNotif(id: 'n1', isRead: false),
          _makeNotif(id: 'n2', isRead: true),
          _makeNotif(id: 'n3', isRead: false),
        ];
      final vm = _makeViewModel(getNotifications: getNotifs);

      await vm.load();

      expect(vm.unreadCount, 2);
    });

    test('debe ser 0 si todas están leídas', () async {
      final getNotifs = _MockGetNotifications()
        ..returnValue = [
          _makeNotif(id: 'n1', isRead: true),
          _makeNotif(id: 'n2', isRead: true),
        ];
      final vm = _makeViewModel(getNotifications: getNotifs);

      await vm.load();

      expect(vm.unreadCount, 0);
    });

    test('debe ser 0 si no hay notificaciones', () async {
      final getNotifs = _MockGetNotifications()..returnValue = [];
      final vm        = _makeViewModel(getNotifications: getNotifs);

      await vm.load();

      expect(vm.unreadCount, 0);
    });
  });

  // ── markAllAsRead() ───────────────────────────────────────────────────────────

  group('markAllAsRead()', () {
    test('debe marcar todas las notificaciones como leídas localmente', () async {
      final getNotifs = _MockGetNotifications()
        ..returnValue = [
          _makeNotif(id: 'n1', isRead: false),
          _makeNotif(id: 'n2', isRead: false),
        ];
      final vm = _makeViewModel(getNotifications: getNotifs);

      await vm.load();
      await vm.markAllAsRead();

      expect(vm.unreadCount, 0);
      expect(vm.notifications.every((n) => n.isRead), isTrue);
      expect(vm.isProcessing, isFalse);
    });

    test('no debe llamar al use case si todas las notificaciones ya están leídas', () async {
      final getNotifs = _MockGetNotifications()
        ..returnValue = [_makeNotif(id: 'n1', isRead: true)];
      final markRead  = _MockMarkRead();
      final vm        = _makeViewModel(getNotifications: getNotifs, markRead: markRead);

      await vm.load();
      await vm.markAllAsRead();

      expect(markRead.callCount, 0);
    });

    test('debe establecer error si markAllAsRead falla en el servidor', () async {
      final getNotifs = _MockGetNotifications()
        ..returnValue = [_makeNotif(id: 'n1', isRead: false)];
      final markRead  = _MockMarkRead()..throwError = AppError.server();
      final vm        = _makeViewModel(getNotifications: getNotifs, markRead: markRead);

      await vm.load();
      await vm.markAllAsRead();

      expect(vm.error,        isNotNull);
      expect(vm.isProcessing, isFalse);
    });
  });

  // ── deleteAll() ───────────────────────────────────────────────────────────────

  group('deleteAll()', () {
    test('debe vaciar la lista de notificaciones tras eliminar', () async {
      final getNotifs = _MockGetNotifications()
        ..returnValue = [_makeNotif(id: 'n1'), _makeNotif(id: 'n2')];
      final vm = _makeViewModel(getNotifications: getNotifs);

      await vm.load();
      expect(vm.notifications.length, 2);

      await vm.deleteAll();

      expect(vm.notifications, isEmpty);
      expect(vm.unreadCount,   0);
      expect(vm.isProcessing,  isFalse);
    });

    test('no debe llamar al use case si ya no hay notificaciones', () async {
      final getNotifs = _MockGetNotifications()..returnValue = [];
      final delete    = _MockDelete();
      final vm        = _makeViewModel(getNotifications: getNotifs, delete: delete);

      await vm.load();
      await vm.deleteAll();

      expect(delete.callCount, 0);
    });

    test('debe establecer error si deleteAll falla en el servidor', () async {
      final getNotifs = _MockGetNotifications()
        ..returnValue = [_makeNotif(id: 'n1')];
      final delete    = _MockDelete()..throwError = AppError.server();
      final vm        = _makeViewModel(getNotifications: getNotifs, delete: delete);

      await vm.load();
      await vm.deleteAll();

      expect(vm.error,        isNotNull);
      expect(vm.isProcessing, isFalse);
    });
  });

  // ── markSelectedAsRead() ────────────────────────────────────────────────────

  group('markSelectedAsRead()', () {
    test('debe marcar solo las notificaciones seleccionadas, no las demás', () async {
      final getNotifs = _MockGetNotifications()
        ..returnValue = [
          _makeNotif(id: 'n1', isRead: false),
          _makeNotif(id: 'n2', isRead: false),
          _makeNotif(id: 'n3', isRead: false),
        ];
      final markRead = _MockMarkRead();
      final vm = _makeViewModel(getNotifications: getNotifs, markRead: markRead);

      await vm.load();
      await vm.markSelectedAsRead({'n1', 'n3'});

      final n1 = vm.notifications.firstWhere((n) => n.id == 'n1');
      final n2 = vm.notifications.firstWhere((n) => n.id == 'n2');
      final n3 = vm.notifications.firstWhere((n) => n.id == 'n3');
      expect(n1.isRead, isTrue);
      expect(n2.isRead, isFalse);
      expect(n3.isRead, isTrue);
      expect(vm.unreadCount, 1);
      expect(markRead.lastIds, ['n1', 'n3']);
    });
  });

  // ── deleteSelected() ──────────────────────────────────────────────────────────

  group('deleteSelected()', () {
    test('debe eliminar solo las notificaciones seleccionadas, no las demás', () async {
      final getNotifs = _MockGetNotifications()
        ..returnValue = [
          _makeNotif(id: 'n1'),
          _makeNotif(id: 'n2'),
          _makeNotif(id: 'n3'),
        ];
      final delete = _MockDelete();
      final vm = _makeViewModel(getNotifications: getNotifs, delete: delete);

      await vm.load();
      expect(vm.notifications.length, 3);

      await vm.deleteSelected({'n2'});

      expect(vm.notifications.length, 2);
      expect(vm.notifications.any((n) => n.id == 'n2'), isFalse);
      expect(vm.notifications.any((n) => n.id == 'n1'), isTrue);
      expect(vm.notifications.any((n) => n.id == 'n3'), isTrue);
      expect(delete.lastIds, ['n2']);
    });
  });

  // ── clearError() ──────────────────────────────────────────────────────────────

  group('clearError()', () {
    test('debe limpiar el error establecido por load()', () async {
      final getNotifs = _MockGetNotifications()..throwError = AppError.network();
      final vm        = _makeViewModel(getNotifications: getNotifs);

      await vm.load();
      expect(vm.error, isNotNull);

      vm.clearError();
      expect(vm.error, isNull);
    });
  });
}
