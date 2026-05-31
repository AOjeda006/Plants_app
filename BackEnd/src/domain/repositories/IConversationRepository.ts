/**
 * @file IConversationRepository.ts
 * @description Interfaz del repositorio de conversaciones de chat. Define el contrato de
 * acceso a datos sin acoplar la capa de dominio a ninguna implementación concreta.
 * @module Chat
 * @layer Domain
 */

import type { ClientSession } from 'mongodb';
import type { Conversation } from '../entities/Conversation.js';

/**
 * Contrato del repositorio de conversaciones.
 * Los use cases dependen de esta interfaz, nunca de la implementación concreta.
 */
export interface IConversationRepository {
  /**
   * Obtiene todas las conversaciones activas en las que participa el usuario.
   * Ordenadas por lastMessageAt descendente.
   *
   * @param userId — ID del usuario participante.
   * @returns Lista de conversaciones del usuario.
   */
  findByUserId(userId: string): Promise<Conversation[]>;

  /**
   * Busca una conversación por su ID.
   *
   * @param id — ID de la conversación.
   * @returns Conversación encontrada o null.
   */
  findById(id: string): Promise<Conversation | null>;

  /**
   * Busca una conversación existente entre dos usuarios (1-a-1).
   * Útil para el patrón "get or create".
   *
   * @param userIdA — ID del primer participante.
   * @param userIdB — ID del segundo participante.
   * @returns Conversación encontrada o null.
   */
  findByParticipants(userIdA: string, userIdB: string): Promise<Conversation | null>;

  /**
   * Crea una nueva conversación entre dos usuarios.
   *
   * @param participantA — ID del primer participante.
   * @param participantB — ID del segundo participante.
   * @param session — Sesión de transacción opcional.
   * @returns Conversación creada con id asignado.
   */
  create(participantA: string, participantB: string, session?: ClientSession): Promise<Conversation>;

  /**
   * Actualiza la fecha del último mensaje de la conversación.
   * Se llama al persistir un nuevo mensaje.
   *
   * @param id — ID de la conversación.
   * @param date — Fecha del nuevo mensaje.
   * @param session — Sesión de transacción opcional.
   */
  updateLastMessageAt(id: string, date: Date, session?: ClientSession): Promise<void>;
}
