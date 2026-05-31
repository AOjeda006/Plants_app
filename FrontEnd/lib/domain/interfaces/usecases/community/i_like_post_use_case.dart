/// @file i_like_post_use_case.dart
/// @description Interfaz: Da like a un post.
/// @module Community
/// @layer Domain
library;
abstract interface class ILikePostUseCase {
  /// Da like a un post.
  Future<void> execute(String postId);
}
