/**
 * @file IExportUserDataUseCase.ts
 * @description Interfaz del caso de uso de exportación de datos personales (RGPD).
 * @module User
 * @layer Domain
 */

/**
 * Contrato del caso de uso de exportación de datos.
 * Devuelve un objeto JSON con todos los datos personales del usuario.
 */
export interface IExportUserDataUseCase {
  /**
   * @param userId — ID del usuario autenticado.
   * @returns Objeto con perfil, plantas y metadatos de exportación.
   * @throws {NotFoundException} Si el usuario no existe.
   */
  execute(userId: string): Promise<Record<string, unknown>>;
}
