/// @file socket_client.dart
/// @description Cliente Socket.IO con reconexión exponencial + jitter y cola de
/// eventos pendientes mientras la conexión no está disponible.
/// Expone connect/disconnect/emit/on/off como interfaz simple para los repositorios.
/// @module Core
/// @layer Core
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:socket_io_client/socket_io_client.dart' as sio;

import '../config/app_config.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CONSTANTES DE RECONEXIÓN
// ═══════════════════════════════════════════════════════════════════════════════

const Duration _kReconnectBase = Duration(seconds: 2);
const Duration _kReconnectMax  = Duration(seconds: 60);
const double   _kBackoffFactor = 2.0;

// ═══════════════════════════════════════════════════════════════════════════════
// MODELOS INTERNOS
// ═══════════════════════════════════════════════════════════════════════════════

/// Evento pendiente de emitir cuando la conexión se restaure.
class _PendingEvent {
  const _PendingEvent(this.event, this.data);
  final String event;
  final dynamic data;
}

// ═══════════════════════════════════════════════════════════════════════════════
// SOCKET CLIENT
// ═══════════════════════════════════════════════════════════════════════════════

/// Cliente Socket.IO gestionado para la aplicación de plantas.
///
/// Características:
///  - Reconexión automática con backoff exponencial + jitter (no depende del
///    mecanismo interno de socket_io_client para mayor control).
///  - Cola de eventos pendientes: los emit() mientras está desconectado se
///    encolan y se procesan en orden al reconectar.
///  - Token de autenticación inyectado en los query params de la handshake.
///  - [onConnected] / [onDisconnected] streams para que la UI reaccione al estado.
///
/// [injectable] registrar en container.dart como singleton.
/// [dependencies] tokenProvider: misma función que usa ApiClient.
class SocketClient {
  final Future<String?> Function() _tokenProvider;
  final math.Random _rng = math.Random();

  sio.Socket? _socket;
  bool _intentionalDisconnect = false;
  int  _reconnectAttempt = 0;
  Timer? _reconnectTimer;

  /// Cola FIFO de eventos emitidos mientras la conexión no estaba disponible.
  final List<_PendingEvent> _pendingQueue = [];

  /// Listeners registrados por la app. Se mantienen en memoria para
  /// re-aplicarlos en cada (re)conexión: permite registrar handlers
  /// ANTES de llamar a connect(), y que persistan tras reconexión. Sin
  /// este buffer, los `socket.on(...)` hechos antes de connect() serían
  /// no-op porque `_socket` aún sería null.
  final Map<String, List<void Function(dynamic)>> _registeredHandlers = {};

  // Controladores de estado de conexión.
  final StreamController<void> _connectedCtrl    = StreamController.broadcast();
  final StreamController<void> _disconnectedCtrl = StreamController.broadcast();

  /// Stream que emite un evento cada vez que el socket se conecta (o reconecta).
  Stream<void> get onConnected    => _connectedCtrl.stream;

  /// Stream que emite un evento cada vez que el socket se desconecta.
  Stream<void> get onDisconnected => _disconnectedCtrl.stream;

  /// true si el socket está actualmente conectado al servidor.
  bool get isConnected => _socket?.connected ?? false;

  SocketClient({required Future<String?> Function() tokenProvider})
      : _tokenProvider = tokenProvider;

  // ─── Ciclo de vida ────────────────────────────────────────────────────────────

  /// Conecta al servidor Socket.IO usando la URL de [AppConfig.socketUrl].
  /// Incluye el access token en los query params para autenticación en handshake.
  Future<void> connect() async {
    if (isConnected) return;

    _intentionalDisconnect = false;
    final token = await _tokenProvider();

    _socket = sio.io(
      AppConfig.instance.socketUrl,
      sio.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          // Token en AUTH (modo recomendado socket.io v3+: el backend lo
          // lee de handshake.auth.token). También en query como fallback
          // por si algún proxy intermedio no propaga auth correctamente
          // — el backend acepta ambos (SocketGateway hace
          // `auth.token ?? query.token`).
          .setAuth({'token': token ?? ''})
          .setQuery({'token': token ?? ''})
          .build(),
    );

    _socket!
      ..onConnect(_handleConnect)
      ..onDisconnect(_handleDisconnect)
      ..onConnectError(_handleConnectError);

    _socket!.connect();
  }

