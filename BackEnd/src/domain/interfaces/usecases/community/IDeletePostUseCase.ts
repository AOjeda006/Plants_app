/**
 * @file IDeletePostUseCase.ts
 * @description Interfaz del caso de uso para eliminar un post propio.
 * @module Community
 * @layer Domain
 */

/**
 * Contrato del use case DeletePost.
 * Valida que el usuario sea el propietario del post antes de eliminarlo.
 */
export interface IDeletePostUseCase {
  /**
   * Ejecuta el caso de uso.
   *
   * @param postId — Id del post a eliminar.
   * @param userId — Id del usuario que solicita la eliminación (debe ser el autor).
   * @throws NotFoundException — Si el post no existe.
   * @throws ForbiddenException — Si el usuario no es el autor del post.
   */
  execute(postId: string, userId: string): Promise<void>;
}
