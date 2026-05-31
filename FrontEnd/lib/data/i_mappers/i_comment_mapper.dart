/// @file i_comment_mapper.dart
/// @description Interfaz del mapper de comentarios de posts. Contrato CommentModel ↔ Comment.
/// @module Community
/// @layer Data
library;

import '../../domain/entities/comment.dart';
import '../models/comment_model.dart';

/// Contrato para la conversión bidireccional entre CommentModel y Comment.
///
/// Los repositorios dependen de esta interfaz para no acoplarse a la
/// implementación concreta del mapper.
abstract interface class ICommentMapper {
  /// Convierte un modelo de serialización a entidad de dominio.
  ///
  /// [param] model — CommentModel obtenido desde la API.
  /// [returns] Comment — Entidad inmutable de dominio.
  Comment toEntity(CommentModel model);

  /// Convierte una entidad de dominio a modelo de serialización.
  ///
  /// [param] entity — Comment de dominio.
  /// [returns] CommentModel — Modelo listo para serializar a JSON.
  CommentModel toModel(Comment entity);
}
