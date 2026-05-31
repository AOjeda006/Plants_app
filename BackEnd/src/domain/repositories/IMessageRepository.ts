/**
 * @file IMessageRepository.ts
 * @description Interfaz del repositorio de mensajes de chat. Define el contrato de
 * acceso a datos sin acoplar la capa de dominio a ninguna implementación concreta.
 * @module Chat
 * @layer Domain
 */

import type { ClientSession } from 'mongodb';
import type { Message, MessageStatus, ContentMeta } from '../entities/Message.js';

/**
 * Datos necesarios para crear un mensaje. Agrupar los parámetros en este
 * objeto mejora la legibilidad del call site frente a una firma con 6
 * parámetros posicionales y permite añadir campos opcionales en el
 * futuro sin tocar la firma.
 */
export interface CreateMessageInput {
  conversationId: string;
  senderId:       string;
  receiverId:     string;
  text?:          string;
  contentMeta?:   ContentMeta;
  tempId?:        string;
}

/**
 * Contrato del repositorio de mensajes.
 * Los use cases dependen de esta interfaz, nunca de la implementación concreta.
 */
export interface IMessageRepository {
  /**
   * Obtiene mensajes paginados de una conversación, ordenados por fecha descendente.
   *
   * @param conversationId — ID de la conversación.
   * @param page — Número de página (base 1). Por defecto 1.
   * @param limit — Elementos por página. Por defecto 30.
   * @returns Lista de mensajes.
   */
  findByConversationId(conversationId: string, page?: number, limit?: number): Promise<Message[]>;

  /**
   * Obtiene el último mensaje de una conversación.
   * Usado para enriquecer la lista de conversaciones.
   *
   * @param conversationId — ID de la conversación.
   * @returns Último mensaje o null si la conversación está vacía.
   */
  findLastByConversationId(conversationId: string): Promise<Message | null>;

  /**
   * Busca un mensaje por su tempId de cliente (para matching de ACK optimistas).
   *
   * @param tempId — ID temporal asignado por el cliente.
   * @returns Mensaje encontrado o null.
   */
  findByTempId(tempId: string): Promise<Message | null>;

  /**
   * Crea y persiste un nuevo mensaje en la base de datos.
   *
   * @param input — Datos del mensaje agrupados (CreateMessageInput).
   * @param session — Sesión de transacción opcional.
   * @returns Mensaje creado con id asignado.
   */
  create(input: CreateMessageInput, session?: ClientSession): Promise<Message>;

  /**
   * Actualiza el estado de un mensaje (pending → delivered → read).
   *
   * @param id — ID del mensaje.
   * @param status — Nuevo estado.
   * @param session — Sesión de transacción opcional.
   */
  updateStatus(id: string, status: MessageStatus, session?: ClientSession): Promise<void>;

  /**
   * Marca todos los mensajes no leídos en una conversación como leídos para un usuario.
   * Solo marca los mensajes enviados por el otro participante.
   *
   * @param conversationId — ID de la conversación.
   * @param userId — ID del usuario que lee los mensajes.
   * @param session — Sesión de transacción opcional.
   */
  markAsRead(conversationId: string, userId: string, session?: ClientSession): Promise<void>;

  /**
   * Cuenta los mensajes no leídos en una conversación para un usuario.
   * Solo cuenta los mensajes que no fueron enviados por ese usuario.
   *
   * @param conversationId — ID de la conversación.
   * @param userId — ID del usuario que consulta.
   * @returns Número de mensajes no leídos.
   */
  countUnread(conversationId: string, userId: string): Promise<number>;

  /**
   * Devuelve los IDs distintos de senders que tienen mensajes NO leídos
   * dirigidos al receptor dado. Se usa para decidir el título del push:
   * si hay un único sender → "Tienes nuevos mensajes de [Nombre]";
   * si hay varios → "Tienes nuevos mensajes de Varios usuarios".
   *
   * @param receiverId — ID del usuario receptor de los mensajes.
   * @returns Lista de IDs distintos de senders con mensajes pendientes.
   */
  findDistinctUnreadSenderIds(receiverId: string): Promise<string[]>;
}
