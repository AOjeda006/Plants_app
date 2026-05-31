/// @file main_tabs_page.dart
/// @description Página raíz de la app autenticada.
/// Gestiona la navegación principal con 6 destinos:
/// Plantas, Comunidad, Mensajes, Notificaciones, Calendario y Perfil.
/// En web/desktop (ancho > 600px) usa NavigationRail vertical a la izquierda.
/// En móvil (ancho ≤ 600px) usa BottomNavigationBar inferior.
/// @module Core
/// @layer Presentation
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_theme.dart';
import '../../core/di/container.dart';
import '../../core/network/api_client.dart';
import '../../core/network/socket_client.dart';
import '../../core/services/firebase_messaging_service.dart';
import '../../core/utils/connectivity/connectivity_service.dart';
import '../../l10n/app_localizations.dart';
import '../viewmodels/auth/auth_viewmodel.dart';
import '../viewmodels/chat/conversations_viewmodel.dart';
import '../viewmodels/community/feed_viewmodel.dart';
import '../viewmodels/plants/plants_list_viewmodel.dart';
import '../viewmodels/reminders/notifications_viewmodel.dart';
import '../widgets/offline_banner.dart';
import 'community_feed_page.dart';
import 'conversations_list_page.dart';
import 'my_profile_page.dart';
import 'notifications_page.dart';
import 'calendar_page.dart';
import 'plants_list_page.dart';
import 'user_profile_page.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN TABS SCOPE
// ═══════════════════════════════════════════════════════════════════════════════

/// InheritedWidget que permite a las páginas hijas mostrar UserProfilePage
/// dentro del body de MainTabsPage, manteniendo el BottomNavigationBar visible.
///
/// Usar [MainTabsScope.maybeOf(context)] para obtener la instancia y llamar
/// a [pushUserProfile] o [popUserProfile].
class MainTabsScope extends InheritedWidget {
  /// Muestra UserProfilePage inline (debajo del AppBar, encima del BottomNav).
  final void Function(Map<String, dynamic> args) pushUserProfile;

  /// Cierra el UserProfilePage inline y vuelve a la pestaña anterior.
  final VoidCallback popUserProfile;

  const MainTabsScope({
    super.key,
    required this.pushUserProfile,
    required this.popUserProfile,
    required super.child,
  });

  /// Obtiene la instancia sin crear dependencia reactiva (adecuado para callbacks).
  static MainTabsScope? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<MainTabsScope>();
  }

  @override
  bool updateShouldNotify(MainTabsScope oldWidget) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN TABS PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Shell de navegación principal. Hospeda las 6 secciones con tab bar inferior.
///
/// Las páginas se mantienen vivas con [IndexedStack] para conservar el estado
/// entre cambios de pestaña.
/// Índices de pestañas: 0=Plantas, 1=Comunidad, 2=Mensajes, 3=Notificaciones, 4=Calendario, 5=Perfil.
class MainTabsPage extends StatefulWidget {
  const MainTabsPage({super.key});

  @override
  State<MainTabsPage> createState() => _MainTabsPageState();
}

class _MainTabsPageState extends State<MainTabsPage> with WidgetsBindingObserver {
  int _currentIndex = 0;

  // Páginas mantenidas vivas en IndexedStack (conservan scroll y estado entre tabs).
  // MyProfilePage, NotificationsPage y ConversationsListPage se excluyen:
  // se montan/desmontan en cada visita para cargar datos frescos.
  static const List<Widget> _pages = [
    PlantsListPage(),
    CommunityFeedPage(),
  ];

  // Página del calendario — se crea una sola vez para mantener estado.
  static const Widget _calendarPage = CalendarPage();

  // Badge de mensajes no leídos — se activa vía socket.
  bool _hasUnreadMessages = false;

  // Argumentos para mostrar UserProfilePage inline (mantiene BottomNav visible).
  // null = no hay perfil abierto, se muestra la pestaña actual.
  Map<String, dynamic>? _userProfileArgs;

  // Suscripción al stream de conectividad para mostrar ReconnectedBanner y refrescar datos.
  StreamSubscription<bool>? _connectivitySub;

  // ViewModel singleton para el badge de notificaciones no leídas.
  late final NotificationsViewModel _notificationsVm;

