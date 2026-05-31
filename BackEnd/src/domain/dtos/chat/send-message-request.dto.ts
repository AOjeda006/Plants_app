/**
 * @file send-message-request.dto.ts
 * @description DTO de envío de mensaje en una conversación.
 * El conversationId viene del parámetro de ruta URL (no se incluye en el body).
 * @module Chat
 * @layer Domain
 */

import { IsString, IsOptional, MaxLength, IsObject } from 'class-validator';

/**
 * Datos del body para enviar un mensaje en una conversación existente.
 */
export class SendMessageRequestDto {
  /** Texto del mensaje (opcional si se adjunta contenido multimedia) */
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  text?: string;

  /** Metadatos de contenido multimedia adjunto */
  @IsOptional()
  @IsObject()
  contentMeta?: Record<string, unknown>;

  /** ID temporal asignado por el cliente para actualizaciones optimistas */
  @IsOptional()
  @IsString()
  tempId?: string;
}
