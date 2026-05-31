/// @file i_post_repository.dart
/// @description Interfaz del repositorio de posts de la comunidad.
/// Define el contrato que debe cumplir cualquier implementación de repositorio de posts.
/// @module Community
/// @layer Domain
library;

import '../dtos/community/create_post_request_dto.dart';
import '../entities/comment.dart';
import '../entities/post.dart';

/// Contrato del repositorio de posts y comentarios de la comunidad.
///
/// Los use cases dependen de esta interfaz para desacoplarse de la
/// implementación concreta (PostRepositoryImpl).
abstract interface class IPostRepository {

  /// Obtiene la página [page] del feed de la comunidad.
  ///
  /// [param] page     — Número de página (1-based).
  /// [param] limit    — Posts por página.
  /// [param] authorId — Si se proporciona, llama a /community/mine (posts propios).
  /// [returns] Lista de posts del feed.
  /// [throws] AppError — Si la petición falla.
  Future<List<Post>> getFeed({int page = 1, int limit = 20, String? authorId});

  /// Obtiene un post por su identificador.
  ///
  /// [param] postId — Identificador del post.
  /// [returns] Post completo con todos sus campos.
  /// [throws] AppError — Si el post no existe.
  Future<Post> getPostById(String postId);

  /// Crea un nuevo post en la comunidad.
  ///
  /// [param] dto — DTO con los datos del nuevo post.
  /// [returns] Post recién creado.
  /// [throws] AppError — Si la validación falla o la petición da error.
  Future<Post> createPost(CreatePostRequestDto dto);

  /// Da like a un post. Operación idempotente.
  ///
  /// [param] postId — Identificador del post.
  /// [throws] AppError — Si la petición falla.
  Future<void> likePost(String postId);

  /// Quita el like de un post. Operación idempotente.
  ///
  /// [param] postId — Identificador del post.
  /// [throws] AppError — Si la petición falla.
  Future<void> unlikePost(String postId);

  /// Obtiene los comentarios de un post.
  ///
  /// [param] postId — Identificador del post.
  /// [returns] Lista de comentarios ordenados por fecha de creación.
  /// [throws] AppError — Si la petición falla.
  Future<List<Comment>> getComments(String postId);

  /// Crea un comentario en un post.
  ///
  /// [param] postId  — Identificador del post.
  /// [param] content — Texto del comentario.
  /// [returns] Comentario recién creado.
  /// [throws] AppError — Si la petición falla.
  Future<Comment> createComment(String postId, String content);
}
