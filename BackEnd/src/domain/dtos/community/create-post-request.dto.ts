/**
 * @file create-post-request.dto.ts
 * @description DTO de creación de post. Se completará en Fase 3.
 * @module Community
 * @layer Domain
 */
import { IsString, IsOptional, MaxLength } from 'class-validator';

export class CreatePostRequestDto {
  @IsString() @MaxLength(1000) content!: string;
  @IsOptional() @IsString() imageUrl?: string;
  @IsOptional() @IsString() plantId?: string;
}
