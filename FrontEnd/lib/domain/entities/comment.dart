/// @file comment.dart
/// @description Entidad de dominio Comment. Representa un comentario en un post de la comunidad.
/// Objeto puro de Dart, sin dependencias de Flutter ni paquetes externos.
/// Los mappers convierten CommentModel ↔ Comment.
/// @module Community
/// @layer Domain
library;

// ═══════════════════════════════════════════════════════════════════════════════
// COMMENT ENTITY
// ═══════════════════════════════════════════════════════════════════════════════

/// Entidad de dominio que representa un comentario de la comunidad.
///
/// Incluye datos del autor embebidos (authorName, authorPhoto) para evitar
/// llamadas adicionales al mostrar la lista de comentarios.
class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.authorPhoto,
  });

  /// Identificador único del comentario (MongoDB ObjectId como String).
  final String id;

  /// ID del post al que pertenece este comentario.
  final String postId;

  /// ID del usuario autor del comentario.
  final String userId;

  /// Nombre visible del autor (embebido para rendimiento).
  final String authorName;

  /// URL de la foto de perfil del autor (Cloudinary), o null si no tiene.
  final String? authorPhoto;

  /// Texto del comentario.
  final String content;

  /// Fecha UTC de creación del comentario.
  final DateTime createdAt;

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// true si el autor tiene foto de perfil.
  bool get hasAuthorPhoto => authorPhoto != null && authorPhoto!.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Comment && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Comment(id: $id, postId: $postId, userId: $userId)';
}
