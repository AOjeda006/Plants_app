/// @file app_router.dart
/// @description Router de navegación de la app con Navigator 1.0 (named routes).
/// Define todas las rutas de auth, plantas, especies, comunidad y chat.
/// @module Core
/// @layer Presentation
library;

import 'package:flutter/material.dart';

import '../../domain/entities/plant.dart';
import '../../domain/entities/plant_species.dart';
import '../../domain/entities/user.dart';
import '../pages/account_management_page.dart';
import '../pages/admin/admin_dashboard_page.dart';
import '../pages/admin/deleted_items_page.dart';
import '../pages/admin/reports_page.dart';
import '../pages/edit_profile_page.dart';
import '../pages/main_tabs_page.dart';
import '../pages/my_profile_page.dart';
import '../pages/settings_page.dart';
import '../pages/chat_page.dart';
import '../pages/community_feed_page.dart';
import '../pages/conversations_list_page.dart';
import '../pages/create_post_page.dart';
import '../pages/login_page.dart';
import '../pages/plant_detail_page.dart';
import '../pages/calendar_page.dart';
import '../pages/plant_form_page.dart';
import '../pages/post_detail_page.dart';
import '../pages/register_page.dart';
import '../pages/report_form_page.dart';
import '../pages/species_info_page.dart';
import '../pages/splash_page.dart';
import '../pages/user_profile_page.dart';
import '../pages/welcome_page.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// RUTAS
// ═══════════════════════════════════════════════════════════════════════════════

/// Nombres de rutas de la aplicación. Usar siempre estas constantes en lugar
/// de literales para evitar typos y facilitar refactoring.
abstract final class AppRoutes {
  // ─── Auth ─────────────────────────────────────────────────────────────────

  /// Splash / verificación de sesión.
  static const String splash         = '/';

  /// Página de login.
  static const String login          = '/login';

  /// Página de registro.
  static const String register       = '/register';

  /// Onboarding post-registro.
  static const String welcome        = '/welcome';

  // ─── Plantas ──────────────────────────────────────────────────────────────

  /// Lista de plantas del usuario (pantalla home principal).
  /// Sin argumentos.
  static const String home          = '/home';

  /// Detalle de una planta.
  /// Argumento: [String] plantId.
  static const String plantDetail   = '/plants/detail';

  /// Formulario de creación de planta.
  /// Sin argumentos.
  static const String plantCreate   = '/plants/create';

  /// Formulario de edición de planta.
  /// Argumento: [Plant] planta a editar.
  static const String plantEdit     = '/plants/edit';

  /// Información de una especie (modal/página completa).
  /// Argumento: [PlantSpecies] o [String] speciesName si solo se tiene el nombre.
  static const String speciesInfo   = '/species/info';

  /// Búsqueda rápida de especie (acceso desde AppBar de la lista).
  /// Sin argumentos.
  static const String speciesSearch = '/species/search';

  // ─── Comunidad ────────────────────────────────────────────────────────────

  /// Feed de la comunidad.
  /// Sin argumentos.
  static const String communityFeed = '/community';

  /// Detalle de un post.
  /// Argumento: [String] postId.
  static const String postDetail    = '/community/post';

  /// Crear nuevo post.
  /// Sin argumentos.
  static const String createPost    = '/community/create';

  /// Perfil de un usuario ajeno.
  /// Argumento: [Map] con keys 'userId', 'authorName', 'authorPhoto'?.
  static const String userProfile   = '/community/profile';

  // ─── Chat ─────────────────────────────────────────────────────────────────

  /// Lista de conversaciones del usuario.
  /// Sin argumentos.
  static const String conversations = '/conversations';

  /// Chat 1:1 con un participante.
  /// Argumento: [Map] con keys 'conversationId', 'participantName',
  /// 'participantPhoto'? y 'currentUserId'.
  static const String chat          = '/conversations/chat';

