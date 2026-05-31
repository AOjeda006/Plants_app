/// @file get_feed_use_case.dart
/// @description Implementación del caso de uso para obtener el feed de la comunidad.
/// @module Community
/// @layer Domain
library;

import '../../entities/post.dart';
import '../../interfaces/usecases/community/i_get_feed_use_case.dart';
import '../../repositories/i_post_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// GET FEED USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Obtiene el feed paginado de posts de la comunidad.
///
/// [implements] IGetFeedUseCase
/// [injectable] registrar en container.dart como singleton.
/// [dependencies] IPostRepository.
class GetFeedUseCase implements IGetFeedUseCase {
  final IPostRepository _repository;

  const GetFeedUseCase({required IPostRepository repository})
      : _repository = repository;

  @override
  Future<List<Post>> execute({int page = 1, int limit = 20, String? authorId}) {
    return _repository.getFeed(page: page, limit: limit, authorId: authorId);
  }
}
