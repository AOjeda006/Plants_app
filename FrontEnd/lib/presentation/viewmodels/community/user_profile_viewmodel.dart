/// @file user_profile_viewmodel.dart
/// @description ViewModel del perfil de usuario ajeno. Muestra los datos del autor
/// obtenidos desde un post y sus publicaciones filtradas del feed.
/// @module Community
/// @layer Presentation
library;

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/interfaces/usecases/community/i_get_feed_use_case.dart';
import '../../../domain/interfaces/usecases/user/i_get_user_by_id_use_case.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// USER PROFILE VIEWMODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// ViewModel del perfil de un usuario ajeno con sus posts públicos.
///
/// Estado gestionado:
///  - [authorName]  — nombre del autor mostrado en la cabecera.
///  - [authorPhoto] — URL foto del autor (puede ser null).
///  - [userId]      — ID del usuario visto.
///  - [posts]       — posts del feed que pertenecen a este usuario.
///  - [isLoading]   — true mientras se cargan los posts.
///  - [error]       — último error (null si no hay).
///
/// El backend acepta el parámetro `authorId` en el feed para devolver
/// solo posts de un autor concreto. Este ViewModel se apoya en ese
/// filtrado server-side (alineado con `MyProfileViewModel`); así se ven
/// todos los posts del usuario aunque tenga >50 publicaciones globales.
///
/// [injectable] registrar en container.dart como factory.
/// [dependencies] IGetFeedUseCase, IGetUserByIdUseCase.
class UserProfileViewModel extends ChangeNotifier {
  final IGetFeedUseCase       _getFeed;
  final IGetUserByIdUseCase   _getUserById;

  UserProfileViewModel({
    required IGetFeedUseCase     getFeedUseCase,
    required IGetUserByIdUseCase getUserByIdUseCase,
  })  : _getFeed     = getFeedUseCase,
        _getUserById = getUserByIdUseCase;

  // ─── Estado ───────────────────────────────────────────────────────────────────

  String     _userId       = '';
  String     _authorName   = '';
  String?    _authorPhoto;
  String?    _bannerPhoto;
  List<Post> _posts        = [];
  bool       _isLoading    = false;
  bool       _isPrivate    = false;
  AppError?  _error;

  String     get userId      => _userId;
  String     get authorName  => _authorName;
  String?    get authorPhoto => _authorPhoto;
  /// URL del banner/fondo de perfil, o null si no tiene.
  String?    get bannerPhoto => _bannerPhoto;
  List<Post> get posts       => _posts;
  bool       get isLoading   => _isLoading;
  /// true si el perfil del usuario es privado (no se muestran sus posts).
  bool       get isPrivate   => _isPrivate;
  AppError?  get error       => _error;

  /// Posts que tienen imagen adjunta (tab "Con foto").
  List<Post> get postsWithImage    => _posts.where((p) => p.hasImage).toList();

  /// Posts de solo texto, sin imagen (tab "Sin foto").
  List<Post> get postsWithoutImage => _posts.where((p) => !p.hasImage).toList();

  /// true si el usuario no tiene posts publicados (o no se pudieron cargar).
  bool get isEmpty => !_isLoading && _posts.isEmpty && _error == null;

  // ─── Cargar perfil ────────────────────────────────────────────────────────────

  /// Inicializa el perfil con los datos del autor obtenidos de un [Post]
  /// y carga sus publicaciones filtradas del feed global.
  ///
  /// [param] userId      — ID del usuario a mostrar.
  /// [param] authorName  — Nombre visible del autor (desde el post).
  /// [param] authorPhoto — URL de la foto del autor (desde el post).
  Future<void> loadProfile({
    required String  userId,
    required String  authorName,
    String?          authorPhoto,
  }) async {
    _userId      = userId;
    _authorName  = authorName;
    _authorPhoto = authorPhoto;
    _isLoading   = true;
    _isPrivate   = false;
    _error       = null;
    notifyListeners();

    try {
      // Cargar perfil completo: privacidad y banner.
      final user  = await _getUserById.execute(userId);
      _isPrivate   = user.preferences?.profilePublic == false;
      _bannerPhoto = user.bannerPhoto;

      if (_isPrivate) {
        _posts = [];
      } else {
        // El backend filtra por autor: no aplicamos filtro local. Esto
        // cubre usuarios con >50 posts, donde un filtro local sobre la
        // primera página global se quedaría corto.
        _posts = await _getFeed.execute(page: 1, limit: 50, authorId: userId);
      }
    } on AppError catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recarga los posts del usuario.
  Future<void> refresh() async {
    if (_userId.isEmpty) return;
    await loadProfile(
      userId:      _userId,
      authorName:  _authorName,
      authorPhoto: _authorPhoto,
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
