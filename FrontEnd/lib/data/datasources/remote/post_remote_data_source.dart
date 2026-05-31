/// @file post_remote_data_source.dart
/// @description Datasource remoto para el módulo de comunidad (posts y comentarios).
/// Encapsula todas las llamadas HTTP al backend via ApiClient.
/// Devuelve JSON crudo (Map/List) — la conversión a modelos ocurre en el repositorio.
/// @module Community
/// @layer Data
library;

import '../../../core/network/api_client.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// POST REMOTE DATA SOURCE
// ═══════════════════════════════════════════════════════════════════════════════

/// Datasource que accede a los endpoints /community del backend.
///
/// [injectable] registrar en container.dart como singleton.
/// [dependencies] ApiClient.
class PostRemoteDataSource {
  final ApiClient _api;

  const PostRemoteDataSource({required ApiClient apiClient}) : _api = apiClient;

  // ─── Feed ─────────────────────────────────────────────────────────────────────

  /// Obtiene el feed paginado de la comunidad.
  ///
  /// Si [authorId] es null, devuelve el feed público (con la exclusión de
  /// posts propios que aplica el backend). Si [authorId] tiene valor,
  /// devuelve únicamente los posts de ese autor — usado por
  /// MyProfilePage (authorId == usuario actual) y UserProfilePage
  /// (authorId == otro usuario). Antes el flag `mine: true` enrutaba a
  /// `/community/mine`, que siempre devolvía los posts del autenticado
  /// e ignoraba el authorId del otro usuario.
  ///
  /// [param] page     — Número de página (1-based, default 1).
  /// [param] limit    — Posts por página (default 20).
  /// [param] authorId — Filtra el feed a posts de ese autor.
  /// [returns] Lista de mapas con estructura PostResponseDTO.
  /// [throws] AppError — Si la petición falla.
  Future<List<Map<String, dynamic>>> getFeed({
    int     page  = 1,
    int     limit = 20,
    String? authorId,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (authorId != null && authorId.isNotEmpty) {
      query['authorId'] = authorId;
    }
    final response = await _api.get<List<dynamic>>(
      '/community',
      queryParameters: query,
    );
    return response.cast<Map<String, dynamic>>();
  }

  // ─── Post individual ──────────────────────────────────────────────────────────

  /// Obtiene el detalle de un post por su ID.
  ///
  /// [param] postId — Identificador del post.
  /// [returns] Mapa con estructura PostResponseDTO.
  /// [throws] AppError — Si el post no existe o la petición falla.
  Future<Map<String, dynamic>> getPostById(String postId) async {
    return _api.get<Map<String, dynamic>>('/community/$postId');
  }

  // ─── Crear post ───────────────────────────────────────────────────────────────

  /// Crea un nuevo post en la comunidad.
  ///
  /// [param] data — JSON con `{ content, imageUrl?, plantId? }`.
  /// [returns] Mapa con estructura PostResponseDTO del post creado.
  /// [throws] AppError — Si la validación falla o la petición da error.
  Future<Map<String, dynamic>> createPost(Map<String, dynamic> data) async {
    return _api.post<Map<String, dynamic>>('/community', data: data);
  }

  // ─── Likes ────────────────────────────────────────────────────────────────────

  /// Da like a un post (idempotente — no falla si ya tiene like).
  ///
  /// [param] postId — Identificador del post.
  /// [throws] AppError — Si la petición falla.
  Future<void> likePost(String postId) async {
    await _api.post<void>('/community/$postId/like');
  }

  /// Quita el like de un post (idempotente — no falla si no tenía like).
  ///
  /// [param] postId — Identificador del post.
  /// [throws] AppError — Si la petición falla.
  Future<void> unlikePost(String postId) async {
    await _api.delete<void>('/community/$postId/like');
  }

  // ─── Comentarios ──────────────────────────────────────────────────────────────

  /// Obtiene los comentarios de un post.
  ///
  /// [param] postId — Identificador del post.
  /// [returns] Lista de mapas con estructura CommentResponseDTO.
  /// [throws] AppError — Si la petición falla.
  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    final response = await _api.get<List<dynamic>>('/community/$postId/comments');
    return response.cast<Map<String, dynamic>>();
  }

  /// Crea un comentario en un post.
  ///
  /// [param] postId  — Identificador del post.
  /// [param] content — Texto del comentario.
  /// [returns] Mapa con estructura CommentResponseDTO del comentario creado.
  /// [throws] AppError — Si la petición falla.
  Future<Map<String, dynamic>> createComment(String postId, String content) async {
    return _api.post<Map<String, dynamic>>(
      '/community/$postId/comments',
      data: {'content': content},
    );
  }

  // ─── Eliminación de contenido propio ────────────────────────────────────────

  /// Elimina un post propio (soft-delete). Valida ownership en el backend.
  ///
  /// [param] postId — Identificador del post.
  /// [throws] AppError — Si el post no existe, no es del usuario o la petición falla.
  Future<void> deletePost(String postId) async {
    await _api.delete<void>('/community/$postId');
  }

  /// Elimina un comentario propio (soft-delete). Valida ownership en el backend.
  /// Decrementa automáticamente commentsCount del post padre.
  ///
  /// [param] postId    — Identificador del post padre.
  /// [param] commentId — Identificador del comentario.
  /// [throws] AppError — Si el comentario no existe, no es del usuario o la petición falla.
  Future<void> deleteComment(String postId, String commentId) async {
    await _api.delete<void>('/community/$postId/comments/$commentId');
  }
}
