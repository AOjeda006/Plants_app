/// @file user_profile_viewmodel_test.dart
/// @description Tests unitarios para UserProfileViewModel.
/// Verifica la carga del perfil ajeno, el estado de perfil privado,
/// el filtrado de posts y la gestión de errores.
/// @module Community
/// @layer Presentation
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:plants_app/core/errors/app_error.dart';
import 'package:plants_app/domain/entities/post.dart';
import 'package:plants_app/domain/entities/user.dart';
import 'package:plants_app/domain/interfaces/usecases/community/i_get_feed_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/user/i_get_user_by_id_use_case.dart';
import 'package:plants_app/presentation/viewmodels/community/user_profile_viewmodel.dart';

// ─── Mocks manuales ───────────────────────────────────────────────────────────

class _MockGetUserById implements IGetUserByIdUseCase {
  User? returnValue;
  AppError? throwError;

  @override
  Future<User> execute(String userId) async {
    if (throwError != null) throw throwError!;
    return returnValue!;
  }
}

class _MockGetFeed implements IGetFeedUseCase {
  List<Post> returnValue = [];
  AppError? throwError;
  // El backend filtra por `authorId` y el frontend no hace filtro local.
  // Simulamos ese filtrado server-side cuando el VM pasa authorId.
  @override
  Future<List<Post>> execute({int page = 1, int limit = 20, String? authorId}) async {
    if (throwError != null) throw throwError!;
    if (authorId == null) return returnValue;
    return returnValue.where((p) => p.userId == authorId).toList();
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

const targetUserId = 'target-001';
const otherId      = 'other-001';

final _now = DateTime.utc(2026, 3, 16);

User _makeUser({
  String id          = targetUserId,
  bool profilePublic = true,
  String? bannerPhoto,
}) =>
    User(
      id:          id,
      name:        'Target User',
      email:       '$id@x.com',
      role:        'user',
      createdAt:   _now,
      bannerPhoto: bannerPhoto,
      preferences: UserPreferences(profilePublic: profilePublic),
    );

Post _makePost({required String userId, required String id}) => Post(
  id:            id,
  userId:        userId,
  authorName:    'Target User',
  content:       'Post de Target',
  likesCount:    0,
  commentsCount: 0,
  isLikedByMe:   false,
  createdAt:     _now,
  updatedAt:     _now,
);

UserProfileViewModel _makeViewModel({
  _MockGetUserById? getUserById,
  _MockGetFeed?     getFeed,
}) =>
    UserProfileViewModel(
      getFeedUseCase:      getFeed      ?? _MockGetFeed(),
      getUserByIdUseCase:  getUserById  ?? _MockGetUserById(),
    );

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  // ── loadProfile — perfil público ──────────────────────────────────────────────

  group('loadProfile() — perfil público', () {
    test('debe cargar los posts del usuario filtrados por userId', () async {
      final getUserById = _MockGetUserById()..returnValue = _makeUser();
      final getFeed     = _MockGetFeed()
        ..returnValue = [
          _makePost(userId: targetUserId, id: 'p1'),
          _makePost(userId: otherId,      id: 'p2'), // ajeno
          _makePost(userId: targetUserId, id: 'p3'),
        ];
      final vm = _makeViewModel(getUserById: getUserById, getFeed: getFeed);

      await vm.loadProfile(
        userId:     targetUserId,
        authorName: 'Target User',
      );

      expect(vm.isPrivate,    isFalse);
      expect(vm.posts.length, 2);
      expect(vm.posts.map((p) => p.id), containsAll(['p1', 'p3']));
      expect(vm.isLoading,    isFalse);
      expect(vm.error,        isNull);
    });

    test('debe exponer bannerPhoto del usuario', () async {
      final getUserById = _MockGetUserById()
        ..returnValue = _makeUser(bannerPhoto: 'https://cdn.example.com/banner.jpg');
      final vm = _makeViewModel(getUserById: getUserById);

      await vm.loadProfile(userId: targetUserId, authorName: 'Target User');

      expect(vm.bannerPhoto, 'https://cdn.example.com/banner.jpg');
    });

    test('debe separar posts con y sin imagen en los getters', () async {
      final getUserById = _MockGetUserById()..returnValue = _makeUser();
      final postWithImg = Post(
        id:            'img-post',
        userId:        targetUserId,
        authorName:    'Target User',
        content:       'Con foto',
        image:         'https://img.example.com/photo.jpg',
        likesCount:    0,
        commentsCount: 0,
        isLikedByMe:   false,
        createdAt:     _now,
        updatedAt:     _now,
      );
      final postNoImg = _makePost(userId: targetUserId, id: 'text-post');
      final getFeed   = _MockGetFeed()..returnValue = [postWithImg, postNoImg];
      final vm        = _makeViewModel(getUserById: getUserById, getFeed: getFeed);

      await vm.loadProfile(userId: targetUserId, authorName: 'Target User');

      expect(vm.postsWithImage.length,    1);
      expect(vm.postsWithoutImage.length, 1);
    });
  });

  // ── loadProfile — perfil privado ──────────────────────────────────────────────

  group('loadProfile() — perfil privado', () {
    test('debe marcar isPrivate=true y devolver lista de posts vacía', () async {
      final getUserById = _MockGetUserById()
        ..returnValue = _makeUser(profilePublic: false);
      final getFeed = _MockGetFeed()
        ..returnValue = [_makePost(userId: targetUserId, id: 'p1')];
      final vm = _makeViewModel(getUserById: getUserById, getFeed: getFeed);

      await vm.loadProfile(userId: targetUserId, authorName: 'Target User');

      expect(vm.isPrivate,    isTrue);
      expect(vm.posts,        isEmpty);
      expect(vm.isLoading,    isFalse);
      expect(vm.error,        isNull);
    });

    test('no debe llamar al feed si el perfil es privado', () async {
      final getUserById = _MockGetUserById()
        ..returnValue = _makeUser(profilePublic: false);
      int feedCallCount = 0;
      final vm = UserProfileViewModel(
        getFeedUseCase:     _CountingGetFeed(counter: () => feedCallCount++),
        getUserByIdUseCase: getUserById,
      );

      await vm.loadProfile(userId: targetUserId, authorName: 'Target User');

      expect(feedCallCount, 0);
    });
  });

  // ── Errores ───────────────────────────────────────────────────────────────────

  group('loadProfile() — errores', () {
    test('debe establecer error si getUserById falla', () async {
      final getUserById = _MockGetUserById()
        ..throwError = AppError.notFound('User not found');
      final vm = _makeViewModel(getUserById: getUserById);

      await vm.loadProfile(userId: targetUserId, authorName: 'Target User');

      expect(vm.error,     isNotNull);
      expect(vm.isLoading, isFalse);
    });

    test('debe establecer error si el feed falla', () async {
      final getUserById = _MockGetUserById()..returnValue = _makeUser();
      final getFeed     = _MockGetFeed()..throwError = AppError.network();
      final vm          = _makeViewModel(getUserById: getUserById, getFeed: getFeed);

      await vm.loadProfile(userId: targetUserId, authorName: 'Target User');

      expect(vm.error,     isNotNull);
      expect(vm.isLoading, isFalse);
    });

    test('clearError debe limpiar el error', () async {
      final getUserById = _MockGetUserById()
        ..throwError = AppError.network();
      final vm = _makeViewModel(getUserById: getUserById);

      await vm.loadProfile(userId: targetUserId, authorName: 'Target User');
      expect(vm.error, isNotNull);

      vm.clearError();
      expect(vm.error, isNull);
    });
  });

  // ── isEmpty ───────────────────────────────────────────────────────────────────

  group('isEmpty', () {
    test('debe ser true si no hay posts, no carga y no hay error', () async {
      final getUserById = _MockGetUserById()..returnValue = _makeUser();
      final getFeed     = _MockGetFeed()..returnValue = [];
      final vm          = _makeViewModel(getUserById: getUserById, getFeed: getFeed);

      await vm.loadProfile(userId: targetUserId, authorName: 'Target User');

      expect(vm.isEmpty, isTrue);
    });

    test('debe ser false si hay posts', () async {
      final getUserById = _MockGetUserById()..returnValue = _makeUser();
      final getFeed     = _MockGetFeed()
        ..returnValue = [_makePost(userId: targetUserId, id: 'p1')];
      final vm = _makeViewModel(getUserById: getUserById, getFeed: getFeed);

      await vm.loadProfile(userId: targetUserId, authorName: 'Target User');

      expect(vm.isEmpty, isFalse);
    });
  });
}

// ─── Helper auxiliar para contar llamadas al feed ─────────────────────────────

class _CountingGetFeed implements IGetFeedUseCase {
  final void Function() counter;
  _CountingGetFeed({required this.counter});

  @override
  Future<List<Post>> execute({int page = 1, int limit = 20, String? authorId}) async {
    counter();
    return [];
  }
}
