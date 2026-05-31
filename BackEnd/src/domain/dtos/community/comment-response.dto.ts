/**
 * @file comment-response.dto.ts
 * @description DTO de respuesta HTTP para un comentario de la comunidad.
 * Incluye datos del autor enriquecidos (nombre y foto) para evitar llamadas adicionales.
 * @module Community
 * @layer Domain
 */

/**
 * DTO de respuesta para un comentario, con datos del autor embebidos.
 */
export interface CommentResponseDTO {
  id: string;
  postId: string;
  userId: string;
  authorName: string;
  authorPhoto?: string;
  content: string;
  createdAt: string;
}
