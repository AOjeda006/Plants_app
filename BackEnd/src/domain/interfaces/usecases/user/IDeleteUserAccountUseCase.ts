/**
 * @file IDeleteUserAccountUseCase.ts
 * @description Interfaz del caso de uso para eliminar la cuenta del usuario (soft-delete).
 * @module User
 * @layer Domain
 */
export interface IDeleteUserAccountUseCase {
  /**
   * @param userId          — ID del usuario autenticado.
   * @param password        — Contraseña actual para confirmar la eliminación.
   * @param preserveContent — Si true, las publicaciones y comentarios del usuario
   *                          se mantienen (anónimos). Si false (default), se eliminan.
   */
  execute(userId: string, password: string, preserveContent?: boolean): Promise<void>;
}
