/// @file comment_mapper.dart
/// @description Implementación del mapper de comentarios de la comunidad.
/// Convierte CommentModel ↔ Comment normalizando tipos y parsando fechas.
/// Toda la lógica de transformación vive aquí, nunca en el Model ni en la entidad.
/// @module Community
/// @layer Data
library;

import '../../domain/entities/comment.dart';
import '../i_mappers/i_comment_mapper.dart';
import '../models/comment_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// COMMENT MAPPER
// ═══════════════════════════════════════════════════════════════════════════════

/// Implementación de [ICommentMapper].
///
/// [implements] ICommentMapper
/// [injectable] registrar en container.dart como singleton.
class CommentMapper implements ICommentMapper {

  // ─── CommentModel → Comment ───────────────────────────────────────────────────

  @override
  Comment toEntity(CommentModel model) {
    return Comment(
      id:          model.id,
      postId:      model.postId,
      userId:      model.userId,
      authorName:  model.authorName,
      authorPhoto: model.authorPhoto,
      content:     model.content,
      // Parsear ISO 8601 → DateTime UTC.
      createdAt:   DateTime.parse(model.createdAt).toUtc(),
    );
  }

  // ─── Comment → CommentModel ───────────────────────────────────────────────────

  @override
  CommentModel toModel(Comment entity) {
    return CommentModel(
      id:          entity.id,
      postId:      entity.postId,
      userId:      entity.userId,
      authorName:  entity.authorName,
      authorPhoto: entity.authorPhoto,
      content:     entity.content,
      createdAt:   entity.createdAt.toIso8601String(),
    );
  }
}
