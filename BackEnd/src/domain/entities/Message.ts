/**
 * @file Message.ts
 * @description Entidad de dominio que representa un mensaje en una conversación de chat.
 * @module Chat
 * @layer Domain
 */

/** Estados posibles de un mensaje en su ciclo de vida de entrega */
export type MessageStatus = 'pending' | 'sent' | 'delivered' | 'read';

/** Metadatos opcionales de contenido multimedia adjunto */
export interface ContentMeta {
  type?: 'image' | 'video' | 'file' | 'audio';
  url?: string;
  size?: number;
  mimeType?: string;
}

/**
 * Entidad de dominio Message.
 *
 * Representa un mensaje enviado por un usuario en una conversación.
 * Soporta texto y contenido multimedia. El tempId permite actualizaciones
 * optimistas en el cliente: se asigna en el lado cliente antes de la confirmación.
 */
export class Message {
  /** Identificador único del mensaje */
  readonly id: string;

  /** ID de la conversación a la que pertenece */
  readonly conversationId: string;

  /** ID del usuario que envió el mensaje */
  readonly senderId: string;

  /** ID del destinatario (para futuras conversaciones de grupo) */
  readonly receiverId?: string;

  /** Texto del mensaje (opcional en mensajes solo-media) */
  readonly text?: string;

  /** Metadatos de contenido multimedia adjunto */
  readonly contentMeta?: ContentMeta;

  /** Estado de entrega del mensaje */
  readonly status: MessageStatus;

  /** ID temporal asignado por el cliente para actualizaciones optimistas */
  readonly tempId?: string;

  /** Fecha de creación del mensaje */
  readonly createdAt: Date;

  /** Fecha de última modificación (actualización de estado) */
  readonly updatedAt: Date;

  constructor(params: {
    id: string;
    conversationId: string;
    senderId: string;
    receiverId?: string;
    text?: string;
    contentMeta?: ContentMeta;
    status: MessageStatus;
    tempId?: string;
    createdAt: Date;
    updatedAt: Date;
  }) {
    this.id             = params.id;
    this.conversationId = params.conversationId;
    this.senderId       = params.senderId;
    this.receiverId     = params.receiverId;
    this.text           = params.text;
    this.contentMeta    = params.contentMeta;
    this.status         = params.status;
    this.tempId         = params.tempId;
    this.createdAt      = params.createdAt;
    this.updatedAt      = params.updatedAt;
  }

  /** true si el mensaje ha sido leído por el destinatario */
  get isRead(): boolean {
    return this.status === 'read';
  }
}
