/// @file get_post_comments_use_case.dart
/// @description Implementación del caso de uso para obtener los comentarios de un post.
/// @module Community
/// @layer Domain
library;

import '../../entities/comment.dart';
import '../../interfaces/usecases/community/i_get_post_comments_use_case.dart';
import '../../repositories/i_post_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// GET POST COMMENTS USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Obtiene los comentarios de un post ordenados por fecha de creación.
///
/// [implements] IGetPostCommentsUseCase
/// [injectable] registrar en container.dart como singleton.
/// [dependencies] IPostRepository.
class GetPostCommentsUseCase implements IGetPostCommentsUseCase {
  final IPostRepository _repository;

  const GetPostCommentsUseCase({required IPostRepository repository})
      : _repository = repository;

  @override
  Future<List<Comment>> execute(String postId) {
    return _repository.getComments(postId);
  }
}
