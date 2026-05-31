/// @file create_comment_use_case.dart
/// @description Implementación del caso de uso para crear un comentario en un post.
/// @module Community
/// @layer Domain
library;

import '../../entities/comment.dart';
import '../../interfaces/usecases/community/i_create_comment_use_case.dart';
import '../../repositories/i_post_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CREATE COMMENT USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Añade un comentario a un post de la comunidad.
///
/// [implements] ICreateCommentUseCase
/// [injectable] registrar en container.dart como singleton.
/// [dependencies] IPostRepository.
class CreateCommentUseCase implements ICreateCommentUseCase {
  final IPostRepository _repository;

  const CreateCommentUseCase({required IPostRepository repository})
      : _repository = repository;

  @override
  Future<Comment> execute(String postId, String content) {
    return _repository.createComment(postId, content);
  }
}
