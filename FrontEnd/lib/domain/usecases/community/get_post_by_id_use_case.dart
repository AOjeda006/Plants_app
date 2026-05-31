/// @file get_post_by_id_use_case.dart
/// @description Implementación del caso de uso para obtener un post por ID.
/// @module Community
/// @layer Domain
library;

import '../../entities/post.dart';
import '../../interfaces/usecases/community/i_get_post_by_id_use_case.dart';
import '../../repositories/i_post_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// GET POST BY ID USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Obtiene el detalle de un post por su identificador.
///
/// [implements] IGetPostByIdUseCase
/// [injectable] registrar en container.dart como singleton.
/// [dependencies] IPostRepository.
class GetPostByIdUseCase implements IGetPostByIdUseCase {
  final IPostRepository _repository;

  const GetPostByIdUseCase({required IPostRepository repository})
      : _repository = repository;

  @override
  Future<Post> execute(String postId) {
    return _repository.getPostById(postId);
  }
}
