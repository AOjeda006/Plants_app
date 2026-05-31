/// @file post_viewmodel_test.dart
/// @description Tests unitarios para PostViewModel.
/// Verifica: toggleLike() con actualización optimista y reversión en error,
/// submitComment() con incremento de commentsCount y lista de comentarios,
/// y bloqueo de doble-tap mediante isPendingLike.
/// @module Community
/// @layer Presentation
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:plants_app/core/errors/app_error.dart';
import 'package:plants_app/domain/entities/comment.dart';
import 'package:plants_app/domain/entities/post.dart';
import 'package:plants_app/domain/interfaces/usecases/community/i_create_comment_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/community/i_get_post_by_id_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/community/i_get_post_comments_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/community/i_like_post_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/community/i_unlike_post_use_case.dart';
import 'package:plants_app/presentation/viewmodels/community/post_viewmodel.dart';

// ─── Stubs ────────────────────────────────────────────────────────────────────

final _fixedDate = DateTime.utc(2026, 3, 19, 10);

Post _makePost({bool isLikedByMe = false, int likesCount = 5, int commentsCount = 2}) =>
    Post(
      id:            'post-001',
      userId:        'user-001',
      authorName:    'Ana Verde',
      content:       'Mi planta favorita',
      likesCount:    likesCount,
      commentsCount: commentsCount,
      createdAt:     _fixedDate,
      updatedAt:     _fixedDate,
      isLikedByMe:   isLikedByMe,
    );

Comment _makeComment() => Comment(
      id:          'comment-001',
      postId:      'post-001',
      userId:      'user-002',
      authorName:  'Bot Comentarista',
      content:     '¡Qué bonita!',
      createdAt:   _fixedDate,
    );

class _StubGetPostById implements IGetPostByIdUseCase {
  final Post post;
  _StubGetPostById(this.post);
  @override
  Future<Post> execute(String postId) async => post;
}

class _StubGetComments implements IGetPostCommentsUseCase {
  final List<Comment> comments;
  _StubGetComments([this.comments = const []]);
  @override
  Future<List<Comment>> execute(String postId) async => comments;
}

/// Like que falla con AppError.
class _FailingLike implements ILikePostUseCase {
  @override
  Future<void> execute(String postId) async =>
      throw AppError.server('Like API error');
}

/// Unlike que falla con AppError.
class _FailingUnlike implements IUnlikePostUseCase {
  @override
  Future<void> execute(String postId) async =>
      throw AppError.server('Unlike API error');
}

class _OkLike implements ILikePostUseCase {
  @override
  Future<void> execute(String postId) async {}
}

class _OkUnlike implements IUnlikePostUseCase {
  @override
  Future<void> execute(String postId) async {}
}

class _OkCreateComment implements ICreateCommentUseCase {
  final Comment comment;
  _OkCreateComment(this.comment);
  @override
  Future<Comment> execute(String postId, String content) async => comment;
}

class _FailingCreateComment implements ICreateCommentUseCase {
  @override
  Future<Comment> execute(String postId, String content) async =>
      throw AppError.server('Comment API error');
}

// ─── Helper: construye el ViewModel ya cargado con el post de prueba ──────────