  // ─── Perfil propio ────────────────────────────────────────────────────────

  /// Perfil propio del usuario autenticado.
  static const String profile        = '/profile';

  /// Edición del perfil propio. Argumento: [User] usuario actual.
  static const String profileEdit    = '/profile/edit';

  // ─── Ajustes ──────────────────────────────────────────────────────────────

  /// Pantalla de ajustes (notificaciones, unidades, privacidad).
  static const String settings       = '/settings';

  /// Gestión de cuenta (contraseña, exportar datos, eliminar cuenta).
  static const String settingsAccount = '/settings/account';

  /// Formulario de reporte de incidencia (cualquier usuario autenticado).
  static const String reportIncident  = '/report-incident';

  // ─── Admin ────────────────────────────────────────────────────────────────

  /// Panel de administración principal.
  static const String admin          = '/admin';

  /// Calendario de recordatorios de plantas.
  static const String calendar       = '/plants/calendar';

  /// Reportes de la plataforma.
  static const String adminReports   = '/admin/reports';

  /// Elementos eliminados (soft-delete).
  static const String adminDeleted   = '/admin/deleted';
}

// ═══════════════════════════════════════════════════════════════════════════════
// APP ROUTER
// ═══════════════════════════════════════════════════════════════════════════════

/// Proporciona el mapa de rutas para [MaterialApp.routes] y el
/// generador de rutas para rutas con argumentos ([MaterialApp.onGenerateRoute]).
abstract final class AppRouter {

  /// Mapa de rutas estáticas (sin argumentos de navegación).
  static Map<String, WidgetBuilder> get routes => {
    AppRoutes.splash:         (_) => const SplashPage(),
    AppRoutes.login:          (_) => const LoginPage(),
    AppRoutes.register:       (_) => const RegisterPage(),
    AppRoutes.welcome:        (_) => const WelcomePage(),
    // Shell principal con barra de navegación inferior.
    // /home → MainTabsPage que contiene Plantas, Comunidad, Mensajes, Perfil.
    AppRoutes.home:           (_) => const MainTabsPage(),
    AppRoutes.plantCreate:    (_) => const PlantFormPage(),
    AppRoutes.calendar:       (_) => const CalendarPage(),
    AppRoutes.speciesSearch:  (_) => const PlantFormPage(),
    // Comunidad — rutas sin argumentos (accesibles también por push desde otras pantallas):
    AppRoutes.communityFeed:  (_) => const CommunityFeedPage(),
    AppRoutes.createPost:     (_) => const CreatePostPage(),
    // Chat — rutas sin argumentos:
    AppRoutes.conversations:  (_) => const ConversationsListPage(),
    // Perfil y ajustes — rutas sin argumentos:
    AppRoutes.profile:         (_) => const MyProfilePage(),
    AppRoutes.settings:        (_) => const SettingsPage(),
    AppRoutes.settingsAccount:  (_) => const AccountManagementPage(),
    // reportIncident usa onGenerateRoute para soportar targetId/type opcionales.
    // Admin — rutas sin argumentos:
    AppRoutes.admin:           (_) => const AdminDashboardPage(),
    AppRoutes.adminReports:    (_) => const ReportsPage(),
    AppRoutes.adminDeleted:    (_) => const DeletedItemsPage(),
  };

  /// Ruta inicial de la app (siempre splash para verificar sesión).
  static const String initialRoute = AppRoutes.splash;

