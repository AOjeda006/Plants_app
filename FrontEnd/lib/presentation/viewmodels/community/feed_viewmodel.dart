/// @file feed_viewmodel.dart
/// @description ViewModel del feed de la comunidad. Gestiona paginación, likes y
/// navegación al detalle de post o perfil de usuario.
/// Depende SOLO de interfaces de use cases — nunca de implementaciones concretas.
/// @module Community
/// @layer Presentation
library;

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../domain/dtos/community/create_post_request_dto.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/interfaces/usecases/community/i_create_post_use_case.dart';
import '../../../domain/interfaces/usecases/community/i_get_feed_use_case.dart';
import '../../../domain/interfaces/usecases/community/i_like_post_use_case.dart';
import '../../../domain/interfaces/usecases/community/i_unlike_post_use_case.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// FEED VIEWMODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// ViewModel del feed de la comunidad. Extiende [ChangeNotifier] para Provider.
///
/// Estado gestionado:
///  - [posts]       — lista acumulada de posts del feed.
///  - [isLoading]   — true durante la carga inicial o de primera página.
///  - [isLoadingMore] — true mientras se carga la siguiente página (paginación).
///  - [isCreating]  — true mientras se publica un nuevo post.
///  - [error]       — último error (null si no hay).
///  - [hasMore]     — false cuando ya no hay más páginas.
///
/// [injectable] registrar en container.dart como factory.
/// [dependencies] IGetFeedUseCase, ILikePostUseCase, IUnlikePostUseCase, ICreatePostUseCase.
class FeedViewModel extends ChangeNotifier {
  final IGetFeedUseCase    _getFeed;
  final ILikePostUseCase   _likePost;
  final IUnlikePostUseCase _unlikePost;
  final ICreatePostUseCase _createPost;

  FeedViewModel({
    required IGetFeedUseCase    getFeedUseCase,
    required ILikePostUseCase   likePostUseCase,
    required IUnlikePostUseCase unlikePostUseCase,
    required ICreatePostUseCase createPostUseCase,
  })  : _getFeed    = getFeedUseCase,
        _likePost   = likePostUseCase,
        _unlikePost = unlikePostUseCase,
        _createPost = createPostUseCase;

  // ─── Estado ───────────────────────────────────────────────────────────────────

  List<Post>        _posts          = [];
  bool              _isLoading      = false;
  bool              _isLoadingMore  = false;
  bool              _isCreating     = false;
  AppError?         _error;
  int               _currentPage    = 1;
  bool              _hasMore        = true;
  // IDs de posts con like/unlike en vuelo — bloquea el botón mientras dura la request.
  final Set<String> _pendingLikes   = {};

  static const int _pageSize = 20;

  List<Post> get posts         => _posts;
  bool       get isLoading     => _isLoading;
  bool       get isLoadingMore => _isLoadingMore;
  bool       get isCreating    => _isCreating;
  AppError?  get error         => _error;
  bool       get hasMore       => _hasMore;

  /// true si el feed está vacío y no hay error ni carga.
  bool get isEmpty => !_isLoading && _posts.isEmpty && _error == null;

  /// true si hay una operación de like/unlike en vuelo para [postId].
  bool isPendingLike(String postId) => _pendingLikes.contains(postId);

  // ─── Cargar feed ──────────────────────────────────────────────────────────────

