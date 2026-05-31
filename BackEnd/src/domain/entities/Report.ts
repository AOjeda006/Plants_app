/**
 * @file Report.ts
 * @description Entidad de dominio que representa un reporte de incidencia enviado
 * por un usuario sobre contenido de la plataforma.
 * Persiste en MongoDB en la colección 'reports'.
 * @module Admin
 * @layer Domain
 */

/** Tipos de reporte: incidencia general, post o comentario específico */
export type ReportType = 'general' | 'post' | 'comment';

/** Estado del ciclo de vida de un reporte */
export type ReportStatus = 'pending' | 'resolved' | 'dismissed';

/** Información del admin que resolvió/descartó un reporte */
export interface ResolvedByInfo {
  adminId:    string;
  adminName:  string;
  resolvedAt: Date;
}

/**
 * Entidad Report.
 * Representa una incidencia reportada por un usuario sobre la plataforma.
 */
export class Report {
  readonly id:           string;
  /** Id del usuario que envía el reporte */
  readonly userId:       string;
  /** Tipo de reporte */
  readonly type:         ReportType;
  /** Id del post o comentario reportado (undefined para reportes generales) */
  readonly targetId?:    string;
  /** Descripción de la incidencia */
  readonly text:         string;
  /** URL de imagen adjunta (opcional) */
  readonly imageUrl?:    string;
  /** Estado actual del reporte */
  readonly status:       ReportStatus;
  /** Número de ticket visible, auto-incrementado (ej: "INC-001") */
  readonly ticketNumber: number;
  /** Información del admin que resolvió/descartó el reporte */
  readonly resolvedBy?:  ResolvedByInfo;
  readonly createdAt:    Date;

  constructor(params: {
    id:           string;
    userId:       string;
    type:         ReportType;
    targetId?:    string;
    text:         string;
    imageUrl?:    string;
    status:       ReportStatus;
    ticketNumber: number;
    resolvedBy?:  ResolvedByInfo;
    createdAt:    Date;
  }) {
    this.id           = params.id;
    this.userId       = params.userId;
    this.type         = params.type;
    this.targetId     = params.targetId;
    this.text         = params.text;
    this.imageUrl     = params.imageUrl;
    this.status       = params.status;
    this.ticketNumber = params.ticketNumber;
    this.resolvedBy   = params.resolvedBy;
    this.createdAt    = params.createdAt;
  }
}
