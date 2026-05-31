/// @file firebase_messaging_service.dart
/// @description Servicio de notificaciones push con Firebase Cloud Messaging.
/// Gestiona permisos, mensajes en primer plano (con notificación local) y
/// deep linking desde notificaciones (background y app terminada).
/// @module Core
/// @layer Core
library;

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// BACKGROUND HANDLER (top-level)
// ═══════════════════════════════════════════════════════════════════════════════

/// Handler de mensajes en segundo plano.
/// Debe ser una función top-level (no puede ser un método de clase).
/// No navega — la navegación ocurre cuando el usuario toca la notificación
/// y onMessageOpenedApp la procesa.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // TFG: en producción inicializar Firebase aquí si se usa Firebase en background.
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

// ═══════════════════════════════════════════════════════════════════════════════
// FIREBASE MESSAGING SERVICE
// ═══════════════════════════════════════════════════════════════════════════════

/// Servicio de notificaciones push.
///
/// Responsabilidades:
///  - Solicitar permisos al usuario.
///  - Mostrar notificaciones locales cuando la app está en primer plano.
///  - Navegar a la pantalla correcta al tocar una notificación (deep link).
///
/// Tipos de payload soportados:
///  - `type: 'plant'`  + `id` → /plants/detail
///  - `type: 'post'`   + `id` → /community/post
///  - `type: 'chat'`   + `id` (conversationId) → /conversations/chat
///
/// [injectable] registrar en container.dart como lazySingleton.
/// [dependencies] `GlobalKey<NavigatorState>` (inyectado en la construcción).
///
/// TFG: requiere google-services.json (Android) y GoogleService-Info.plist (iOS)
/// generados con `flutterfire configure` del proyecto Firebase correspondiente.
class FirebaseMessagingService {
  final GlobalKey<NavigatorState> _navigatorKey;

  static const _channelId   = 'plants_app_notifications';
  static const _channelName = 'Plants App';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  FirebaseMessagingService(this._navigatorKey);

  // ─── Inicialización ───────────────────────────────────────────────────────

  /// Mensaje pendiente cuando la app se abre desde una notificación con
  /// la app cerrada. Se almacena en `initialize()` y se procesa cuando
  /// MainTabsPage llama a [consumePendingInitialMessage] tras montar el
  /// árbol con sesión válida.
  ///
  /// Se evita procesar el mensaje directamente en `initialize()` con un
  /// `Future.delayed` arbitrario: el Navigator no está listo de forma
  /// fiable (cold start + SplashPage + checkSession + watchdog hacen que
  /// el timing exacto varíe) y la app acababa abriendo en /plants en
  /// lugar del deep link. En su lugar, MainTabsPage decide cuándo
  /// procesarlo invocando [consumePendingInitialMessage] tras montar el
  /// árbol con sesión válida.
  RemoteMessage? _pendingInitialMessage;

  /// Inicializa el servicio: permisos, canal local, listeners de FCM.
  /// Llamar desde main.dart ANTES de runApp().
  Future<void> initialize() async {
    // Registrar handler de background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Inicializar plugin de notificaciones locales
    await _initLocalNotifications();

    // Solicitar permisos (iOS pide diálogo; Android 13+ también)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Listener: mensaje recibido con la app en PRIMER PLANO
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Listener: usuario tocó una notificación con la app en SEGUNDO PLANO
    FirebaseMessaging.onMessageOpenedApp.listen(_navigateFromMessage);

    // App TERMINADA: guardar el mensaje inicial para que MainTabsPage lo
    // procese cuando el árbol esté montado y la sesión autenticada.
    _pendingInitialMessage = await FirebaseMessaging.instance.getInitialMessage();
  }

  /// Procesa el mensaje inicial pendiente (deep link con app cerrada).
  /// Debe llamarse cuando el árbol UI esté montado y el usuario
  /// autenticado — típicamente desde `MainTabsPage.initState`.
  ///
  /// Devuelve true si había un mensaje pendiente y se procesó.
  bool consumePendingInitialMessage() {
    final msg = _pendingInitialMessage;
    if (msg == null) return false;
    _pendingInitialMessage = null;
    _navigateFromMessage(msg);
    return true;
  }

