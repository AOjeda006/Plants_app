/// @file i_create_post_use_case.dart
/// @description Interfaz: Crea un nuevo post en la comunidad.
/// @module Community
/// @layer Domain
library;

import '../../../dtos/community/create_post_request_dto.dart';
import '../../../entities/post.dart';

abstract interface class ICreatePostUseCase {
  /// Crea un nuevo post en la comunidad.
  ///
  /// [param] dto — DTO con el contenido, imageUrl opcional y plantId opcional.
  /// [returns] [Post] recién creado con datos del servidor.
  Future<Post> execute(CreatePostRequestDto dto);
}
