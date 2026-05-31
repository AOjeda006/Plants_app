/// @file i_create_comment_use_case.dart
/// @description Interfaz: Crea un comentario en un post.
/// @module Community
/// @layer Domain
library;

import '../../../entities/comment.dart';

abstract interface class ICreateCommentUseCase {
  /// Crea un comentario en un post.
  ///
  /// [param] postId  — Identificador del post.
  /// [param] content — Texto del comentario.
  /// [returns] [Comment] recién creado con datos del servidor.
  Future<Comment> execute(String postId, String content);
}
