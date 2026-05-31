/// @file post.dart
/// @description Entidad de dominio Post. Representa una publicación en el feed de la comunidad.
/// Objeto puro de Dart, sin dependencias de Flutter ni paquetes externos.
/// Los mappers convierten PostModel ↔ Post.
/// @module Community
/// @layer Domain
library;

// ═══════════════════════════════════════════════════════════════════════════════
// POST ENTITY
// ═══════════════════════════════════════════════════════════════════════════════

/// Entidad de dominio que representa un post de la comunidad.
///
/// Incluye datos del autor embebidos (authorName, authorPhoto) para evitar
/// llamadas adicionales al cargar el feed (desnormalización de lectura).
/// Todos los campos son inmutables (final). Usar [copyWith] para actualizaciones.
class Post {
  const Post({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.content,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    required this.updatedAt,
    required this.isLikedByMe,
    this.authorPhoto,
    this.image,
  });

  /// Identificador único del post (MongoDB ObjectId como String).
  final String id;

  /// ID del usuario autor del post.
  final String userId;

  /// Nombre visible del autor (embebido para rendimiento en feed).
  final String authorName;

  /// URL de la foto de perfil del autor (Cloudinary), o null si no tiene.
  final String? authorPhoto;

  /// Contenido textual del post (máx. 1000 caracteres).
  final String content;

  /// URL de la imagen adjunta al post (Cloudinary), o null si no tiene.
  final String? image;

  /// true si el usuario autenticado ya dio like a este post.
  final bool isLikedByMe;

  /// Número de likes acumulados (desnormalizado en base de datos).
  final int likesCount;

  /// Número de comentarios acumulados (desnormalizado en base de datos).
  final int commentsCount;

  /// Fecha UTC de creación del post.
  final DateTime createdAt;

  /// Fecha UTC de la última actualización.
  final DateTime updatedAt;

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// true si el post tiene imagen adjunta.
  bool get hasImage => image != null && image!.isNotEmpty;

  /// true si el autor tiene foto de perfil.
  bool get hasAuthorPhoto => authorPhoto != null && authorPhoto!.isNotEmpty;

  /// true si el post tiene al menos un like.
  bool get hasLikes => likesCount > 0;

  /// true si el post tiene al menos un comentario.
  bool get hasComments => commentsCount > 0;

  // ─── copyWith ────────────────────────────────────────────────────────────────

  /// Devuelve una copia del post con los campos indicados modificados.
  /// Útil para actualizaciones optimistas de likesCount y commentsCount.
  Post copyWith({
    String?   id,
    String?   userId,
    String?   authorName,
    String?   authorPhoto,
    String?   content,
    String?   image,
    int?      likesCount,
    int?      commentsCount,
    bool?     isLikedByMe,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Post(
      id:            id            ?? this.id,
      userId:        userId        ?? this.userId,
      authorName:    authorName    ?? this.authorName,
      authorPhoto:   authorPhoto   ?? this.authorPhoto,
      content:       content       ?? this.content,
      image:         image         ?? this.image,
      likesCount:    likesCount    ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLikedByMe:   isLikedByMe   ?? this.isLikedByMe,
      createdAt:     createdAt     ?? this.createdAt,
      updatedAt:     updatedAt     ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Post && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Post(id: $id, userId: $userId, likesCount: $likesCount)';
}
