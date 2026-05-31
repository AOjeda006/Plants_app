/// @file post_model.dart
/// @description Modelo de serialización de post para la capa de datos.
/// Solo fromJson/toJson. SIN lógica de negocio ni mapeo a entidad.
/// La conversión PostModel ↔ Post la realiza PostMapper.
/// @module Community
/// @layer Data
library;

// ═══════════════════════════════════════════════════════════════════════════════
// POST MODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// Modelo de serialización de un post. Refleja la estructura del PostResponseDTO del backend.
///
/// Regla estricta: NO contiene lógica de negocio, validaciones ni referencias
/// a entidades de dominio. Solo fromJson y toJson.
class PostModel {
  const PostModel({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.content,
    required this.likesCount,
    required this.commentsCount,
    required this.isLikedByMe,
    required this.createdAt,
    required this.updatedAt,
    this.authorPhoto,
    this.image,
  });

  final String  id;
  final String  userId;
  final String  authorName;
  final String? authorPhoto;
  final String  content;
  final String? image;
  final int     likesCount;
  final int     commentsCount;
  final bool    isLikedByMe;  // Lo aporta el backend en cada respuesta del feed.
  final String  createdAt;   // ISO 8601 string tal como llega del servidor.
  final String  updatedAt;   // ISO 8601 string tal como llega del servidor.

  // ─── Deserialización ─────────────────────────────────────────────────────────

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
    // El backend puede devolver _id (MongoDB) o id.
    id:            json['_id']           as String? ?? json['id']    as String,
    userId:        json['userId']        as String,
    authorName:    json['authorName']    as String,
    authorPhoto:   json['authorPhoto']   as String?,
    content:       json['content']       as String,
    image:         json['image']         as String?,
    likesCount:    json['likesCount']    as int? ?? 0,
    commentsCount: json['commentsCount'] as int? ?? 0,
    isLikedByMe:   json['isLikedByMe']  as bool? ?? false,
    createdAt:     json['createdAt']     as String,
    updatedAt:     json['updatedAt']     as String,
  );

  // ─── Serialización ────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id':            id,
    'userId':        userId,
    'authorName':    authorName,
    if (authorPhoto != null) 'authorPhoto': authorPhoto,
    'content':       content,
    if (image       != null) 'image':       image,
    'likesCount':    likesCount,
    'commentsCount': commentsCount,
    'createdAt':     createdAt,
    'updatedAt':     updatedAt,
  };
}