  // ViewModel singleton de conversaciones — escuchamos sus cambios para
  // que el badge de mensajes refleje el estado real tras el refresh en
  // segundo plano al abrir la app. El refresh dispara notifyListeners()
  // en el VM y aquí actualizamos `_hasUnreadMessages`.
  late final ConversationsViewModel _conversationsVm;

  // Referencias a handlers de socket para poder desuscribirse sin eliminar otros listeners.
  late final void Function(dynamic) _onSocketMessageReceived;
  late final void Function(dynamic) _onSocketPostUpdated;
  late final void Function(dynamic) _onSocketFeedUpdated;
  late final void Function(dynamic) _onSocketNotificationNew;
  late final void Function(dynamic) _onSocketFcmInvalid;

  // Polling de notificaciones cada 60s como fallback (las notificaciones del cron
  // no tienen evento socket propio).
  Timer? _notificationPollingTimer;

  // Polling del feed de comunidad cada 20s para mantener datos frescos.
  Timer? _feedPollingTimer;

  @override
  void initState() {
    super.initState();
    // Registrar observador del lifecycle de la app para desconectar el
    // socket cuando la app va a background o se cierra. Sin esto, el
    // backend mantendría el socket vivo durante el pingTimeout de
    // socket.io (~45 s default), creería que el receptor está online y
    // enviaría mensajes via `message:received` en lugar de push FCM — el
    // usuario no vería nada porque el proceso Flutter está pausado.
    WidgetsBinding.instance.addObserver(this);

    // Forzar recarga de datos al montar MainTabsPage (ocurre en cada nuevo login).
    sl<PlantsListViewModel>().loadPlants();
    sl<FeedViewModel>().loadFeed();

    // Suscribirse al ViewModel de notificaciones para reflejar cambios en el badge.
    _notificationsVm = sl<NotificationsViewModel>();
    _notificationsVm.addListener(_onNotificationsChanged);
    // Carga inicial del conteo de notificaciones no leídas.
    _notificationsVm.load();

    // Suscribirse al ConversationsViewModel para que el badge de mensajes
    // refleje el estado real tras un refresh en segundo plano. Dispara
    // el refresh inmediato al montar la página (cold start tras splash):
    // si hay mensajes nuevos, el badge aparecerá sin esperar a que el
    // usuario abra la pestaña.
    _conversationsVm = sl<ConversationsViewModel>();
    _conversationsVm.addListener(_onConversationsChanged);
    // ignore: discarded_futures
    _conversationsVm.refresh();

    // Escuchar eventos de socket para actualizar badges, feed y notificaciones.
    // Importante: registramos los listeners ANTES del connect() porque
    // SocketClient los guarda en buffer y los re-aplica al conectar.
    _listenSocketMessages();

    // Abrir la conexión Socket.IO una vez autenticado (sin esto, todos
    // los eventos en tiempo real — chat, post:updated, notification:new,
    // etc. — quedan colgados porque el socket nunca se conecta).
    // El connect() es asíncrono y maneja errores internamente (reconexión
    // automática con backoff); no necesitamos await.
    sl<SocketClient>().connect();

    // Polling de notificaciones cada 60s (fallback para notificaciones del cron sin socket).
    _notificationPollingTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _notificationsVm.load(),
    );

    // Polling del feed cada 20s para mantener datos frescos sin parpadeos.
    _startFeedPolling();

    // Al recuperar conexión: mostrar banner, sincronizar cola y refrescar datos.
    _listenConnectivity();

    // Registrar el fcmToken del dispositivo en el backend tras el login.
    // Si Firebase no está inicializado o el permiso está denegado, el
    // método tolera el error silenciosamente.
    sl<FirebaseMessagingService>().registerToken((token) async {
      try {
        await sl<ApiClient>().put<dynamic>(
          '/users/me/fcm-token',
          data: {'fcmToken': token},
        );
      } catch (_) {
        // Tolerar fallos transitorios: el siguiente login lo reintentará.
      }
    });

