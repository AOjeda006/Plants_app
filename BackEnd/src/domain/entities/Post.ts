/**
 * @file Post.ts
 * @description Entidad de dominio que representa un post de la comunidad.
 * Objeto puro: sin dependencias de framework ni de base de datos.
 * @module Community
 * @layer Domain
 */

/**
 * Entidad de dominio Post.
 *
 * Representa una publicación en el feed de la comunidad.
 * Los contadores `likesCount` y `commentsCount` están desnormalizados
 * en el documento de MongoDB para evitar COUNT queries en el feed.
 */
export class Post {
  /** Identificador único (ObjectId de MongoDB serializado como string) */
  readonly id: string;

  /** ID del usuario autor del post */
  readonly userId: string;

  /** Contenido textual del post (máx. 1000 caracteres) */
  readonly content: string;

  /** URL de la imagen en Cloudinary, si se adjuntó una */
  readonly image?: string;

  /** Número de likes acumulados (desnormalizado para rendimiento) */
  readonly likesCount: number;

  /** Número de comentarios acumulados (desnormalizado para rendimiento) */
  readonly commentsCount: number;

  /** IDs de usuarios que han visto el post (para métricas de alcance) */
  readonly seenBy: string[];

  /** Fecha de creación del post */
  readonly createdAt: Date;

  /** Fecha de la última actualización */
  readonly updatedAt: Date;

  /** Fecha de borrado lógico. Si está definida, el post está eliminado */
  readonly deletedAt?: Date | null;

  constructor(params: {
    id: string;
    userId: string;
    content: string;
    image?: string;
    likesCount?: number;
    commentsCount?: number;
    seenBy?: string[];
    createdAt: Date;
    updatedAt: Date;
    deletedAt?: Date | null;
  }) {
    this.id            = params.id;
    this.userId        = params.userId;
    this.content       = params.content;
    this.image         = params.image;
    this.likesCount    = params.likesCount    ?? 0;
    this.commentsCount = params.commentsCount ?? 0;
    this.seenBy        = params.seenBy        ?? [];
    this.createdAt     = params.createdAt;
    this.updatedAt     = params.updatedAt;
    this.deletedAt     = params.deletedAt;
  }

  /** true si el post no ha sido eliminado lógicamente */
  get isActive(): boolean {
    return !this.deletedAt;
  }
}