  /// Generador para rutas con argumentos dinámicos.
  /// Se invoca cuando la ruta no está en el mapa estático [routes].
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {

      // ── Detalle de planta — arg: String plantId ────────────────────────
      case AppRoutes.plantDetail:
        final plantId = settings.arguments as String;
        return MaterialPageRoute<dynamic>(
          builder:  (_) => PlantDetailPage(plantId: plantId),
          settings: settings,
        );

      // ── Edición de planta — arg: Plant ────────────────────────────────
      case AppRoutes.plantEdit:
        final plant = settings.arguments as Plant;
        return MaterialPageRoute<dynamic>(
          builder:  (_) => PlantFormPage(plant: plant),
          settings: settings,
        );

      // ── Info de especie — arg: PlantSpecies o String (nombre) ─────────
      case AppRoutes.speciesInfo:
        if (settings.arguments is PlantSpecies) {
          return MaterialPageRoute<dynamic>(
            builder:  (_) => SpeciesInfoPage(
              species: settings.arguments as PlantSpecies,
            ),
            settings: settings,
          );
        }
        final speciesName = settings.arguments as String? ?? '';
        return MaterialPageRoute<dynamic>(
          builder:  (_) => SpeciesInfoPage(speciesName: speciesName),
          settings: settings,
        );

      // ── Detalle de post — arg: String postId | Map {postId, reportTicket?, reportedCommentId?} ──
      case AppRoutes.postDetail:
        final args = settings.arguments;
        final String postId;
        final String? reportTicket;
        final String? reportedCommentId;
        if (args is Map<String, dynamic>) {
          postId             = args['postId']             as String;
          reportTicket       = args['reportTicket']       as String?;
          reportedCommentId  = args['reportedCommentId']  as String?;
        } else {
          postId             = args as String;
          reportTicket       = null;
          reportedCommentId  = null;
        }
        return MaterialPageRoute<dynamic>(
          builder:  (_) => PostDetailPage(
            postId:             postId,
            reportTicket:       reportTicket,
            reportedCommentId:  reportedCommentId,
          ),
          settings: settings,
        );

      // ── Perfil de usuario — arg: Map<String, dynamic> ─────────────────
      case AppRoutes.userProfile:
        final args        = settings.arguments as Map<String, dynamic>;
        final userId      = args['userId']      as String;
        final authorName  = args['authorName']  as String;
        final authorPhoto = args['authorPhoto'] as String?;
        return MaterialPageRoute<dynamic>(
          builder: (_) => UserProfilePage(
            userId:      userId,
            authorName:  authorName,
            authorPhoto: authorPhoto,
          ),
          settings: settings,
        );

      // ── Chat 1:1 — arg: Map<String, dynamic> ──────────────────────────
      case AppRoutes.chat:
        final args                 = settings.arguments as Map<String, dynamic>;
        final conversationId       = args['conversationId']       as String;
        final participantName      = args['participantName']       as String;
        final participantPhoto     = args['participantPhoto']      as String?;
        final currentUserId        = args['currentUserId']         as String;
        final isParticipantDeleted = args['isParticipantDeleted']  as bool? ?? false;
        return MaterialPageRoute<dynamic>(
          builder: (_) => ChatPage(
            conversationId:       conversationId,
            participantName:      participantName,
            participantPhoto:     participantPhoto,
            currentUserId:        currentUserId,
            isParticipantDeleted: isParticipantDeleted,
          ),
          settings: settings,
        );

      // ── Edición de perfil — arg: User ─────────────────────────────────
      case AppRoutes.profileEdit:
        final user = settings.arguments as User;
        return MaterialPageRoute<dynamic>(
          builder:  (_) => EditProfilePage(user: user),
          settings: settings,
        );

      // ── Reporte de incidencia — arg: Map<String,dynamic>? (targetId?, type?) ─
      case AppRoutes.reportIncident:
        final args     = settings.arguments as Map<String, dynamic>?;
        final targetId = args?['targetId'] as String?;
        final type     = args?['type']     as String?;
        return MaterialPageRoute<dynamic>(
          builder:  (_) => ReportFormPage(targetId: targetId, type: type),
          settings: settings,
        );

      default:
        return null; // null → usa el mapa de routes estáticas.
    }
  }

  /// Página 404 para rutas desconocidas.
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        body: Center(
          child: Text('Ruta no encontrada: ${settings.name}'),
        ),
      ),
    );
  }
}
