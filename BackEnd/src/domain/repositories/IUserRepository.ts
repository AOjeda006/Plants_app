/**
 * @file IUserRepository.ts
 * @description Interfaz del repositorio de usuarios.
 * Define el contrato que deben cumplir todas las implementaciones concretas.
 * Los use cases dependen de esta interfaz, nunca de implementaciones concretas.
 * @module Auth
 * @layer Domain
 */

import { ClientSession } from 'mongodb';
import { User } from '../entities/User.js';

/**
 * Contrato del repositorio de usuarios.
 * La implementación concreta vive en data/repositories/user_repository_impl.ts.
 */
export interface IUserRepository {
  /**
   * Busca un usuario por su identificador único.
   *
   * @param id — ObjectId serializado como string.
   * @returns El usuario encontrado o null si no existe.
   */
  findById(id: string): Promise<User | null>;

  /**
   * Busca un usuario por su email (case-insensitive).
   *
   * @param email — Email del usuario.
   * @returns El usuario encontrado o null si no existe.
   */
  findByEmail(email: string): Promise<User | null>;

  /**
   * Persiste un nuevo usuario en la base de datos.
   *
   * @param user — Entidad User a crear (sin id, se genera en el repositorio).
   * @param session — Sesión de transacción opcional.
   * @returns El usuario creado con su id asignado.
   */
  create(user: Omit<User, 'id'>, session?: ClientSession): Promise<User>;

  /**
   * Actualiza los campos de un usuario existente.
   *
   * @param id — Identificador del usuario a actualizar.
   * @param data — Campos a actualizar (parcial).
   * @param session — Sesión de transacción opcional.
   * @returns El usuario actualizado.
   * @throws {NotFoundException} Si el usuario no existe.
   */
  update(id: string, data: Partial<Omit<User, 'id' | 'createdAt'>>, session?: ClientSession): Promise<User>;

  /**
   * Elimina un usuario de la base de datos.
   *
   * @param id — Identificador del usuario.
   * @param soft — Si true, realiza borrado lógico (deletedAt). Si false, borrado físico.
   * @param session — Sesión de transacción opcional.
   * @throws {NotFoundException} Si el usuario no existe.
   */
  delete(id: string, soft?: boolean, session?: ClientSession): Promise<void>;
}
