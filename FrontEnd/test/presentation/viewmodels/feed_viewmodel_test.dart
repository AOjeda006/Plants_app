/// @file feed_viewmodel_test.dart
/// @description Tests unitarios para FeedViewModel.
/// Verifica carga de feed, like/unlike optimista con reversión y creación de posts.
/// @module Community
/// @layer Presentation
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:plants_app/core/errors/app_error.dart';
import 'package:plants_app/domain/dtos/community/create_post_request_dto.dart';
import 'package:plants_app/domain/entities/post.dart';
import 'package:plants_app/domain/interfaces/usecases/community/i_get_feed_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/community/i_like_post_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/community/i_unlike_post_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/community/i_create_post_use_case.dart';
import 'package:plants_app/presentation/viewmodels/community/feed_viewmodel.dart';

// ─── Mocks manuales ───────────────────────────────────────────────────────────

class _MockGetFeed implements IGetFeedUseCase {
  List<Post> returnValue = [];
  AppError? throwError;

  @override
  Future<List<Post>> execute({int page = 1, int limit = 20, String? authorId}) async {
    if (throwError != null) throw throwError!;
    return returnValue;
  }
}

class _MockLikePost implements ILikePostUseCase {
  AppError? throwError;

  @override
  Future<void> execute(String postId) async {
    if (throwError != null) throw throwError!;
  }
}

class _MockUnlikePost implements IUnlikePostUseCase {
  AppError? throwError;

  @override
  Future<void> execute(String postId) async {
    if (throwError != null) throw throwError!;
  }
}

class _MockCreatePost implements ICreatePostUseCase {
  Post? returnValue;
  AppError? throwError;

