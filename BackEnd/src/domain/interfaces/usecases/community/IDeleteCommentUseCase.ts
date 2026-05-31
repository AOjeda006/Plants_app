/**
 * @file IDeleteCommentUseCase.ts
 * @description Interfaz del caso de uso para eliminar un comentario propio.
 * @module Community
 * @layer Domain
 */

/**
 * Contrato del use case DeleteComment.
 * Valida que el usuario sea el propietario del comentario antes de eliminarlo.
 */
export interface IDeleteCommentUseCase {
  /**
   * Ejecuta el caso de uso.
   *
   * @param commentId — Id del comentario a eliminar.
   * @param userId — Id del usuario que solicita la eliminación (debe ser el autor).
   * @throws NotFoundException — Si el comentario no existe.
   * @throws ForbiddenException — Si el usuario no es el autor del comentario.
   */
  execute(commentId: string, userId: string): Promise<void>;
}
