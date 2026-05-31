/**
 * @file PostLike.ts
 * @description Entidad de dominio que representa un "me gusta" de un usuario en un post.
 * Es una entidad de relación pura sin lógica de negocio adicional.
 * @module Community
 * @layer Domain
 */

/**
 * Entidad de dominio PostLike.
 *
 * Registra que un usuario concreto ha dado like a un post concreto.
 * La unicidad (postId + userId) se garantiza a nivel de índice MongoDB.
 */
export class PostLike {
  /** Identificador único del like */
  readonly id: string;

  /** ID del post que recibe el like */
  readonly postId: string;

  /** ID del usuario que da el like */
  readonly userId: string;

  /** Fecha en que se registró el like */
  readonly createdAt: Date;

  constructor(params: {
    id: string;
    postId: string;
    userId: string;
    createdAt: Date;
  }) {
    this.id        = params.id;
    this.postId    = params.postId;
    this.userId    = params.userId;
    this.createdAt = params.createdAt;
  }
}