  /// Desconecta de forma intencional (no reintenta).
  void disconnect() {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  // ─── Emisión y escucha ────────────────────────────────────────────────────────

  /// Emite un evento al servidor.
  ///
  /// Si el socket no está conectado, el evento se encola y se enviará
  /// automáticamente al restaurar la conexión.
  void emit(String event, [dynamic data]) {
    if (isConnected) {
      _socket!.emit(event, data);
    } else {
      _pendingQueue.add(_PendingEvent(event, data));
    }
  }

  /// Suscribe un listener a un evento del servidor.
  ///
  /// El handler se guarda en [_registeredHandlers] para re-aplicarlo en
  /// cada (re)conexión: permite registrar listeners ANTES de llamar a
  /// [connect()] y que persistan tras reconexiones automáticas.
  void on(String event, void Function(dynamic data) handler) {
    _registeredHandlers.putIfAbsent(event, () => []).add(handler);
    _socket?.on(event, handler);
  }

  /// Elimina un listener previamente registrado.
  void off(String event, [void Function(dynamic data)? handler]) {
    if (handler != null) {
      _registeredHandlers[event]?.remove(handler);
      if (_registeredHandlers[event]?.isEmpty ?? false) {
        _registeredHandlers.remove(event);
      }
      _socket?.off(event, handler);
    } else {
      _registeredHandlers.remove(event);
      _socket?.off(event);
    }
  }

  /// Re-aplica todos los listeners de [_registeredHandlers] sobre el
  /// socket activo. Se llama en cada (re)conexión exitosa para que los
  /// handlers que se registraron antes del connect() o durante una
  /// desconexión sigan funcionando tras reconectar.
  void _reattachHandlers() {
    final s = _socket;
    if (s == null) return;
    for (final entry in _registeredHandlers.entries) {
      for (final handler in entry.value) {
        s.on(entry.key, handler);
      }
    }
  }

  // ─── Handlers internos ───────────────────────────────────────────────────────

  void _handleConnect(_) {
    _reconnectAttempt = 0;
    _reconnectTimer?.cancel();
    // Re-aplicar listeners registrados en el buffer: cubre el caso
    // de que la app haya llamado on(...) antes del connect(), o tras
    // una reconexión donde socket_io_client puede haber soltado
    // listeners internamente.
    _reattachHandlers();
    _connectedCtrl.add(null);
    _flushPendingQueue();
  }

  void _handleDisconnect(_) {
    _disconnectedCtrl.add(null);
    if (!_intentionalDisconnect) {
      _scheduleReconnect();
    }
  }

  void _handleConnectError(_) {
    if (!_intentionalDisconnect) {
      _scheduleReconnect();
    }
  }

  // ─── Reconexión ──────────────────────────────────────────────────────────────

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final delay = _computeDelay(_reconnectAttempt);
    _reconnectAttempt++;

    _reconnectTimer = Timer(delay, () async {
      if (!_intentionalDisconnect) {
        // Actualizar el token antes de reconectar (podría haberse renovado).
        final token = await _tokenProvider();
        _socket?.io.options?['auth']  = {'token': token ?? ''};
        _socket?.io.options?['query'] = {'token': token ?? ''};
        _socket?.connect();
      }
    });
  }

  Duration _computeDelay(int attempt) {
    final exp     = _kReconnectBase * math.pow(_kBackoffFactor, attempt);
    final capped  = exp > _kReconnectMax ? _kReconnectMax : exp;
    final jitterMs = _rng.nextInt(1000);
    return capped + Duration(milliseconds: jitterMs);
  }

  // ─── Cola de eventos pendientes ───────────────────────────────────────────────

  /// Envía en orden todos los eventos encolados durante la desconexión.
  void _flushPendingQueue() {
    while (_pendingQueue.isNotEmpty) {
      final event = _pendingQueue.removeAt(0);
      _socket?.emit(event.event, event.data);
    }
  }

  // ─── Limpieza ─────────────────────────────────────────────────────────────────

  /// Libera recursos (llamar desde dispose() del widget raíz o en logout).
  void dispose() {
    disconnect();
    _connectedCtrl.close();
    _disconnectedCtrl.close();
  }
}
