/**
 * @file Conversation.ts
 * @description Entidad de dominio que representa una conversación privada entre dos usuarios.
 * @module Chat
 * @layer Domain
 */

/**
 * Entidad de dominio Conversation.
 *
 * Representa una conversación 1-a-1 entre dos participantes.
 * La unicidad del par (participantA + participantB) se gestiona en el repositorio.
 */
export class Conversation {
  /** Identificador único de la conversación */
  readonly id: string;

  /** IDs de los usuarios participantes (siempre 2 en esta versión TFG) */
  readonly participants: string[];

  /** Fecha del último mensaje enviado en esta conversación */
  readonly lastMessageAt?: Date;

  /** Fecha de creación de la conversación */
  readonly createdAt: Date;

  /** Fecha de última modificación */
  readonly updatedAt: Date;

  /** Borrado lógico; null si activa */
  readonly deletedAt?: Date | null;

  constructor(params: {
    id: string;
    participants: string[];
    lastMessageAt?: Date;
    createdAt: Date;
    updatedAt: Date;
    deletedAt?: Date | null;
  }) {
    this.id            = params.id;
    this.participants  = params.participants;
    this.lastMessageAt = params.lastMessageAt;
    this.createdAt     = params.createdAt;
    this.updatedAt     = params.updatedAt;
    this.deletedAt     = params.deletedAt;
  }

  /** true si la conversación no ha sido eliminada lógicamente */
  get isActive(): boolean {
    return !this.deletedAt;
  }

  /**
   * Devuelve el ID del otro participante dado el ID del usuario actual.
   *
   * @param myUserId — ID del usuario que consulta.
   * @returns ID del otro participante, o undefined si no es un participante.
   */
  getOtherParticipantId(myUserId: string): string | undefined {
    return this.participants.find(id => id !== myUserId);
  }
}
