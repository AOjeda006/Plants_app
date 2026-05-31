/**
 * @file INotificationRepository.ts
 * @description Interfaz del repositorio de notificaciones in-app.
 * @module Reminders
 * @layer Domain
 */

import type { Notification } from '../entities/Notification.js';

export interface INotificationRepository {
  /**
   * Devuelve las notificaciones de un usuario ordenadas por fecha descendente.
   *
   * @param userId — Id del usuario.
   * @returns Lista de notificaciones.
   */
  findByUserId(userId: string): Promise<Notification[]>;

  /**
   * Crea una notificación nueva.
   *
   * @param data — Datos sin id.
   * @returns Notificación creada.
   */
  create(data: Omit<Notification, 'id'>): Promise<Notification>;

  /**
   * Cuenta las notificaciones creadas hoy para un usuario.
   *
   * @param userId — Id del usuario.
   * @returns Número de notificaciones creadas hoy.
   */
  countTodayByUserId(userId: string): Promise<number>;

  /**
   * Marca como leídas todas las notificaciones de un usuario.
   *
   * @param userId — Id del usuario.
   */
  markAllReadByUserId(userId: string): Promise<void>;

  /**
   * Marca como leídas las notificaciones con los ids indicados (del usuario).
   *
   * @param userId — Id del usuario.
   * @param ids — Ids de notificaciones a marcar.
   */
  markReadByIds(userId: string, ids: string[]): Promise<void>;

  /**
   * Elimina todas las notificaciones de un usuario.
   *
   * @param userId — Id del usuario.
   */
  deleteAllByUserId(userId: string): Promise<void>;

  /**
   * Elimina las notificaciones con los ids indicados (del usuario).
   *
   * @param userId — Id del usuario.
   * @param ids — Ids de notificaciones a eliminar.
   */
  deleteByIds(userId: string, ids: string[]): Promise<void>;
}
