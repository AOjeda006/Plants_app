/// @file i_get_post_by_id_use_case.dart
/// @description Interfaz: Obtiene un post por su ID.
/// @module Community
/// @layer Domain
library;

import '../../../entities/post.dart';

abstract interface class IGetPostByIdUseCase {
  /// Obtiene el detalle de un post por su identificador.
  ///
  /// [param] postId — Identificador del post.
  /// [returns] [Post] completo con todos sus campos.
  Future<Post> execute(String postId);
}
