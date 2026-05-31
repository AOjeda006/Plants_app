/// @file i_get_feed_use_case.dart
/// @description Interfaz: Obtiene el feed paginado de la comunidad.
/// @module Community
/// @layer Domain
library;

import '../../../entities/post.dart';

abstract interface class IGetFeedUseCase {
  /// Obtiene la página [page] del feed de la comunidad.
  ///
  /// [param] page     — Número de página (1-based, default 1).
  /// [param] limit    — Posts por página (default 20).
  /// [param] authorId — Si se proporciona, devuelve solo posts de ese autor (perfil propio).
  ///                    Si no, es el feed de comunidad (excluye propios en el backend).
  /// [returns] Lista de [Post] del feed.
  Future<List<Post>> execute({int page = 1, int limit = 20, String? authorId});
}
