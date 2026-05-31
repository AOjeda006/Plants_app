/// @file i_post_mapper.dart
/// @description Interfaz del mapper de posts de comunidad. Contrato PostModel ↔ Post.
/// @module Community
/// @layer Data
library;

import '../../domain/entities/post.dart';
import '../models/post_model.dart';

/// Contrato para la conversión bidireccional entre PostModel y Post.
///
/// Los repositorios dependen de esta interfaz para no acoplarse a la
/// implementación concreta del mapper.
abstract interface class IPostMapper {
  /// Convierte un modelo de serialización a entidad de dominio.
  ///
  /// [param] model — PostModel obtenido desde la API o caché.
  /// [returns] Post — Entidad inmutable de dominio.
  Post toEntity(PostModel model);

  /// Convierte una entidad de dominio a modelo de serialización.
  ///
  /// [param] entity — Post de dominio.
  /// [returns] PostModel — Modelo listo para serializar a JSON.
  PostModel toModel(Post entity);
}