Future<PostViewModel> _buildVm({
  required Post post,
  ILikePostUseCase?   likeUseCase,
  IUnlikePostUseCase? unlikeUseCase,
  ICreateCommentUseCase? createCommentUseCase,
  List<Comment> comments = const [],
}) async {
  final vm = PostViewModel(
    getPostByIdUseCase:     _StubGetPostById(post),
    getPostCommentsUseCase: _StubGetComments(comments),
    createCommentUseCase:   createCommentUseCase ?? _OkCreateComment(_makeComment()),
    likePostUseCase:        likeUseCase   ?? _OkLike(),
    unlikePostUseCase:      unlikeUseCase ?? _OkUnlike(),
  );
  await vm.loadPost('post-001');
  return vm;
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  // ── toggleLike() ─────────────────────────────────────────────────────────────

  group('toggleLike() — dar like (post no likeado)', () {
    test('incrementa likesCount e isLikedByMe optimistamente', () async {
      final post = _makePost(isLikedByMe: false, likesCount: 5);
      final vm   = await _buildVm(post: post, likeUseCase: _OkLike());

      await vm.toggleLike();

      expect(vm.post?.isLikedByMe, isTrue);
      expect(vm.post?.likesCount,  equals(6));
    });

    test('revierte isLikedByMe y likesCount si la API falla', () async {
      final post = _makePost(isLikedByMe: false, likesCount: 5);
      final vm   = await _buildVm(post: post, likeUseCase: _FailingLike());

      await vm.toggleLike();

      expect(vm.post?.isLikedByMe, isFalse);
      expect(vm.post?.likesCount,  equals(5));
    });

    test('no deja likesCount por debajo de 0 al revertir', () async {
      // Post con 0 likes, no likeado; la API falla. El contador no puede ser negativo.
      final post = _makePost(isLikedByMe: false, likesCount: 0);
      final vm   = await _buildVm(post: post, likeUseCase: _FailingLike());

      await vm.toggleLike();

      expect(vm.post?.likesCount, greaterThanOrEqualTo(0));
    });

    test('isPendingLike es true durante la llamada y false al terminar', () async {
      bool? pendingDuringCall;
      final post = _makePost(isLikedByMe: false, likesCount: 3);
      final likeWithCapture = _OkLike();

      // Observamos el estado durante el toggle.
      final vm = await _buildVm(post: post, likeUseCase: likeWithCapture);

      // Dado que la stub resuelve sincrónico en el microtask, verificamos antes de await.
      final future = vm.toggleLike();
      pendingDuringCall = vm.isPendingLike;
      await future;

      expect(pendingDuringCall, isTrue,  reason: 'isPendingLike debe ser true durante la llamada');
      expect(vm.isPendingLike,  isFalse, reason: 'isPendingLike debe ser false al terminar');
    });
  });

  group('toggleLike() — quitar like (post ya likeado)', () {
    test('decrementa likesCount e isLikedByMe optimistamente', () async {
      final post = _makePost(isLikedByMe: true, likesCount: 7);
      final vm   = await _buildVm(post: post, unlikeUseCase: _OkUnlike());

      await vm.toggleLike();

      expect(vm.post?.isLikedByMe, isFalse);
      expect(vm.post?.likesCount,  equals(6));
    });

    test('revierte isLikedByMe y likesCount si la API falla', () async {
      final post = _makePost(isLikedByMe: true, likesCount: 7);
      final vm   = await _buildVm(post: post, unlikeUseCase: _FailingUnlike());

      await vm.toggleLike();

      expect(vm.post?.isLikedByMe, isTrue);
      expect(vm.post?.likesCount,  equals(7));
    });
  });

  group('toggleLike() — doble-tap', () {
    test('una segunda llamada concurrente es ignorada si la primera sigue en vuelo', () async {
      final post = _makePost(isLikedByMe: false, likesCount: 5);
      final vm   = await _buildVm(post: post, likeUseCase: _OkLike());

      // Lanzar dos toggleLike sin await; el segundo debe ser ignorado.
      final f1 = vm.toggleLike();
      final f2 = vm.toggleLike(); // ignorado (isPendingLike == true)
      await Future.wait([f1, f2]);

      // Solo se aplicó un toggle: count = 6 (no 7).
      expect(vm.post?.likesCount, equals(6));
    });
  });

  // ── submitComment() ───────────────────────────────────────────────────────────

  group('submitComment()', () {
    test('incrementa commentsCount en 1 tras publicar', () async {
      final post    = _makePost(commentsCount: 2);
      final comment = _makeComment();
      final vm      = await _buildVm(post: post, createCommentUseCase: _OkCreateComment(comment));

      final result = await vm.submitComment('¡Qué bonita!');

      expect(result,                isTrue);
      expect(vm.post?.commentsCount, equals(3));
    });

    test('añade el nuevo comentario al final de la lista', () async {
      final post    = _makePost();
      final comment = _makeComment();
      final vm      = await _buildVm(
        post:                 post,
        createCommentUseCase: _OkCreateComment(comment),
        comments:             [],
      );

      await vm.submitComment('¡Qué bonita!');

      expect(vm.comments, hasLength(1));
      expect(vm.comments.last.content, equals('¡Qué bonita!'));
    });

    test('devuelve false y no modifica commentsCount si la API falla', () async {
      final post = _makePost(commentsCount: 2);
      final vm   = await _buildVm(
        post:                 post,
        createCommentUseCase: _FailingCreateComment(),
      );

      final result = await vm.submitComment('Este comentario fallará');

      expect(result,                 isFalse);
      expect(vm.post?.commentsCount, equals(2));
    });

    test('devuelve false si el contenido está vacío', () async {
      final post = _makePost();
      final vm   = await _buildVm(post: post);

      final result = await vm.submitComment('   ');

      expect(result, isFalse);
    });
  });

  // ── applyPostUpdate (post:updated socket event) ───────────────────────────────

  group('applyPostUpdate()', () {
    test('actualiza likesCount y commentsCount cuando el postId coincide', () async {
      final post = _makePost(likesCount: 3, commentsCount: 2);
      final vm   = await _buildVm(post: post);

      vm.applyPostUpdate('post-001', 10, 7);

      expect(vm.post?.likesCount,    10);
      expect(vm.post?.commentsCount, 7);
    });

    test('no modifica isLikedByMe al recibir el evento del servidor', () async {
      final post = _makePost(isLikedByMe: true, likesCount: 5);
      final vm   = await _buildVm(post: post);

      vm.applyPostUpdate('post-001', 8, 3);

      expect(vm.post?.isLikedByMe, isTrue);
    });

    test('es no-op si el postId no coincide con el post cargado', () async {
      final post = _makePost(likesCount: 3, commentsCount: 2);
      final vm   = await _buildVm(post: post);

      vm.applyPostUpdate('otro-post-id', 99, 99);

      expect(vm.post?.likesCount,    3);
      expect(vm.post?.commentsCount, 2);
    });

    test('es no-op si no hay post cargado', () async {
      final vm = PostViewModel(
        getPostByIdUseCase:     _StubGetPostById(_makePost()),
        getPostCommentsUseCase: _StubGetComments(),
        createCommentUseCase:   _OkCreateComment(_makeComment()),
        likePostUseCase:        _OkLike(),
        unlikePostUseCase:      _OkUnlike(),
      );
      // No llamamos a loadPost(), por lo que _post == null.
      expect(() => vm.applyPostUpdate('post-001', 5, 2), returnsNormally);
      expect(vm.post, isNull);
    });
  });
}
