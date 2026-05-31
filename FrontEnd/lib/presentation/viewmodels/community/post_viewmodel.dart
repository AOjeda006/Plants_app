/// @file post_viewmodel.dart
/// @description ViewModel del detalle de post. Gestiona la carga del post,
/// sus comentarios y la publicación de nuevos comentarios.
/// Depende SOLO de interfaces de use cases — nunca de implementaciones concretas.
/// @module Community
/// @layer Presentation
library;

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../domain/entities/comment.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/interfaces/usecases/community/i_create_comment_use_case.dart';
import '../../../domain/interfaces/usecases/community/i_get_post_by_id_use_case.dart';
import '../../../domain/interfaces/usecases/community/i_get_post_comments_use_case.dart';
import '../../../domain/interfaces/usecases/community/i_like_post_use_case.dart';
import '../../../domain/interfaces/usecases/community/i_unlike_post_use_case.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// POST VIEWMODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// ViewModel del detalle de un post con sus comentarios.
///
/// Estado gestionado:
///  - [post]              — post actual cargado (null mientras carga).
///  - [comments]          — lista de comentarios del post.
///  - [isLoading]         — true durante la carga inicial del post.
///  - [isLoadingComments] — true mientras carga los comentarios.
///  - [isSubmitting]      — true mientras se publica un comentario.
///  - [error]             — último error (null si no hay).
///
/// [injectable] registrar en container.dart como factory.
/// [dependencies] IGetPostByIdUseCase, IGetPostCommentsUseCase,
///               ICreateCommentUseCase, ILikePostUseCase, IUnlikePostUseCase.
class PostViewModel extends ChangeNotifier {
  final IGetPostByIdUseCase      _getPostById;
  final IGetPostCommentsUseCase  _getComments;
  final ICreateCommentUseCase    _createComment;
  final ILikePostUseCase         _likePost;
  final IUnlikePostUseCase       _unlikePost;

  PostViewModel({
    required IGetPostByIdUseCase     getPostByIdUseCase,
    required IGetPostCommentsUseCase getPostCommentsUseCase,
    required ICreateCommentUseCase   createCommentUseCase,
    required ILikePostUseCase        likePostUseCase,
    required IUnlikePostUseCase      unlikePostUseCase,
  })  : _getPostById    = getPostByIdUseCase,
        _getComments    = getPostCommentsUseCase,
        _createComment  = createCommentUseCase,
        _likePost       = likePostUseCase,
        _unlikePost     = unlikePostUseCase;

  // ─── Estado ───────────────────────────────────────────────────────────────────

  Post?         _post;
  List<Comment> _comments          = [];
  bool          _isLoading         = false;
  bool          _isLoadingComments = false;
  bool          _isSubmitting      = false;
  bool          _isPendingLike     = false;
  AppError?     _error;

  Post?         get post              => _post;
  List<Comment> get comments          => _comments;
  bool          get isLoading         => _isLoading;
  bool          get isLoadingComments => _isLoadingComments;
  bool          get isSubmitting      => _isSubmitting;
  bool          get isPendingLike     => _isPendingLike;
  AppError?     get error             => _error;

  // ─── Carga inicial ────────────────────────────────────────────────────────────

  /// Carga el post y sus comentarios en paralelo.
  Future<void> loadPost(String postId) async {
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      // Cargar post y comentarios en paralelo para acelerar la pantalla.
      final results = await Future.wait([
        _getPostById.execute(postId),
        _getComments.execute(postId),
      ]);
      _post     = results[0] as Post;
      _comments = results[1] as List<Comment>;
    } on AppError catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Recargar comentarios ─────────────────────────────────────────────────────

  /// Recarga solo los comentarios del post sin spinner de pantalla completa.
  Future<void> refreshComments(String postId) async {
    if (_post == null) return;
    _isLoadingComments = true;
    notifyListeners();

    try {
      _comments = await _getComments.execute(postId);
    } on AppError catch (e) {
      debugPrint('PostViewModel.refreshComments error: ${e.message}');
    } finally {
      _isLoadingComments = false;
      notifyListeners();
    }
  }

  // ─── Like / Unlike ────────────────────────────────────────────────────────────

  /// Alterna el like del post actual según su estado actual [isLikedByMe].
  /// Actualización optimista: cambia isLikedByMe y likesCount antes de la respuesta.
  /// Si la API falla, revierte ambos campos. Bloquea doble-tap mediante [_isPendingLike].
  Future<void> toggleLike() async {
    if (_post == null || _isPendingLike) return;

    final wasLiked = _post!.isLikedByMe;
    final postId   = _post!.id;

    // Actualización optimista: isLikedByMe + likesCount.
    _isPendingLike = true;
    _post = _post!.copyWith(
      isLikedByMe: !wasLiked,
      likesCount:  (_post!.likesCount + (wasLiked ? -1 : 1)).clamp(0, double.maxFinite.toInt()),
    );
    notifyListeners();

    try {
      if (wasLiked) {
        await _unlikePost.execute(postId);
      } else {
        await _likePost.execute(postId);
      }
    } on AppError catch (e) {
      // 409 = like ya existía — tratar como éxito silencioso, no revertir.
      if (e.statusCode != 409) {
        _post = _post!.copyWith(
          isLikedByMe: wasLiked,
          likesCount:  (_post!.likesCount + (wasLiked ? 1 : -1)).clamp(0, double.maxFinite.toInt()),
        );
      }
    } finally {
      _isPendingLike = false;
      notifyListeners();
    }
  }

  // ─── Publicar comentario ──────────────────────────────────────────────────────

  /// Publica un comentario en el post actual.
  ///
  /// [returns] true si el comentario se creó correctamente.
  Future<bool> submitComment(String content) async {
    if (_post == null || content.trim().isEmpty) return false;

    _isSubmitting = true;
    _error        = null;
    notifyListeners();

    try {
      final comment = await _createComment.execute(_post!.id, content.trim());
      // Añadir al final de la lista y actualizar el contador del post.
      _comments = [..._comments, comment];
      _post     = _post!.copyWith(commentsCount: _post!.commentsCount + 1);
      return true;
    } on AppError catch (e) {
      _error = e;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ─── Eliminación de comentario ─────────────────────────────────────────────

  /// Elimina un comentario de la lista local y decrementa el contador del post.
  /// No hace llamada a la API — eso lo hace la vista directamente.
  /// El socket 'post:updated' llegará después con el valor real del servidor.
  void removeCommentLocally(String commentId) {
    if (_post == null) return;
    _comments = _comments.where((c) => c.id != commentId).toList();
    _post = _post!.copyWith(
      commentsCount: (_post!.commentsCount - 1).clamp(0, double.maxFinite.toInt()),
    );
    notifyListeners();
  }

  // ─── Actualizaciones en tiempo real ───────────────────────────────────────────

  /// Aplica contadores actualizados recibidos vía Socket.IO ('post:updated').
  /// Usa siempre el valor del servidor como fuente de verdad para contadores.
  /// No toca isLikedByMe (estado local del toggle optimista).
  /// No-op si no hay post cargado o el postId no coincide.
  void applyPostUpdate(String postId, int likesCount, int commentsCount) {
    if (_post == null || _post!.id != postId) return;
    _post = _post!.copyWith(
      likesCount:    likesCount,
      commentsCount: commentsCount,
    );
    notifyListeners();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
