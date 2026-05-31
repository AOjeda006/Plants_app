/// @file create_post_use_case.dart
/// @description Implementación del caso de uso para crear un post en la comunidad.
/// @module Community
/// @layer Domain
library;

import '../../dtos/community/create_post_request_dto.dart';
import '../../entities/post.dart';
import '../../interfaces/usecases/community/i_create_post_use_case.dart';
import '../../repositories/i_post_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CREATE POST USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Crea un nuevo post en el feed de la comunidad.
///
/// [implements] ICreatePostUseCase
/// [injectable] registrar en container.dart como singleton.
/// [dependencies] IPostRepository.
class CreatePostUseCase implements ICreatePostUseCase {
  final IPostRepository _repository;

  const CreatePostUseCase({required IPostRepository repository})
      : _repository = repository;

  @override
  Future<Post> execute(CreatePostRequestDto dto) {
    return _repository.createPost(dto);
  }
}
