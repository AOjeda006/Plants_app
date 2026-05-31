/**
 * @file IUnlikePostUseCase.ts
 * @description Interfaz del caso de uso para quitar el like de un post.
 * @module Community
 * @layer Domain
 */
export interface IUnlikePostUseCase {
  execute(postId: string, userId: string): Promise<void>;
}
