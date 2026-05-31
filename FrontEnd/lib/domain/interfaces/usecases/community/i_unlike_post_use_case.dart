/// @file i_unlike_post_use_case.dart
/// @description Interfaz: Quita el like de un post.
/// @module Community
/// @layer Domain
library;
abstract interface class IUnlikePostUseCase {
  /// Quita el like de un post.
  Future<void> execute(String postId);
}
