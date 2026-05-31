/// @file my_profile_viewmodel.dart
/// @description ViewModel de la pantalla de perfil propio.
/// Gestiona la carga del perfil, los posts propios y el logout.
/// Depende SOLO de interfaces de use cases.
/// @module User
/// @layer Presentation
library;

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/interfaces/usecases/community/i_get_feed_use_case.dart';
import '../../../domain/interfaces/usecases/user/i_get_my_profile_use_case.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MY PROFILE VIEWMODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// ViewModel de la pantalla de perfil propio.
///
/// Estado gestionado:
///  - [user]              — usuario cargado (null mientras se carga o si hay error).
///  - [posts]             — posts propios filtrados del feed.
///  - [postsWithImage]    — posts con imagen adjunta (tab "Con foto").
///  - [postsWithoutImage] — posts de solo texto (tab "Sin foto").
///  - [isLoading]         — true mientras se carga el perfil.
///  - [error]             — último error ocurrido.
///
/// [injectable] registrar en container.dart como factory.
/// [dependencies] IGetMyProfileUseCase, IGetFeedUseCase.
class MyProfileViewModel extends ChangeNotifier {
  final IGetMyProfileUseCase _getMyProfile;
  final IGetFeedUseCase      _getFeed;

  MyProfileViewModel({
    required IGetMyProfileUseCase getMyProfileUseCase,
    required IGetFeedUseCase      getFeedUseCase,
  })  : _getMyProfile = getMyProfileUseCase,
        _getFeed      = getFeedUseCase;

  // ─── Estado ───────────────────────────────────────────────────────────────────

  User?      _user;
  List<Post> _posts     = [];
  bool       _isLoading = false;
  AppError?  _error;

  User?      get user      => _user;
  List<Post> get posts     => _posts;
  bool       get isLoading => _isLoading;
  AppError?  get error     => _error;

  /// Posts que tienen imagen adjunta (tab "Con foto").
  List<Post> get postsWithImage    => _posts.where((p) => p.hasImage).toList();

  /// Posts de solo texto, sin imagen (tab "Sin foto").
  List<Post> get postsWithoutImage => _posts.where((p) => !p.hasImage).toList();

  // ─── Cargar perfil ────────────────────────────────────────────────────────────

  /// Carga el perfil del usuario autenticado y sus publicaciones propias.
  Future<void> loadProfile() async {
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      _user = await _getMyProfile.execute();

      // Obtener posts propios vía GET /community/mine (authorId = userId del token).
      if (_user != null) {
        _posts = await _getFeed.execute(page: 1, limit: 50, authorId: _user!.id);
      }
    } on AppError catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // El logout vive en `AuthViewModel.logout()` (que orquesta el
  // `ILogoutUseCase` profundo). Las pantallas que cierran sesión llaman
  // a ese método y después incrementan `appProviderGeneration.value` para
  // reconstruir el árbol de Providers.

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
