/// @file connectivity_service.dart
/// @description Wrapper sobre connectivity_plus que expone el estado de red
/// como un Stream y un método síncrono isOnline().
/// Centraliza toda la lógica de conectividad para que el resto de la app
/// no dependa directamente del paquete connectivity_plus.
/// @module Core
/// @layer Core
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CONNECTIVITY SERVICE
// ═══════════════════════════════════════════════════════════════════════════════

/// Servicio de conectividad que abstrae connectivity_plus.
///
/// Expone:
///  - [onConnectivityChanged] — `Stream<bool>` donde true = online, false = offline.
///  - [isOnline()]            — consulta instantánea del estado actual.
///  - [initialize()]          — debe llamarse durante el arranque de la app.
///
/// [injectable] registrar en container.dart como singleton.
class ConnectivityService {
  final Connectivity _connectivity;

  /// Estado de conectividad actual (se actualiza al recibir cambios del stream).
  bool _isOnline = true;

  /// Controlador del stream público de cambios.
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  // ─── Inicialización ───────────────────────────────────────────────────────────

  /// Inicializa el servicio: consulta el estado actual y se suscribe a cambios.
  /// Debe llamarse en main.dart antes de runApp().
  Future<void> initialize() async {
    // Estado inicial.
    final results = await _connectivity.checkConnectivity();
    _isOnline = _hasConnection(results);

    // Suscripción a cambios futuros.
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = _hasConnection(results);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(online);
      }
    });
  }

  // ─── API pública ──────────────────────────────────────────────────────────────

  /// Stream que emite true al conectar y false al desconectar.
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// true si el dispositivo tiene conexión de red en este momento.
  bool isOnline() => _isOnline;

  /// true si el dispositivo está sin conexión.
  bool isOffline() => !_isOnline;

  // ─── Limpieza ─────────────────────────────────────────────────────────────────

  /// Libera recursos. Llamar en dispose() del widget raíz o en cierre de la app.
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }

  // ─── Helper ───────────────────────────────────────────────────────────────────

  /// true si alguno de los resultados indica conexión real (wifi, móvil o ethernet).
  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.wifi     ||
        r == ConnectivityResult.mobile   ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }
}
