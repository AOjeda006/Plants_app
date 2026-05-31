/// @file post_detail_page_test.dart
/// @description Tests de widget para PostDetailPage.
/// Verifica: renderizado inicial (loading), visualización del autor tras carga,
/// y navegación condicional al perfil del autor (MyProfilePage vs UserProfilePage)
/// según si el userId del post coincide con el usuario autenticado.
/// @module Community
/// @layer Presentation
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:plants_app/core/errors/app_error.dart';
import 'package:plants_app/domain/entities/comment.dart';
import 'package:plants_app/domain/entities/post.dart';
import 'package:plants_app/domain/entities/user.dart';
import 'package:plants_app/domain/interfaces/usecases/auth/i_login_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/auth/i_logout_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/auth/i_refresh_token_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/auth/i_register_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/auth/i_validate_token_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/community/i_create_comment_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/community/i_get_post_by_id_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/community/i_get_post_comments_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/community/i_like_post_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/community/i_unlike_post_use_case.dart';
import 'package:plants_app/domain/dtos/auth/login_request_dto.dart';
import 'package:plants_app/domain/dtos/auth/register_request_dto.dart';
import 'package:plants_app/core/network/socket_client.dart';
import 'package:plants_app/presentation/pages/post_detail_page.dart';
import 'package:plants_app/presentation/routes/app_router.dart';
import 'package:plants_app/presentation/viewmodels/auth/auth_viewmodel.dart';
import 'package:plants_app/presentation/viewmodels/community/post_viewmodel.dart';

// ─── Mocks de use cases de comunidad ─────────────────────────────────────────

class _StubGetPostById implements IGetPostByIdUseCase {
  final Post post;
  _StubGetPostById(this.post);

  @override
  Future<Post> execute(String postId) async => post;
}

class _StubGetComments implements IGetPostCommentsUseCase {
  @override
  Future<List<Comment>> execute(String postId) async => [];
}

class _StubCreateComment implements ICreateCommentUseCase {
  @override
  Future<Comment> execute(String postId, String content) async =>
      throw AppError.server('no implementado en test');
}

class _StubLikePost implements ILikePostUseCase {
  @override
  Future<void> execute(String postId) async {}
}

class _StubUnlikePost implements IUnlikePostUseCase {
  @override
  Future<void> execute(String postId) async {}
}

// ─── Stub de SocketClient (para el listener post:updated de _PostDetailBodyState) ─

class _StubSocketClient extends SocketClient {
  _StubSocketClient() : super(tokenProvider: () async => null);

  @override
  void on(String event, void Function(dynamic data) handler) {}

  @override
  void off(String event, [void Function(dynamic data)? handler]) {}
}

// ─── Mocks de auth (para AuthViewModel requerido por _AuthorHeader) ──────────

class _StubLogin implements ILoginUseCase {
  @override
  Future<({User user, String token})> execute(LoginRequestDto dto) async =>
      throw UnimplementedError();
}

class _StubRegister implements IRegisterUseCase {
  @override
  Future<({User user, String token})> execute(RegisterRequestDto dto) async =>
      throw UnimplementedError();
}

class _StubRefreshToken implements IRefreshTokenUseCase {
  @override
  Future<bool> execute({double refreshThresholdDays = 7.0}) async => false;
}

class _StubLogout implements ILogoutUseCase {
  @override
  Future<void> execute() async {}
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

final _sl = GetIt.instance;

final _fixedDate = DateTime.utc(2026, 3, 17, 10);

/// Post de prueba cuyo autor tiene userId 'author-001'.
Post _makePost({String userId = 'author-001'}) => Post(
      id:            'post-001',
      userId:        userId,
      authorName:    'Flora García',
      content:       'Mi Monstera está creciendo muy bien.',
      likesCount:    3,
      commentsCount: 0,
      createdAt:     _fixedDate,
      updatedAt:     _fixedDate,
      isLikedByMe:   false,
    );


// ─── NavigatorObserver para tests de navegación ───────────────────────────────

class _RouteObserver extends NavigatorObserver {
  final List<String?> pushedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route.settings.name);
  }
}

// ─── Stub de IValidateTokenUseCase que devuelve usuario fijo ────────────────

class _StubValidateWithUser implements IValidateTokenUseCase {
  final User user;
  _StubValidateWithUser(this.user);

