/// @file notifications_page_test.dart
/// @description Tests de widget para NotificationsPage.
/// Verifica que la corrección "setState-during-build" (uso de addPostFrameCallback
/// en initState en lugar de llamar load() directamente en build) no lanza
/// excepciones durante el montaje del árbol.
/// También cubre: estado vacío, lista de notificaciones, AppBar con acciones.
/// @module Reminders
/// @layer Presentation
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:plants_app/domain/entities/notification.dart';
import 'package:plants_app/domain/interfaces/usecases/notifications/i_delete_notifications_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/notifications/i_get_user_notifications_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/notifications/i_mark_notifications_read_use_case.dart';
import 'package:plants_app/presentation/pages/notifications_page.dart';
import 'package:plants_app/presentation/viewmodels/reminders/notifications_viewmodel.dart';

// ─── Mocks manuales ───────────────────────────────────────────────────────────

class _MockGetNotifications implements IGetUserNotificationsUseCase {
  List<AppNotification> returnValue = [];

  @override
  Future<List<AppNotification>> execute() async => returnValue;
}

class _MockMarkRead implements IMarkNotificationsReadUseCase {
  @override
  Future<void> execute({List<String>? ids}) async {}
}

class _MockDelete implements IDeleteNotificationsUseCase {
  @override
  Future<void> execute({List<String>? ids}) async {}
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

final _sl = GetIt.instance;

final _now = DateTime.utc(2026, 3, 17, 10);

AppNotification _makeNotif({
  String id     = 'notif-001',
  bool   isRead = false,
  String type   = 'watering',
  String msg    = 'Es hora de regar tu planta',
}) =>
    AppNotification(
      id:         id,
      userId:     'user-001',
      type:       type,
      message:    msg,
      reminderId: 'reminder-001',
      plantId:    'plant-001',
      isRead:     isRead,
      createdAt:  _now,
    );

NotificationsViewModel _makeViewModel({
  _MockGetNotifications? getNotifications,
}) =>
    NotificationsViewModel(
      getNotificationsUseCase:      getNotifications ?? _MockGetNotifications(),
      markNotificationsReadUseCase: _MockMarkRead(),
      deleteNotificationsUseCase:   _MockDelete(),
    );

/// Envuelve el widget en un MaterialApp sin dependencias de autenticación
/// (NotificationsPage no requiere AuthViewModel en su árbol).
Widget _wrap(Widget child) => MaterialApp(home: child);

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  setUpAll(() async {
    // Inicializar localización para DateFormat usado en _NotificationTile.
    await initializeDateFormatting('es_ES', null);
  });

  setUp(() async {
    await _sl.reset();
  });

  tearDownAll(() async => _sl.reset());

  // ── Regresión setState-during-build ───────────────────────────────────────────

  group('Regresión setState-during-build', () {
    testWidgets(
        'no lanza excepción al montar la página (addPostFrameCallback funciona)',
        (tester) async {
      _sl.registerSingleton<NotificationsViewModel>(_makeViewModel());

      await tester.pumpWidget(_wrap(const NotificationsPage()));
      // Primer pump: construye el widget y dispara el post-frame callback.
      await tester.pump();
      // Segundo pump: el callback load() se ejecuta y notifyListeners() es seguro.
      await tester.pumpAndSettle();

      // Si hubiese "setState during build", el test lanzaría FlutterError aquí.
      expect(tester.takeException(), isNull);
    });

    testWidgets('muestra el título "Notificaciones" en el AppBar', (tester) async {
      _sl.registerSingleton<NotificationsViewModel>(_makeViewModel());

      await tester.pumpWidget(_wrap(const NotificationsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Notificaciones'), findsOneWidget);
    });
  });

  // ── Estado vacío ──────────────────────────────────────────────────────────────

  group('Estado vacío', () {
    testWidgets('muestra "No tienes notificaciones" cuando la lista está vacía',
        (tester) async {
      final getNotifs = _MockGetNotifications()..returnValue = [];
      _sl.registerSingleton<NotificationsViewModel>(
        _makeViewModel(getNotifications: getNotifs),
      );

      await tester.pumpWidget(_wrap(const NotificationsPage()));
      await tester.pumpAndSettle();

      expect(find.text('No tienes notificaciones'), findsOneWidget);
    });

    testWidgets('los botones "Marcar como leído" y "Eliminar" están deshabilitados sin notificaciones',
        (tester) async {
      final getNotifs = _MockGetNotifications()..returnValue = [];
      _sl.registerSingleton<NotificationsViewModel>(
        _makeViewModel(getNotifications: getNotifs),
      );

      await tester.pumpWidget(_wrap(const NotificationsPage()));
      await tester.pumpAndSettle();

      // Los IconButton con onPressed=null están deshabilitados.
      final checkBtn  = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.check_circle_outline_rounded),
      );
      final deleteBtn = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.delete_outline_rounded),
      );
      expect(checkBtn.onPressed,  isNull);
      expect(deleteBtn.onPressed, isNull);
    });
  });

  // ── Lista de notificaciones ───────────────────────────────────────────────────

  group('Lista de notificaciones', () {
    testWidgets('muestra el mensaje de una notificación de riego', (tester) async {
      final getNotifs = _MockGetNotifications()
        ..returnValue = [_makeNotif(msg: 'Es hora de regar tu planta')];
      _sl.registerSingleton<NotificationsViewModel>(
        _makeViewModel(getNotifications: getNotifs),
      );

      await tester.pumpWidget(_wrap(const NotificationsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Es hora de regar tu planta'), findsOneWidget);
    });

    testWidgets('muestra el número correcto de tiles en la lista', (tester) async {
      final getNotifs = _MockGetNotifications()
        ..returnValue = [
          _makeNotif(id: 'n1', msg: 'Regar Monstera'),
          _makeNotif(id: 'n2', msg: 'Podar Rosa'),
          _makeNotif(id: 'n3', msg: 'Fertilizar Limonero'),
        ];
      _sl.registerSingleton<NotificationsViewModel>(
        _makeViewModel(getNotifications: getNotifs),
      );

      await tester.pumpWidget(_wrap(const NotificationsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Regar Monstera'),     findsOneWidget);
      expect(find.text('Podar Rosa'),         findsOneWidget);
      expect(find.text('Fertilizar Limonero'), findsOneWidget);
    });

    testWidgets(
        'el botón "Marcar como leído" está habilitado si hay notificaciones no leídas',
        (tester) async {
      final getNotifs = _MockGetNotifications()
        ..returnValue = [_makeNotif(isRead: false)];
      _sl.registerSingleton<NotificationsViewModel>(
        _makeViewModel(getNotifications: getNotifs),
      );

      await tester.pumpWidget(_wrap(const NotificationsPage()));
      await tester.pumpAndSettle();

      final checkBtn = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.check_circle_outline_rounded),
      );
      expect(checkBtn.onPressed, isNotNull);
    });
  });
}
