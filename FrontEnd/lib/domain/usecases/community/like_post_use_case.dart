/// @file like_post_use_case.dart
/// @description Implementación del caso de uso para dar like a un post.
/// @module Community
/// @layer Domain
library;

import '../../interfaces/usecases/community/i_like_post_use_case.dart';
import '../../repositories/i_post_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// LIKE POST USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Da like a un post de la comunidad. Operación idempotente.
///
/// [implements] ILikePostUseCase
/// [injectable] registrar en container.dart como singleton.
/// [dependencies] IPostRepository.
class LikePostUseCase implements ILikePostUseCase {
  final IPostRepository _repository;

  const LikePostUseCase({required IPostRepository repository})
      : _repository = repository;

  @override
  Future<void> execute(String postId) {
    return _repository.likePost(postId);
  }
}