  @override
  Future<User> execute() async => user;
}

/// Crea un User de dominio (Flutter) con el id dado.
User _makeUser({String id = 'current-user-001'}) => User(
      id:        id,
      name:      'Usuario Test',
      email:     'test@example.com',
      role:      'user',
      createdAt: _fixedDate,
    );

/// Inicializa un AuthViewModel con el usuario ya cargado (llama checkSession).
Future<AuthViewModel> _makeAuthVmWithUser(User user) async {
  final vm = AuthViewModel(
    loginUseCase:          _StubLogin(),
    registerUseCase:       _StubRegister(),
    validateTokenUseCase:  _StubValidateWithUser(user),
    logoutUseCase:         _StubLogout(),
    refreshTokenUseCase:   _StubRefreshToken(),
  );
  // checkSession() llama a _validateTokenUseCase.execute() y asigna _currentUser.
  await vm.checkSession();
  return vm;
}

/// Envuelve el widget con AuthViewModel y un MaterialApp con las rutas necesarias.
Widget _wrap({
  required Widget child,
  required AuthViewModel authVm,
  required _RouteObserver observer,
}) =>
    ChangeNotifierProvider<AuthViewModel>.value(
      value: authVm,
      child: MaterialApp(
        navigatorObservers: [observer],
        routes: {
          // Rutas destino para verificar navegación.
          AppRoutes.profile:     (_) => const Scaffold(body: Text('MyProfilePage')),
          AppRoutes.userProfile: (_) => const Scaffold(body: Text('UserProfilePage')),
        },
        home: child,
      ),
    );

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_ES', null);
  });

  setUp(() async {
    await _sl.reset();
    // _PostDetailBodyState.initState() llama a sl<SocketClient>().on('post:updated').
    _sl.registerSingleton<SocketClient>(_StubSocketClient());
  });

  tearDownAll(() async => _sl.reset());

  // ── Renderizado inicial ───────────────────────────────────────────────────────

  group('Renderizado', () {
    testWidgets('muestra el título "Publicación" en el AppBar', (tester) async {
      final post = _makePost();
      _sl.registerFactory<PostViewModel>(
        () => PostViewModel(
          getPostByIdUseCase:     _StubGetPostById(post),
          getPostCommentsUseCase: _StubGetComments(),
          createCommentUseCase:   _StubCreateComment(),
          likePostUseCase:        _StubLikePost(),
          unlikePostUseCase:      _StubUnlikePost(),
        ),
      );
      final authVm   = await _makeAuthVmWithUser(_makeUser());
      final observer = _RouteObserver();

      await tester.pumpWidget(_wrap(
        child:    const PostDetailPage(postId: 'post-001'),
        authVm:   authVm,
        observer: observer,
      ));
      await tester.pump();

      expect(find.text('Publicación'), findsOneWidget);
    });

    testWidgets('muestra el nombre del autor cuando el post ha cargado', (tester) async {
      final post = _makePost();
      _sl.registerFactory<PostViewModel>(
        () => PostViewModel(
          getPostByIdUseCase:     _StubGetPostById(post),
          getPostCommentsUseCase: _StubGetComments(),
          createCommentUseCase:   _StubCreateComment(),
          likePostUseCase:        _StubLikePost(),
          unlikePostUseCase:      _StubUnlikePost(),
        ),
      );
      final authVm   = await _makeAuthVmWithUser(_makeUser());
      final observer = _RouteObserver();

      await tester.pumpWidget(_wrap(
        child:    const PostDetailPage(postId: 'post-001'),
        authVm:   authVm,
        observer: observer,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Flora García'), findsOneWidget);
    });

    testWidgets('muestra el contenido del post tras la carga', (tester) async {
      final post = _makePost();
      _sl.registerFactory<PostViewModel>(
        () => PostViewModel(
          getPostByIdUseCase:     _StubGetPostById(post),
          getPostCommentsUseCase: _StubGetComments(),
          createCommentUseCase:   _StubCreateComment(),
          likePostUseCase:        _StubLikePost(),
          unlikePostUseCase:      _StubUnlikePost(),
        ),
      );
      final authVm   = await _makeAuthVmWithUser(_makeUser());
      final observer = _RouteObserver();

      await tester.pumpWidget(_wrap(
        child:    const PostDetailPage(postId: 'post-001'),
        authVm:   authVm,
        observer: observer,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Mi Monstera está creciendo muy bien.'), findsOneWidget);
    });
  });

  // ── Guard: autor eliminado ────────────────────────────────────────────────────

  group('Guard "Usuario eliminado"', () {
    testWidgets(
        'tap en autor "Usuario eliminado" muestra SnackBar y no navega',
        (tester) async {
      // Post cuyo autor ya no existe (soft-deleted).
      final post = Post(
        id:            'post-del',
        userId:        'deleted-user',
        authorName:    'Usuario eliminado',
        content:       'Contenido huérfano',
        likesCount:    0,
        commentsCount: 0,
        createdAt:     _fixedDate,
        updatedAt:     _fixedDate,
        isLikedByMe:   false,
      );

      _sl.registerFactory<PostViewModel>(
        () => PostViewModel(
          getPostByIdUseCase:     _StubGetPostById(post),
          getPostCommentsUseCase: _StubGetComments(),
          createCommentUseCase:   _StubCreateComment(),
          likePostUseCase:        _StubLikePost(),
          unlikePostUseCase:      _StubUnlikePost(),
        ),
      );
      final authVm   = await _makeAuthVmWithUser(_makeUser());
      final observer = _RouteObserver();

      await tester.pumpWidget(_wrap(
        child:    const PostDetailPage(postId: 'post-del'),
        authVm:   authVm,
        observer: observer,
      ));
      await tester.pumpAndSettle();

      // Pulsar el ListTile del autor (_AuthorHeader).
      await tester.tap(find.byType(ListTile).first);
      await tester.pump(); // procesa el SnackBar

      // Debe mostrar el SnackBar de aviso.
      expect(find.text('Este usuario ya no existe'), findsOneWidget);

      // No debe haber navegado a ninguna ruta de perfil.
      expect(observer.pushedRoutes, isNot(contains(AppRoutes.profile)));
      expect(observer.pushedRoutes, isNot(contains(AppRoutes.userProfile)));
    });
  });

  // ── Navegación al perfil del autor ────────────────────────────────────────────

  group('Navegación al perfil del autor', () {
    testWidgets(
        'pulsar el autor navega a MyProfilePage si el post es del usuario actual',
        (tester) async {
      // El post y el usuario autenticado tienen el mismo userId.
      final currentUser = _makeUser(id: 'user-me');
      final post        = _makePost(userId: 'user-me');

      _sl.registerFactory<PostViewModel>(
        () => PostViewModel(
          getPostByIdUseCase:     _StubGetPostById(post),
          getPostCommentsUseCase: _StubGetComments(),
          createCommentUseCase:   _StubCreateComment(),
          likePostUseCase:        _StubLikePost(),
          unlikePostUseCase:      _StubUnlikePost(),
        ),
      );
      final authVm   = await _makeAuthVmWithUser(currentUser);
      final observer = _RouteObserver();

      await tester.pumpWidget(_wrap(
        child:    const PostDetailPage(postId: 'post-001'),
        authVm:   authVm,
        observer: observer,
      ));
      await tester.pumpAndSettle();

      // Pulsar el ListTile del autor (_AuthorHeader).
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      // Debe navegar a la ruta de perfil propio.
      expect(observer.pushedRoutes, contains(AppRoutes.profile));
    });

    testWidgets(
        'pulsar el autor navega a UserProfilePage si el post es de otro usuario',
        (tester) async {
      // El post es de 'author-001', pero el usuario actual es 'user-me'.
      final currentUser = _makeUser(id: 'user-me');
      final post        = _makePost(userId: 'author-001');

      _sl.registerFactory<PostViewModel>(
        () => PostViewModel(
          getPostByIdUseCase:     _StubGetPostById(post),
          getPostCommentsUseCase: _StubGetComments(),
          createCommentUseCase:   _StubCreateComment(),
          likePostUseCase:        _StubLikePost(),
          unlikePostUseCase:      _StubUnlikePost(),
        ),
      );
      final authVm   = await _makeAuthVmWithUser(currentUser);
      final observer = _RouteObserver();

      await tester.pumpWidget(_wrap(
        child:    const PostDetailPage(postId: 'post-001'),
        authVm:   authVm,
        observer: observer,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      // Debe navegar a la ruta de perfil ajeno.
      expect(observer.pushedRoutes, contains(AppRoutes.userProfile));
    });
  });
}
