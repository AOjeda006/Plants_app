/// @file post_mapper.dart
/// @description Implementación del mapper de posts de comunidad.
/// Convierte PostModel ↔ Post normalizando tipos y parsando fechas.
/// Toda la lógica de transformación vive aquí, nunca en el Model ni en la entidad.
/// @module Community
/// @layer Data
library;

import '../../domain/entities/post.dart';
import '../i_mappers/i_post_mapper.dart';
import '../models/post_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// POST MAPPER
// ═══════════════════════════════════════════════════════════════════════════════

/// Implementación de [IPostMapper].
///
/// [implements] IPostMapper
/// [injectable] registrar en container.dart como singleton.
class PostMapper implements IPostMapper {

  // ─── PostModel → Post ─────────────────────────────────────────────────────────

  @override
  Post toEntity(PostModel model) {
    return Post(
      id:            model.id,
      userId:        model.userId,
      authorName:    model.authorName,
      authorPhoto:   model.authorPhoto,
      content:       model.content,
      image:         model.image,
      likesCount:    model.likesCount,
      commentsCount: model.commentsCount,
      isLikedByMe:   model.isLikedByMe,
      // Parsear ISO 8601 → DateTime UTC.
      createdAt:     DateTime.parse(model.createdAt).toUtc(),
      updatedAt:     DateTime.parse(model.updatedAt).toUtc(),
    );
  }

  // ─── Post → PostModel ─────────────────────────────────────────────────────────

  @override
  PostModel toModel(Post entity) {
    return PostModel(
      id:            entity.id,
      userId:        entity.userId,
      authorName:    entity.authorName,
      authorPhoto:   entity.authorPhoto,
      content:       entity.content,
      image:         entity.image,
      likesCount:    entity.likesCount,
      commentsCount: entity.commentsCount,
      isLikedByMe:   entity.isLikedByMe,
      createdAt:     entity.createdAt.toIso8601String(),
      updatedAt:     entity.updatedAt.toIso8601String(),
    );
  }
}