  // ─── Notificaciones locales ───────────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings     = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS:     iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Navegar desde payload almacenado al tocar la notificación local
        if (details.payload != null) {
          _navigateFromPayload(details.payload!);
        }
      },
    );

    // Crear canal de notificaciones en Android 8+
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Notificaciones de la app de plantas',
            importance:  Importance.high,
          ),
        );
  }

  // ─── Handlers ─────────────────────────────────────────────────────────────

  /// Muestra una notificación local cuando llega un FCM en primer plano.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          icon:       '@mipmap/ic_launcher',
          importance: Importance.high,
          priority:   Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: _encodePayload(message.data),
    );
  }

  // ─── Deep linking ─────────────────────────────────────────────────────────

  /// Navega a la pantalla correspondiente según el payload del FCM.
  void _navigateFromMessage(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  /// Navega a partir de un payload string `type:id`.
  void _navigateFromPayload(String payload) {
    final parts = payload.split(':');
    if (parts.length < 2) return;
    _navigateFromData({'type': parts[0], 'id': parts.sublist(1).join(':')});
  }

  /// Lógica central de navegación por tipo de notificación.
  ///
  /// TFG: rutas hardcoded para evitar dependencia circular con presentation layer.
  void _navigateFromData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final id   = data['id']   as String?;
    if (type == null || id == null || id.isEmpty) return;

    final nav = _navigatorKey.currentState;
    if (nav == null) return;

    switch (type) {
      case 'plant':
        nav.pushNamed('/plants/detail', arguments: id);
      case 'post':
        nav.pushNamed('/community/post', arguments: id);
      case 'chat':
        nav.pushNamed('/conversations/chat', arguments: {
          'conversationId':  id,
          'participantName': data['participantName'] as String? ?? 'Chat',
          'participantPhoto': data['participantPhoto'] as String?,
          'currentUserId':   data['currentUserId']   as String? ?? '',
        });
    }
  }

  // ─── Utilidades ───────────────────────────────────────────────────────────

  /// Codifica los datos relevantes como payload compacto `type:id`.
  String _encodePayload(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    final id   = data['id']   as String? ?? '';
    return '$type:$id';
  }

  /// Devuelve el token FCM del dispositivo (útil para registrarlo en el backend).
  Future<String?> getToken() => FirebaseMessaging.instance.getToken();

  /// Cancela todas las notificaciones push del sistema para esta app.
  ///
  /// Llamado desde `MainTabsPage` en `initState` (cold start tras splash)
  /// y en `didChangeAppLifecycleState.resumed` (warm resume). Al volver a
  /// la app, el usuario ya está revisando el contenido — las cards de la
  /// barra de notificaciones quedan obsoletas y deben limpiarse.
  ///
  /// En Android, `FlutterLocalNotificationsPlugin.cancelAll()` invoca
  /// `NotificationManagerCompat.cancelAll()` que limpia TODAS las
  /// notificaciones de la app (incluidas las que FCM publicó
  /// directamente cuando la app estaba cerrada). En iOS solo limpia las
  /// que el plugin posteó; para FCM directo en iOS habría que llamar
  /// adicionalmente a `UNUserNotificationCenter.removeAllDeliveredNotifications`
  /// pero queda fuera de alcance TFG (proyecto despliegue Android-first).
  Future<void> clearAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
    } catch (_) {
      // Plugin no inicializado o sin permisos — silencioso (best-effort).
    }
  }

  /// `deleteToken()` se conserva como API por si en el futuro se necesita
  /// forzar regeneración, pero el `LogoutUseCase` profundo YA NO la
  /// invoca: llamar a `FirebaseMessaging.instance.deleteToken()` deja a
  /// la siguiente sesión con `getToken() == null` durante varios segundos
  /// (Firebase tarda en regenerar). Si el `MainTabsPage.initState` se
  /// ejecuta en ese hueco, `registerToken` no envía nada y la cuenta
  /// queda sin push hasta el siguiente arranque. Es más seguro dejar el
  /// token activo en Firebase server y desasociar SOLO en el backend
  /// (DELETE /users/me/fcm-token + updateMany del PUT cubren el caso de
  /// cambio de cuenta).
  Future<void> deleteToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // Firebase no inicializado, sin permisos, o sin red — silencioso.
    }
  }

  /// Subscripción única a `onTokenRefresh`. Se crea la primera vez que
  /// `registerToken` se llama y se mantiene viva todo el ciclo de vida
  /// del singleton. Sin este guard, cada login añadía un listener nuevo
  /// y los antiguos seguían activos con callbacks obsoletos.
  StreamSubscription<String>? _tokenRefreshSub;

  /// Último callback `send` registrado. El listener compartido siempre
  /// invoca el más reciente para que las llamadas usen el JWT del
  /// usuario actual (vía `tokenProvider` de ApiClient).
  Future<void> Function(String fcmToken)? _latestSend;

  /// Obtiene el token actual y lo envía al backend; además se suscribe
  /// (una sola vez) a `onTokenRefresh` para reenviarlo cuando rote.
  ///
  /// Robustez:
  ///  - Si `getToken()` devuelve null (Firebase regenerando, sin
  ///    permiso aún concedido, race de timing), reintenta hasta 3 veces
  ///    con backoff 500ms/1s/2s antes de rendirse.
  ///  - El listener de `onTokenRefresh` se registra una sola vez y
  ///    delega en `_latestSend` para no acumular suscripciones obsoletas
  ///    al cambiar de cuenta.
  ///
  /// El callback [send] encapsula la llamada HTTP al backend
  /// (`PUT /users/me/fcm-token` con `{fcmToken}`). Permite mantener
  /// este servicio sin acoplarse a `ApiClient`.
  Future<void> registerToken(
    Future<void> Function(String fcmToken) send,
  ) async {
    _latestSend = send;
    try {
      // Retry corto: si Firebase aún no ha materializado el token
      // (típicamente <2s tras un cold start o un deleteToken previo),
      // damos 3 intentos con backoff incremental.
      String? token;
      for (final delay in const [
        Duration.zero,
        Duration(milliseconds: 500),
        Duration(seconds: 1),
        Duration(seconds: 2),
      ]) {
        if (delay > Duration.zero) await Future<void>.delayed(delay);
        token = await getToken();
        if (token != null && token.isNotEmpty) break;
      }
      if (token != null && token.isNotEmpty) {
        await send(token);
      }
      // Listener único — se crea solo la primera vez. Las llamadas
      // posteriores reutilizan la subscripción pero apuntan al
      // `_latestSend` que SIEMPRE es el callback más reciente.
      _tokenRefreshSub ??= FirebaseMessaging.instance.onTokenRefresh.listen(
        (newToken) async {
          final cb = _latestSend;
          if (cb == null) return;
          try {
            await cb(newToken);
          } catch (_) {
            // Tolerar fallos transitorios; el siguiente login reintentará.
          }
        },
      );
    } catch (_) {
      // Firebase no inicializado (modo dev sin google-services.json):
      // simplemente no se registra token. La app sigue funcionando.
    }
  }
}