  @override
  Future<Post> execute(CreatePostRequestDto dto) async {
    if (throwError != null) throw throwError!;
    return returnValue!;
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

final _now = DateTime.utc(2026, 3, 5);

Post _makePost({
  String id          = 'post-001',
  int    likesCount  = 0,
  bool   isLikedByMe = false,
}) => Post(
  id:            id,
  userId:        'user-001',
  authorName:    'Test User',
  content:       'Contenido del post',
  likesCount:    likesCount,
  commentsCount: 0,
  isLikedByMe:   isLikedByMe,
  createdAt:     _now,
  updatedAt:     _now,
);

FeedViewModel _makeViewModel({
  _MockGetFeed?    getFeed,
  _MockLikePost?   like,
  _MockUnlikePost? unlike,
  _MockCreatePost? create,
}) =>
    FeedViewModel(
      getFeedUseCase:    getFeed ?? _MockGetFeed(),
      likePostUseCase:   like    ?? _MockLikePost(),
      unlikePostUseCase: unlike  ?? _MockUnlikePost(),
      createPostUseCase: create  ?? _MockCreatePost(),
    );

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  // ── loadFeed ──────────────────────────────────────────────────────────────────

  group('loadFeed()', () {
    test('debe cargar la primera página y limpiar el error', () async {
      final posts  = [_makePost(id: 'p1'), _makePost(id: 'p2')];
      final getFeed = _MockGetFeed()..returnValue = posts;
      final vm = _makeViewModel(getFeed: getFeed);

      await vm.loadFeed();

      expect(vm.posts.length, 2);
      expect(vm.error, isNull);
      expect(vm.isLoading, isFalse);
    });

    test('debe establecer hasMore en false si la página viene con menos de 20 elementos', () async {
      final getFeed = _MockGetFeed()..returnValue = [_makePost()];
      final vm = _makeViewModel(getFeed: getFeed);

      await vm.loadFeed();

      expect(vm.hasMore, isFalse);
    });

    test('debe guardar el error si la carga falla', () async {
      final getFeed = _MockGetFeed()..throwError = AppError.network();
      final vm = _makeViewModel(getFeed: getFeed);

      await vm.loadFeed();

      expect(vm.posts, isEmpty);
      expect(vm.error, isNotNull);
    });

    test('isEmpty debe ser true cuando no hay posts y no hay error', () async {
      final vm = _makeViewModel();
      await vm.loadFeed();
      expect(vm.isEmpty, isTrue);
    });
  });

  // ── toggleLike — dar like (isLikedByMe = false → true) ───────────────────────

  group('toggleLike() — dar like', () {
    test('debe incrementar likesCount e isLikedByMe optimistamente', () async {
      final post    = _makePost(id: 'p1', likesCount: 3, isLikedByMe: false);
      final getFeed = _MockGetFeed()..returnValue = [post];
      final vm      = _makeViewModel(getFeed: getFeed);

      await vm.loadFeed();
      await vm.toggleLike('p1');

      expect(vm.posts.first.likesCount, 4);
      expect(vm.posts.first.isLikedByMe, isTrue);
    });

    test('debe revertir el contador e isLikedByMe si la API falla', () async {
      final post    = _makePost(id: 'p1', likesCount: 3, isLikedByMe: false);
      final getFeed = _MockGetFeed()..returnValue = [post];
      final like    = _MockLikePost()..throwError = AppError.network();
      final vm      = _makeViewModel(getFeed: getFeed, like: like);

      await vm.loadFeed();
      await vm.toggleLike('p1');

      expect(vm.posts.first.likesCount, 3);
      expect(vm.posts.first.isLikedByMe, isFalse);
    });

    test('no debe poner likesCount por debajo de 0 al revertir', () async {
      final post    = _makePost(id: 'p1', likesCount: 0, isLikedByMe: false);
      final getFeed = _MockGetFeed()..returnValue = [post];
      final like    = _MockLikePost()..throwError = AppError.network();
      final vm      = _makeViewModel(getFeed: getFeed, like: like);

      await vm.loadFeed();
      await vm.toggleLike('p1');

      expect(vm.posts.first.likesCount, greaterThanOrEqualTo(0));
    });

    test('debe ignorar doble-tap mientras la request está en vuelo', () async {
      final post    = _makePost(id: 'p1', likesCount: 2, isLikedByMe: false);
      final getFeed = _MockGetFeed()..returnValue = [post];
      final vm      = _makeViewModel(getFeed: getFeed);

      await vm.loadFeed();
      // Primer toggle en vuelo (no awaited).
      final first  = vm.toggleLike('p1');
      // Segundo toggle mientras el primero no ha terminado: debe ser ignorado.
      final second = vm.toggleLike('p1');
      await Future.wait([first, second]);

      // Solo se aplicó un +1 (no dos).
      expect(vm.posts.first.likesCount, 3);
    });
  });

  // ── toggleLike — quitar like (isLikedByMe = true → false) ────────────────────

  group('toggleLike() — quitar like', () {
    test('debe decrementar likesCount e isLikedByMe optimistamente', () async {
      final post    = _makePost(id: 'p1', likesCount: 5, isLikedByMe: true);
      final getFeed = _MockGetFeed()..returnValue = [post];
      final vm      = _makeViewModel(getFeed: getFeed);

      await vm.loadFeed();
      await vm.toggleLike('p1');

      expect(vm.posts.first.likesCount, 4);
      expect(vm.posts.first.isLikedByMe, isFalse);
    });

    test('debe revertir el contador e isLikedByMe si la API falla', () async {
      final post    = _makePost(id: 'p1', likesCount: 5, isLikedByMe: true);
      final getFeed = _MockGetFeed()..returnValue = [post];
      final unlike  = _MockUnlikePost()..throwError = AppError.network();
      final vm      = _makeViewModel(getFeed: getFeed, unlike: unlike);

      await vm.loadFeed();
      await vm.toggleLike('p1');

      expect(vm.posts.first.likesCount, 5);
      expect(vm.posts.first.isLikedByMe, isTrue);
    });
  });

  // ── createPost ────────────────────────────────────────────────────────────────

  group('createPost()', () {
    test('debe insertar el nuevo post al inicio del feed y devolver true', () async {
      final existing = _makePost(id: 'old-post');
      final newPost  = _makePost(id: 'new-post');
      final getFeed  = _MockGetFeed()..returnValue = [existing];
      final create   = _MockCreatePost()..returnValue = newPost;
      final vm       = _makeViewModel(getFeed: getFeed, create: create);

      await vm.loadFeed();
      final dto = CreatePostRequestDto(content: 'Nuevo post');
      final result = await vm.createPost(dto);

      expect(result, isTrue);
      expect(vm.posts.first.id, 'new-post');
      expect(vm.posts.length, 2);
      expect(vm.isCreating, isFalse);
    });

    test('debe devolver false y guardar el error si la creación falla', () async {
      final create = _MockCreatePost()..throwError = AppError.server();
      final vm     = _makeViewModel(create: create);

      final dto    = CreatePostRequestDto(content: 'Post fallido');
      final result = await vm.createPost(dto);

      expect(result, isFalse);
      expect(vm.error, isNotNull);
    });
  });

  // ── applyPostUpdate (post:updated socket event) ──────────────────────────────

  group('applyPostUpdate()', () {
    test('actualiza likesCount y commentsCount del post correspondiente', () async {
      final post    = _makePost(id: 'p1', likesCount: 3);
      final getFeed = _MockGetFeed()..returnValue = [post];
      final vm      = _makeViewModel(getFeed: getFeed);

      await vm.loadFeed();
      vm.applyPostUpdate('p1', 10, 5);

      expect(vm.posts.first.likesCount,    10);
      expect(vm.posts.first.commentsCount, 5);
    });

    test('no modifica isLikedByMe al aplicar la actualización del servidor', () async {
      final post    = _makePost(id: 'p1', isLikedByMe: true, likesCount: 5);
      final getFeed = _MockGetFeed()..returnValue = [post];
      final vm      = _makeViewModel(getFeed: getFeed);

      await vm.loadFeed();
      vm.applyPostUpdate('p1', 7, 2);

      // isLikedByMe debe seguir siendo true — no lo toca el socket event.
      expect(vm.posts.first.isLikedByMe, isTrue);
    });

    test('es no-op si el postId no está en el feed', () async {
      final post    = _makePost(id: 'p1', likesCount: 3);
      final getFeed = _MockGetFeed()..returnValue = [post];
      final vm      = _makeViewModel(getFeed: getFeed);

      await vm.loadFeed();
      // Aplicar update para un post que no está en el feed.
      vm.applyPostUpdate('otro-post', 99, 99);

      // El post original no debe cambiar.
      expect(vm.posts.first.likesCount,    3);
      expect(vm.posts.first.commentsCount, 0);
    });
  });

  // ── recarga tras login ────────────────────────────────────────────────────────

  group('loadFeed() — recarga tras login', () {
    test('segunda llamada reemplaza los posts anteriores', () async {
      final getFeed = _MockGetFeed()
        ..returnValue = [_makePost(id: 'post-1'), _makePost(id: 'post-2')];
      final vm = _makeViewModel(getFeed: getFeed);

      await vm.loadFeed();
      expect(vm.posts.length, 2);

      // Simula nueva sesión: el feed solo tiene un post nuevo.
      getFeed.returnValue = [_makePost(id: 'post-3')];
      await vm.loadFeed();

      expect(vm.posts.length, 1);
      expect(vm.posts.first.id, 'post-3');
    });
  });
}
