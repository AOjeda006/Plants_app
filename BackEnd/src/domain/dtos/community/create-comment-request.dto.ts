/**
 * @file create-comment-request.dto.ts
 * @description DTO de creación de comentario. Se completará en Fase 3.
 * @module Community
 * @layer Domain
 */
import { IsString, MaxLength } from 'class-validator';

export class CreateCommentRequestDto {
  @IsString() @MaxLength(500) content!: string;
}