    // Limpiar todas las notificaciones push del sistema al entrar a la
    // app (cold start desde splash). Si el usuario abre la app, las
    // cards que llegaron mientras estaba fuera quedan obsoletas —
    // debería ver el chat directamente y la barra del sistema vacía.
    sl<FirebaseMessagingService>().clearAllNotifications();

    // Procesar deep link de notificación que abrió la app con el proceso
    // cerrado. `addPostFrameCallback` garantiza que el Navigator está
    // montado antes de procesar el `initialMessage`; usar un
    // `Future.delayed` arbitrario sería frágil cuando la app tarda
    // (cold start + checkSession + refresh).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sl<FirebaseMessagingService>().consumePendingInitialMessage();
    });
  }

  void _onNotificationsChanged() {
    if (!mounted) return;
    // Diferir setState para evitar "setState during build" si notifyListeners()
    // se dispara durante un frame de construcción activo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  /// Reacciona a cambios del [ConversationsViewModel]: si hay alguna
  /// conversación con mensajes sin leer Y el usuario no está actualmente
  /// en la pestaña Mensajes, encender el badge. Si está en la pestaña,
  /// no tocamos el estado — la apertura local ya limpia el badge (ver
  /// `_onTabSelected`).
  void _onConversationsChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hasUnread = _conversationsVm.hasAnyUnread;
      if (hasUnread && _currentIndex != 2 && !_hasUnreadMessages) {
        setState(() => _hasUnreadMessages = true);
      }
    });
  }

  void _listenSocketMessages() {
    final socket = sl<SocketClient>();

    // Mostrar badge (punto rojo) en pestaña Mensajes al recibir un
    // mensaje nuevo + refrescar la lista de conversaciones (singleton)
    // para que el último mensaje y el unreadCount se vean tanto si la
    // pestaña está abierta como si se abre después.
    _onSocketMessageReceived = (_) {
      if (_currentIndex != 2 && mounted) {
        setState(() => _hasUnreadMessages = true);
      }
      // Refrescar el ConversationsViewModel global — forceRefresh
      // salta la caché de 1 min y el VM notifica a sus listeners
      // (la pestaña Mensajes si está montada, o se aplica al siguiente
      // build cuando se abra). Ignoramos errores para no romper el
      // listener si el backend está temporalmente caído.
      try {
        // ignore: discarded_futures
        sl<ConversationsViewModel>().refresh();
      } catch (_) {}
    };
    socket.on('message:received', _onSocketMessageReceived);

    // Actualizar contadores de likes/comentarios en el feed en tiempo real.
    _onSocketPostUpdated = (data) {
      if (data is Map) {
        final postId        = data['postId']        as String?;
        final likesCount    = data['likesCount']    as int?;
        final commentsCount = data['commentsCount'] as int?;
        if (postId != null && likesCount != null && commentsCount != null) {
          sl<FeedViewModel>().applyPostUpdate(postId, likesCount, commentsCount);
        }
      }
    };
    socket.on('post:updated', _onSocketPostUpdated);

    // Recargar el feed cuando otro usuario crea o elimina un post.
    // Reinicia el polling para evitar doble refresh inmediato.
    _onSocketFeedUpdated = (_) {
      sl<FeedViewModel>().loadFeed(showLoading: false);
      _startFeedPolling();
    };
    socket.on('feed:updated', _onSocketFeedUpdated);

    // Recargar notificaciones cuando llega una nueva vía socket (ej. admin warning, ban).
    _onSocketNotificationNew = (_) {
      _notificationsVm.load();
    };
    socket.on('notification:new', _onSocketNotificationNew);

    // El backend nos avisa cuando nuestro fcmToken cacheado en Firebase
    // quedó inválido (FCM rechazó el envío con
    // `registration-token-not-registered`). Forzamos regeneración
    // borrando el token local + volviendo a registrarlo. Sin esto, el
    // dispositivo seguiría mandando el mismo token roto tras cada login
    // y la cuenta no recibiría push hasta reinstalar.
    _onSocketFcmInvalid = (_) async {
      try {
        await sl<FirebaseMessagingService>().deleteToken();
      } catch (_) {/* silenciar */}
      // Re-registrar el token nuevo en el backend (PUT /users/me/fcm-token).
      await sl<FirebaseMessagingService>().registerToken((token) async {
        try {
          await sl<ApiClient>().put<dynamic>(
            '/users/me/fcm-token',
            data: {'fcmToken': token},
          );
        } catch (_) {/* silenciar */}
      });
    };
    socket.on('fcm:invalid', _onSocketFcmInvalid);
  }

  /// Inicia (o reinicia) el polling del feed cada 20s.
  /// Cancelar el timer anterior evita doble refresh cuando un socket event
  /// ya disparó la recarga.
  void _startFeedPolling() {
    _feedPollingTimer?.cancel();
    _feedPollingTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => sl<FeedViewModel>().loadFeed(showLoading: false),
    );
  }

  void _listenConnectivity() {
    _connectivitySub = sl<ConnectivityService>().onConnectivityChanged.listen((isOnline) {
      if (!isOnline || !mounted) return;
      // Sin cola offline: al reconectar mostramos el toast de reconexión
      // y refrescamos los listados (plantas + feed) — los datos pueden
      // haber cambiado mientras estuvimos sin red.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ReconnectedBanner.show(context);
        sl<PlantsListViewModel>().loadPlants();
        sl<FeedViewModel>().loadFeed();
      });
    });
  }

  /// Contenido del body según la pestaña activa o el perfil inline abierto.
  Widget _buildBody() {
    // Si hay un perfil de usuario abierto inline, mostrarlo en lugar de la pestaña.
    if (_userProfileArgs != null) {
      final args = _userProfileArgs!;
      return UserProfilePage(
        userId:      args['userId']      as String,
        authorName:  args['authorName']  as String,
        authorPhoto: args['authorPhoto'] as String?,
      );
    }

    return switch (_currentIndex) {
      // Estos se montan/desmontan en cada visita para tener datos frescos.
      2 => const ConversationsListPage(),
      3 => const NotificationsPage(),
      // Calendario (4): se mantiene vivo para conservar estado del mes seleccionado.
      4 => _calendarPage,
      5 => const MyProfilePage(),
      // Plantas (0) y Comunidad (1) viven en el IndexedStack.
      _ => IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
    };
  }

  // ─── Banners superiores (offline + suspensión) ────────────────────────────

  /// Construye los banners que aparecen sobre el contenido (offline + ban).
  Widget _buildTopBanners() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Banner visible solo cuando no hay conexión.
        const OfflineBanner(),
        // Banner de suspensión temporal si el usuario está baneado.
        Builder(builder: (ctx) {
          final bannedUntil = ctx.select<AuthViewModel, DateTime?>(
            (vm) => vm.currentUser?.bannedUntil,
          );
          if (bannedUntil == null || bannedUntil.isBefore(DateTime.now())) {
            return const SizedBox.shrink();
          }
          final formatted = DateFormat('dd/MM/yyyy').format(bannedUntil);
          return Container(
            width:   double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color:   AppColors.warning.withValues(alpha: 0.15),
            child:   Row(
              children: [
                const Icon(Icons.block_rounded, color: AppColors.warning, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tu cuenta está suspendida hasta el $formatted',
                    style: const TextStyle(
                      color:    AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─── NavigationRail (web / desktop ≥ 600px) ────────────────────────────────

  /// Icono con badge para el rail. Reutiliza la misma lógica de badges que el
  /// BottomNav pero con tamaño ajustado al rail.
  Widget _railIcon(IconData icon, {bool badge = false, int? count}) {
    Widget child = Icon(icon);
    if (badge) {
      child = Badge(isLabelVisible: true, child: child);
    } else if (count != null && count > 0) {
      child = Badge(
        isLabelVisible: true,
        label: Text('$count'),
        child: child,
      );
    }
    return child;
  }

  /// Construye el NavigationRail vertical para web/desktop, o variante
  /// compacta para landscape móvil (sin labels).
  ///
  /// En compact, el padding vertical de cada destino se calcula
  /// dinámicamente según la altura disponible (parámetro [availableHeight]):
  /// el espacio sobrante tras colocar 6 iconos se reparte como separación
  /// entre destinos, dejando margen superior/inferior gracias a
  /// `groupAlignment: 0.0`. Si no hay altura suficiente cae a 0.
  Widget _buildNavigationRail({bool compact = false, double? availableHeight}) {
    EdgeInsets destPadding;
    if (compact) {
      // Altura aproximada por destino sin padding extra: ~52dp
      // (icon 26 + padding interno del rail).
      const perDestApprox = 52.0;
      const dests         = 6;
      const reservedMargin = 24.0; // garantiza margen sup+inf mínimo.
      final h = availableHeight ?? 0;
      final extra = h - (perDestApprox * dests) - reservedMargin;
      if (extra > 0) {
        // Repartir extra entre 12 segmentos (top+bottom × 6 destinos).
        // Acotado a 10dp por segmento para evitar separaciones excesivas
        // en pantallas muy altas (ej. tablet landscape).
        final padV = (extra / 12).clamp(0.0, 10.0);
        destPadding = EdgeInsets.symmetric(vertical: padV);
      } else {
        destPadding = EdgeInsets.zero;
      }
    } else {
      destPadding = const EdgeInsets.symmetric(vertical: 8);
    }
    return NavigationRail(
      selectedIndex:         _currentIndex,
      onDestinationSelected: _onTabSelected,
      backgroundColor:       Colors.white,
      indicatorColor:        AppColors.primary.withValues(alpha: 0.15),
      labelType:             compact
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      groupAlignment:        0.0,
      minWidth:              compact ? 56 : 80,
      selectedIconTheme:     const IconThemeData(color: AppColors.primary),
      unselectedIconTheme:   const IconThemeData(color: AppColors.textSecondary),
      selectedLabelTextStyle:    const TextStyle(
        color:      AppColors.primary,
        fontSize:   12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: const TextStyle(
        color:    AppColors.textSecondary,
        fontSize: 12,
      ),
      destinations: [
        NavigationRailDestination(
          icon:         const Icon(Icons.eco_outlined),
          selectedIcon: const Icon(Icons.eco_rounded),
          label:        const Text('Plantas'),
          padding:      destPadding,
        ),
        NavigationRailDestination(
          icon:         const Icon(Icons.people_outline),
          selectedIcon: const Icon(Icons.people_rounded),
          label:        const Text('Comunidad'),
          padding:      destPadding,
        ),
        NavigationRailDestination(
          icon:         _railIcon(Icons.chat_bubble_outline_rounded, badge: _hasUnreadMessages),
          selectedIcon: _railIcon(Icons.chat_bubble_rounded, badge: _hasUnreadMessages),
          label:        const Text('Mensajes'),
          padding:      destPadding,
        ),
        NavigationRailDestination(
          icon:         _railIcon(Icons.notifications_outlined, count: _notificationsVm.unreadCount),
          selectedIcon: _railIcon(Icons.notifications_rounded, count: _notificationsVm.unreadCount),
          label:        const Text('Avisos'),
          padding:      destPadding,
        ),
        NavigationRailDestination(
          icon:         const Icon(Icons.calendar_month_outlined),
          selectedIcon: const Icon(Icons.calendar_month_rounded),
          label:        const Text('Calendario'),
          padding:      destPadding,
        ),
        NavigationRailDestination(
          icon:         const Icon(Icons.person_outline_rounded),
          selectedIcon: const Icon(Icons.person_rounded),
          label:        const Text('Perfil'),
          padding:      destPadding,
        ),
      ],
    );
  }

  // ─── BottomNavigationBar (móvil < 600px) ───────────────────────────────────

  /// Construye el NavigationBar inferior para pantallas estrechas (móvil).
  ///
  /// El widget se envuelve en `NavigationBarTheme` con valores explícitos
  /// para que el color de iconos y labels NO dependa del modo del sistema.
  /// Sin esto, con tema oscuro del sistema activo en Android físico, los
  /// iconos heredaban color blanco (defaults M3) sobre el fondo blanco
  /// forzado por el widget → invisibles.
  Widget _buildBottomNavigationBar() {
    final l10n = AppLocalizations.of(context);
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: AppColors.backgroundLight,
        indicatorColor:  AppColors.primary.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 26);
          }
          return const IconThemeData(color: AppColors.textSecondary, size: 26);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color:      AppColors.primary,
              fontSize:   12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color:    AppColors.textSecondary,
            fontSize: 12,
          );
        }),
      ),
      child: NavigationBar(
        selectedIndex:         _currentIndex,
        onDestinationSelected: _onTabSelected,
        backgroundColor:       AppColors.backgroundLight,
        indicatorColor:        AppColors.primary.withValues(alpha: 0.15),
        shadowColor:           AppColors.primary.withValues(alpha: 0.12),
        elevation:             4,
        height:                72,
        labelBehavior:         NavigationDestinationLabelBehavior.alwaysHide,
        destinations: [
          NavigationDestination(
            icon:         const Icon(Icons.eco_outlined),
            selectedIcon: const Icon(Icons.eco_rounded),
            label:        l10n.tabPlants,
          ),
          NavigationDestination(
            icon:         const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people_rounded),
            label:        l10n.tabCommunity,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _hasUnreadMessages,
              child:          const Icon(Icons.chat_bubble_outline_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: _hasUnreadMessages,
              child:          const Icon(Icons.chat_bubble_rounded),
            ),
            label:        l10n.tabMessages,
            tooltip:      _hasUnreadMessages
                ? '${l10n.tabMessages} — no leídos'
                : l10n.tabMessages,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _notificationsVm.unreadCount > 0,
              label:          Text('${_notificationsVm.unreadCount}'),
              child:          const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: _notificationsVm.unreadCount > 0,
              label:          Text('${_notificationsVm.unreadCount}'),
              child:          const Icon(Icons.notifications_rounded),
            ),
            label:        l10n.tabNotifications,
            tooltip:      _notificationsVm.unreadCount > 0
                ? '${l10n.tabNotifications} — ${_notificationsVm.unreadCount} no leídos'
                : l10n.tabNotifications,
          ),
          NavigationDestination(
            icon:         const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month_rounded),
            label:        l10n.tabCalendar,
          ),
          NavigationDestination(
            icon:         const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label:        l10n.tabProfile,
          ),
        ],
      ),
    );
  }

  // ─── Build principal ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Permitir pop del sistema solo si no hay perfil inline abierto.
      canPop: _userProfileArgs == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _userProfileArgs != null) {
          setState(() => _userProfileArgs = null);
        }
      },
      child: MainTabsScope(
        pushUserProfile: (args) => setState(() => _userProfileArgs = args),
        popUserProfile:  ()     => setState(() => _userProfileArgs = null),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Decisión de layout (orden importa):
            //  1. Web → siempre rail con labels (UX desktop).
            //  2. Móvil landscape → rail compacto sin labels (los móviles
            //     modernos superan 600dp en landscape, NO se debe usar
            //     únicamente maxWidth como discriminador).
            //  3. Móvil portrait → BottomNavigationBar sin labels.
            //  4. Tablet portrait (shortestSide ≥ 600) → rail con labels.
            final orientation     = MediaQuery.of(context).orientation;
            final shortestSide    = MediaQuery.of(context).size.shortestSide;
            final isMobileDevice  = !kIsWeb && shortestSide < 600;

            if (kIsWeb || (!isMobileDevice && orientation == Orientation.portrait)) {
              return Scaffold(
                body: Row(
                  children: [
                    _buildNavigationRail(),
                    const VerticalDivider(thickness: 1, width: 1),
                    Expanded(
                      child: Column(
                        children: [
                          _buildTopBanners(),
                          Expanded(child: _buildBody()),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            // Móvil/tablet en landscape → NavigationRail compacto pegado a
            // la izquierda. El padding entre destinos se calcula
            // dinámicamente según la altura disponible (ver
            // _buildNavigationRail) para garantizar separación uniforme y
            // margen superior/inferior sin overflow.
            if (orientation == Orientation.landscape) {
              return Scaffold(
                body: SafeArea(
                  child: Row(
                    children: [
                      LayoutBuilder(
                        builder: (ctx, c) => _buildNavigationRail(
                          compact:         true,
                          availableHeight: c.maxHeight,
                        ),
                      ),
                      const VerticalDivider(thickness: 1, width: 1),
                      Expanded(
                        child: Column(
                          children: [
                            _buildTopBanners(),
                            Expanded(child: _buildBody()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Portrait móvil: el Scaffold de Material 3 ya gestiona el safe
            // area inferior del NavigationBar automáticamente. Envolverlo en
            // SafeArea(bottom:true) o usar extendBody:false con edge-to-edge
            // duplicaba el padding y producía la franja blanca "fantasma"
            // bajo el nav reportada en dispositivo físico.
            return Scaffold(
              body: Column(
                children: [
                  _buildTopBanners(),
                  Expanded(child: _buildBody()),
                ],
              ),
              bottomNavigationBar: _buildBottomNavigationBar(),
            );
          },
        ),
      ),
    );
  }

  void _onTabSelected(int index) {
    // Cerrar perfil inline si estaba abierto al cambiar de pestaña.
    if (_userProfileArgs != null) {
      setState(() {
        _userProfileArgs = null;
        _currentIndex    = index;
      });
      return;
    }
    // Refrescar datos al activar cada pestaña (solo si cambia de tab).
    // Notificaciones (3) y Perfil (5) se remontan en cada visita — cargan solos.
    if (index != _currentIndex) {
      if (index == 0) sl<PlantsListViewModel>().loadPlants();
      if (index == 1) sl<FeedViewModel>().loadFeed();
    }
    // Limpiar badge al entrar en la pestaña de Mensajes.
    if (index == 2 && _hasUnreadMessages) {
      setState(() {
        _hasUnreadMessages = false;
        _currentIndex      = index;
      });
    } else {
      setState(() => _currentIndex = index);
    }
  }

  @override
  void dispose() {
    // Desregistrar listeners al destruir el widget (con referencia para no eliminar otros).
    WidgetsBinding.instance.removeObserver(this);
    _notificationsVm.removeListener(_onNotificationsChanged);
    _conversationsVm.removeListener(_onConversationsChanged);
    _notificationPollingTimer?.cancel();
    _feedPollingTimer?.cancel();
    _connectivitySub?.cancel();
    final socket = sl<SocketClient>();
    socket.off('message:received', _onSocketMessageReceived);
    socket.off('post:updated', _onSocketPostUpdated);
    socket.off('feed:updated', _onSocketFeedUpdated);
    socket.off('notification:new', _onSocketNotificationNew);
    socket.off('fcm:invalid', _onSocketFcmInvalid);
    super.dispose();
  }

  /// Gestiona el socket según el lifecycle de la app.
  ///
  /// - `resumed`: la app vuelve a primer plano → reconectar socket si no
  ///   estaba conectado. Los listeners en buffer se re-aplican automáticamente.
  /// - `paused` / `inactive` / `hidden` / `detached`: la app se va a background
  ///   o se cierra → desconectar el socket EXPLÍCITAMENTE. Sin esto, el
  ///   backend mantendría el socket vivo hasta el pingTimeout de socket.io
  ///   (~45 s) creyendo que el receptor estaba online; los mensajes se
  ///   enviarían via `message:received` y el proceso pausado nunca los
  ///   renderizaría — el usuario no recibiría push de chats con la app
  ///   cerrada.
  ///
  /// El push FCM SÍ fuerza el wake-up del proceso (vía
  /// `flutter_local_notifications` + handlers de `firebase_messaging`),
  /// por eso la solución es asegurar que el backend vea OFFLINE al
  /// receptor cuando la app no está en foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final socket = sl<SocketClient>();
    switch (state) {
      case AppLifecycleState.resumed:
        if (!socket.isConnected) socket.connect();
        // Limpiar la barra de notificaciones al volver a primer plano:
        // las cards de chat que llegaron mientras la app estaba en
        // background quedan obsoletas — el usuario ya va a revisar el
        // contenido. El servidor también reseteará el dedup
        // (lastChatPushTitle = null) cuando el socket conecte arriba.
        sl<FirebaseMessagingService>().clearAllNotifications();
        // Refrescar conversaciones en segundo plano para que el badge de
        // mensajes refleje cualquier mensaje llegado mientras la app
        // estaba en background. El listener `_onConversationsChanged`
        // actualizará el badge si hay unreadCount > 0 en alguna
        // conversación.
        // ignore: discarded_futures
        _conversationsVm.refresh();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        if (socket.isConnected) socket.disconnect();
        break;
    }
  }
}