  /// Carga la primera página del feed. Resetea el estado de paginación.
  Future<void> loadFeed({bool showLoading = true}) async {
    _currentPage = 1;
    _hasMore     = true;

    if (showLoading) {
      _isLoading = true;
      _error     = null;
      notifyListeners();
    }

    try {
      final page = await _getFeed.execute(page: 1, limit: _pageSize);
      // Si es un refresh silencioso y la respuesta es idéntica al feed actual
      // (mismos IDs y contadores), no reconstruir la UI para evitar parpadeos.
      if (!showLoading && _isSameFeed(page)) {
        _isLoading = false;
        return;
      }
      _posts   = page;
      _hasMore = page.length >= _pageSize;
      _error   = null;
    } on AppError catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Alias para pull-to-refresh: siempre muestra spinner.
  Future<void> refresh() => loadFeed(showLoading: true);

  /// Carga la siguiente página del feed (scroll infinito).
  /// No hace nada si ya hay una carga en progreso o no hay más páginas.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final page     = await _getFeed.execute(page: nextPage, limit: _pageSize);
      // Nueva lista para consistencia con el resto del ViewModel (evitar mutación).
      _posts       = [..._posts, ...page];
      _currentPage = nextPage;
      _hasMore     = page.length >= _pageSize;
    } on AppError catch (e) {
      // Errores de paginación no bloquean la UI — solo se ignoran silenciosamente.
      debugPrint('FeedViewModel.loadMore error: ${e.message}');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ─── Like / Unlike ────────────────────────────────────────────────────────────

  /// Alterna el like del post con [postId] según su estado actual [isLikedByMe].
  /// Actualización optimista: cambia el estado local antes de la respuesta de la API.
  /// Si la API falla, revierte el estado a como estaba. Bloquea doble-tap mediante
  /// [_pendingLikes].
  Future<void> toggleLike(String postId) async {
    if (_pendingLikes.contains(postId)) return;

    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final wasLiked = _posts[idx].isLikedByMe;

    // Actualización optimista: isLikedByMe + likesCount.
    _pendingLikes.add(postId);
    _updatePostLikeState(postId, isLiked: !wasLiked, delta: wasLiked ? -1 : 1);

    try {
      if (wasLiked) {
        await _unlikePost.execute(postId);
      } else {
        await _likePost.execute(postId);
      }
    } on AppError catch (e) {
      // 409 = like ya existía — tratar como éxito silencioso, no revertir.
      if (e.statusCode != 409) {
        _updatePostLikeState(postId, isLiked: wasLiked, delta: wasLiked ? 1 : -1);
      }
    } finally {
      _pendingLikes.remove(postId);
      notifyListeners();
    }
  }

  /// Actualiza [isLikedByMe] y [likesCount] del post [postId] y notifica.
  void _updatePostLikeState(String postId, {required bool isLiked, required int delta}) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final updated = _posts[idx].copyWith(
      isLikedByMe: isLiked,
      likesCount:  (_posts[idx].likesCount + delta).clamp(0, double.maxFinite.toInt()),
    );
    _posts = List.from(_posts)..[idx] = updated;
    notifyListeners();
  }

  // ─── Crear post ───────────────────────────────────────────────────────────────

  /// Publica un nuevo post. Si tiene éxito, lo inserta al inicio del feed.
  ///
  /// [returns] true si el post se creó correctamente.
  Future<bool> createPost(CreatePostRequestDto dto) async {
    _isCreating = true;
    _error      = null;
    notifyListeners();

    try {
      final created = await _createPost.execute(dto);
      // Insertar el nuevo post al inicio del feed para verlo inmediatamente.
      _posts = [created, ..._posts];
      return true;
    } on AppError catch (e) {
      _error = e;
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  // ─── Actualizaciones en tiempo real ───────────────────────────────────────────

  /// Aplica contadores actualizados recibidos vía Socket.IO ('post:updated').
  /// Solo actualiza likesCount y commentsCount — no toca isLikedByMe (estado local).
  /// No-op si el post no está en el feed actual.
  void applyPostUpdate(String postId, int likesCount, int commentsCount) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    // No sobreescribir isLikedByMe: ese estado es local y ya está sincronizado.
    final updated = _posts[idx].copyWith(
      likesCount:    likesCount,
      commentsCount: commentsCount,
    );
    _posts = List.from(_posts)..[idx] = updated;
    notifyListeners();
  }

  // ─── Comparación de feed ───────────────────────────────────────────────────

  /// Compara la lista nueva con el feed actual. Devuelve true si tienen los mismos
  /// posts (por ID) con los mismos contadores — en ese caso no merece reconstruir la UI.
  bool _isSameFeed(List<Post> newPosts) {
    if (newPosts.length != _posts.length) return false;
    for (int i = 0; i < newPosts.length; i++) {
      final curr = _posts[i];
      final next = newPosts[i];
      if (curr.id != next.id ||
          curr.likesCount != next.likesCount ||
          curr.commentsCount != next.commentsCount ||
          curr.isLikedByMe != next.isLikedByMe) {
        return false;
      }
    }
    return true;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
