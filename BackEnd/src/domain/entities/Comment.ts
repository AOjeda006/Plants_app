/**
 * @file Comment.ts
 * @description Entidad de dominio que representa un comentario en un post de la comunidad.
 * @module Community
 * @layer Domain
 */

/**
 * Entidad de dominio Comment.
 *
 * Representa un comentario escrito por un usuario en un post concreto.
 * Soporta borrado lógico mediante `deletedAt`.
 */
export class Comment {
  /** Identificador único del comentario */
  readonly id: string;

  /** ID del post al que pertenece el comentario */
  readonly postId: string;

  /** ID del usuario autor del comentario */
  readonly userId: string;

  /** Texto del comentario (máx. 500 caracteres) */
  readonly content: string;

  /** Fecha de creación del comentario */
  readonly createdAt: Date;

  /** Fecha de borrado lógico. Si está definida, el comentario está eliminado */
  readonly deletedAt?: Date | null;

  constructor(params: {
    id: string;
    postId: string;
    userId: string;
    content: string;
    createdAt: Date;
    deletedAt?: Date | null;
  }) {
    this.id        = params.id;
    this.postId    = params.postId;
    this.userId    = params.userId;
    this.content   = params.content;
    this.createdAt = params.createdAt;
    this.deletedAt = params.deletedAt;
  }

  /** true si el comentario no ha sido eliminado lógicamente */
  get isActive(): boolean {
    return !this.deletedAt;
  }
}
