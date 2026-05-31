/// @file my_profile_viewmodel_test.dart
/// @description Tests unitarios para MyProfileViewModel.
/// Verifica la carga del perfil propio, el filtrado de posts por userId,
/// el logout y la gestión de errores.
/// @module User
/// @layer Presentation
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:plants_app/core/errors/app_error.dart';
import 'package:plants_app/domain/entities/post.dart';
import 'package:plants_app/domain/entities/user.dart';
import 'package:plants_app/domain/interfaces/usecases/community/i_get_feed_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/user/i_get_my_profile_use_case.dart';
import 'package:plants_app/presentation/viewmodels/profile/my_profile_viewmodel.dart';

// ─── Mocks manuales ───────────────────────────────────────────────────────────

class _MockGetMyProfile implements IGetMyProfileUseCase {
  User? returnValue;
  AppError? throwError;

  @override
  Future<User> execute() async {
    if (throwError != null) throw throwError!;
    return returnValue!;
  }
}

class _MockGetFeed implements IGetFeedUseCase {
  List<Post> returnValue = [];
  AppError? throwError;

  @override
  Future<List<Post>> execute({int page = 1, int limit = 20, String? authorId}) async {
    if (throwError != null) throw throwError!;
    // Simula el comportamiento del backend: si se pasa authorId, filtra por userId.
    if (authorId != null) {
      return returnValue.where((p) => p.userId == authorId).toList();
    }
    return returnValue;
  }
}

// _FakeSecureStorage eliminado — el ViewModel ya no recibe
// AuthLocalDataSource (el logout vive en AuthViewModel).

// ─── Helpers ──────────────────────────────────────────────────────────────────

const ownerId = 'owner-001';
const otherId = 'other-001';

final _now = DateTime.utc(2026, 3, 16);

User _makeUser({String id = ownerId}) => User(
  id:        id,
  name:      'Owner',
  email:     '$id@x.com',
  role:      'user',
  createdAt: _now,
);

Post _makePost({required String userId, required String id}) => Post(
  id:            id,
  userId:        userId,
  authorName:    'User',
  content:       'Contenido',
  likesCount:    0,
  commentsCount: 0,
  isLikedByMe:   false,
  createdAt:     _now,
  updatedAt:     _now,
);

MyProfileViewModel _makeViewModel({
  _MockGetMyProfile? getProfile,
  _MockGetFeed?      getFeed,
}) {
  // El ViewModel ya no recibe `authStorage`: el logout pasa por
  // AuthViewModel + LogoutUseCase profundo.
  return MyProfileViewModel(
    getMyProfileUseCase: getProfile ?? _MockGetMyProfile(),
    getFeedUseCase:      getFeed    ?? _MockGetFeed(),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  // ── loadProfile ───────────────────────────────────────────────────────────────

  group('loadProfile()', () {
    test('debe cargar el usuario y filtrar solo sus posts', () async {
      final getProfile = _MockGetMyProfile()..returnValue = _makeUser();
      final getFeed    = _MockGetFeed()
        ..returnValue = [
          _makePost(userId: ownerId, id: 'p1'),
          _makePost(userId: otherId, id: 'p2'), // ajeno — debe excluirse
          _makePost(userId: ownerId, id: 'p3'),
        ];
      final vm = _makeViewModel(getProfile: getProfile, getFeed: getFeed);

      await vm.loadProfile();

      expect(vm.user,         isNotNull);
      expect(vm.user!.id,     ownerId);
      expect(vm.posts.length, 2);
      expect(vm.posts.map((p) => p.id), containsAll(['p1', 'p3']));
      expect(vm.isLoading,    isFalse);
      expect(vm.error,        isNull);
    });

    test('debe devolver lista vacía si el usuario no tiene posts', () async {
      final getProfile = _MockGetMyProfile()..returnValue = _makeUser();
      final getFeed    = _MockGetFeed()
        ..returnValue = [_makePost(userId: otherId, id: 'ajeno')];
      final vm = _makeViewModel(getProfile: getProfile, getFeed: getFeed);

      await vm.loadProfile();

      expect(vm.posts, isEmpty);
    });

    test('debe separar posts con y sin imagen en los getters', () async {
      final getProfile  = _MockGetMyProfile()..returnValue = _makeUser();
      final postWithImg = Post(
        id:            'img-post',
        userId:        ownerId,
        authorName:    'Owner',
        content:       'Con foto',
        image:         'https://img.example.com/photo.jpg',
        likesCount:    0,
        commentsCount: 0,
        isLikedByMe:   false,
        createdAt:     _now,
        updatedAt:     _now,
      );
      final postNoImg = _makePost(userId: ownerId, id: 'text-post');
      final getFeed   = _MockGetFeed()..returnValue = [postWithImg, postNoImg];
      final vm        = _makeViewModel(getProfile: getProfile, getFeed: getFeed);

      await vm.loadProfile();

      expect(vm.postsWithImage.length,    1);
      expect(vm.postsWithoutImage.length, 1);
      expect(vm.postsWithImage.first.id,  'img-post');
    });

    test('debe establecer error si falla la carga del perfil', () async {
      final getProfile = _MockGetMyProfile()
        ..throwError = AppError.unauthorized();
      final vm = _makeViewModel(getProfile: getProfile);

      await vm.loadProfile();

      expect(vm.error,     isNotNull);
      expect(vm.user,      isNull);
      expect(vm.isLoading, isFalse);
    });

    test('debe establecer error si falla la carga del feed', () async {
      final getProfile = _MockGetMyProfile()..returnValue = _makeUser();
      final getFeed    = _MockGetFeed()..throwError = AppError.network();
      final vm         = _makeViewModel(getProfile: getProfile, getFeed: getFeed);

      await vm.loadProfile();

      expect(vm.error,     isNotNull);
      expect(vm.isLoading, isFalse);
    });
  });

  // El método `logout()` se movió a AuthViewModel (que delega en
  // ILogoutUseCase). El test correspondiente vive en
  // `test/domain/usecases/auth/logout_use_case_test.dart`.
}
