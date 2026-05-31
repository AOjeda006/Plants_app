/**
 * @file post-response.dto.ts
 * @description DTO de respuesta HTTP para un post de la comunidad.
 * Incluye datos del autor enriquecidos (nombre y foto) para evitar llamadas adicionales.
 * @module Community
 * @layer Domain
 */

/**
 * DTO de respuesta para un post, con datos del autor embebidos.
 */
export interface PostResponseDTO {
  id: string;
  userId: string;
  authorName: string;
  authorPhoto?: string;
  content: string;
  image?: string;
  likesCount: number;
  commentsCount: number;
  /** true si el usuario que solicitó el feed ya dio like a este post. */
  isLikedByMe: boolean;
  createdAt: string;
  updatedAt: string;
}
