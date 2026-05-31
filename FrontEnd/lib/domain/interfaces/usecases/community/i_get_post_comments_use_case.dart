/// @file i_get_post_comments_use_case.dart
/// @description Interfaz: Obtiene los comentarios de un post.
/// @module Community
/// @layer Domain
library;

import '../../../entities/comment.dart';

abstract interface class IGetPostCommentsUseCase {
  /// Obtiene los comentarios de un post ordenados por fecha de creación.
  ///
  /// [param] postId — Identificador del post.
  /// [returns] Lista de [Comment].
  Future<List<Comment>> execute(String postId);
}
