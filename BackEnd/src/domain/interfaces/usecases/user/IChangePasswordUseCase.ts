/**
 * @file IChangePasswordUseCase.ts
 * @description Interfaz del caso de uso para cambiar la contraseña del usuario.
 * @module User
 * @layer Domain
 */
export interface IChangePasswordUseCase {
  execute(userId: string, currentPassword: string, newPassword: string): Promise<void>;
}
