/// @file comment_model.dart
/// @description Modelo de serialización de comentario para la capa de datos.
/// Solo fromJson/toJson. SIN lógica de negocio ni mapeo a entidad.
/// La conversión CommentModel ↔ Comment la realiza CommentMapper.
/// @module Community
/// @layer Data
library;

// ═══════════════════════════════════════════════════════════════════════════════
// COMMENT MODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// Modelo de serialización de un comentario. Refleja la estructura del CommentResponseDTO del backend.
///
/// Regla estricta: NO contiene lógica de negocio, validaciones ni referencias
/// a entidades de dominio. Solo fromJson y toJson.
class CommentModel {
  const CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.authorPhoto,
  });

  final String  id;
  final String  postId;
  final String  userId;
  final String  authorName;
  final String? authorPhoto;
  final String  content;
  final String  createdAt;   // ISO 8601 string tal como llega del servidor.

  // ─── Deserialización ─────────────────────────────────────────────────────────

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
    id:          json['_id']         as String? ?? json['id']   as String,
    postId:      json['postId']      as String,
    userId:      json['userId']      as String,
    authorName:  json['authorName']  as String,
    authorPhoto: json['authorPhoto'] as String?,
    content:     json['content']     as String,
    createdAt:   json['createdAt']   as String,
  );

  // ─── Serialización ────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id':         id,
    'postId':     postId,
    'userId':     userId,
    'authorName': authorName,
    if (authorPhoto != null) 'authorPhoto': authorPhoto,
    'content':    content,
    'createdAt':  createdAt,
  };
}
