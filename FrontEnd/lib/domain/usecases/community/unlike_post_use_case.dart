/// @file unlike_post_use_case.dart
/// @description Implementación del caso de uso para quitar el like de un post.
/// @module Community
/// @layer Domain
library;

import '../../interfaces/usecases/community/i_unlike_post_use_case.dart';
import '../../repositories/i_post_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// UNLIKE POST USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Quita el like de un post de la comunidad. Operación idempotente.
///
/// [implements] IUnlikePostUseCase
/// [injectable] registrar en container.dart como singleton.
/// [dependencies] IPostRepository.
class UnlikePostUseCase implements IUnlikePostUseCase {
  final IPostRepository _repository;

  const UnlikePostUseCase({required IPostRepository repository})
      : _repository = repository;

  @override
  Future<void> execute(String postId) {
    return _repository.unlikePost(postId);
  }
}
