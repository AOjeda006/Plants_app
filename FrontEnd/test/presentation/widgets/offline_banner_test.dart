/// @file offline_banner_test.dart
/// @description Tests del OfflineBanner. El banner solo refleja el estado
/// de connectivity — sin contador, sin syncing, sin discarded.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:plants_app/core/utils/connectivity/connectivity_service.dart';
import 'package:plants_app/presentation/widgets/offline_banner.dart';

// ─── Stub de ConnectivityService ─────────────────────────────────────────────

class _StubConnectivityService implements ConnectivityService {
  final StreamController<bool> _ctrl = StreamController<bool>.broadcast();
  bool _isOnline;

  _StubConnectivityService({bool initialOnline = true}) : _isOnline = initialOnline;

  @override
  Stream<bool> get onConnectivityChanged => _ctrl.stream;

  @override
  bool isOnline() => _isOnline;

  void emit(bool online) {
    _isOnline = online;
    _ctrl.add(online);
  }

  Future<void> closeController() async {
    await _ctrl.close();
  }

  @override
  Future<void> initialize() async {}

  // Métodos restantes (no usados por el banner): stubs vacíos.
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

final _sl = GetIt.instance;

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  late _StubConnectivityService stub;

  setUp(() async {
    if (_sl.isRegistered<ConnectivityService>()) {
      _sl.unregister<ConnectivityService>();
    }
    stub = _StubConnectivityService(initialOnline: true);
    _sl.registerSingleton<ConnectivityService>(stub);
  });

  tearDown(() async {
    await stub.closeController();
    if (_sl.isRegistered<ConnectivityService>()) {
      _sl.unregister<ConnectivityService>();
    }
  });

  testWidgets('OfflineBanner: oculto cuando hay conexión', (tester) async {
    await tester.pumpWidget(_wrap(const OfflineBanner()));
    await tester.pumpAndSettle();

    expect(find.text('Sin conexión · Modo offline'), findsNothing);
  });

  testWidgets('OfflineBanner: visible cuando se pierde la conexión', (tester) async {
    await tester.pumpWidget(_wrap(const OfflineBanner()));
    await tester.pumpAndSettle();

    stub.emit(false);
    await tester.pumpAndSettle();

    expect(find.text('Sin conexión · Modo offline'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
  });

  testWidgets('OfflineBanner: vuelve a ocultarse al reconectar', (tester) async {
    await tester.pumpWidget(_wrap(const OfflineBanner()));
    stub.emit(false);
    await tester.pumpAndSettle();
    expect(find.text('Sin conexión · Modo offline'), findsOneWidget);

    stub.emit(true);
    await tester.pumpAndSettle();

    expect(find.text('Sin conexión · Modo offline'), findsNothing);
  });

  testWidgets('ReconnectedBanner.show: muestra SnackBar verde', (tester) async {
    late BuildContext capturedCtx;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (ctx) {
        capturedCtx = ctx;
        return const Scaffold(body: SizedBox());
      }),
    ));

    ReconnectedBanner.show(capturedCtx);
    await tester.pump();

    expect(find.text('Conexión restaurada'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_rounded), findsOneWidget);
  });
}
