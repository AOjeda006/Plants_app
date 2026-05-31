/**
 * @file ILikePostUseCase.ts
 * @description Interfaz del caso de uso para dar like a un post.
 * @module Community
 * @layer Domain
 */
export interface ILikePostUseCase {
  execute(postId: string, userId: string): Promise<void>;
}
