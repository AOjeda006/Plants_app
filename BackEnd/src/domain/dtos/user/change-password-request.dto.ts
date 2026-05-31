/**
 * @file change-password-request.dto.ts
 * @description DTO de cambio de contraseña. Se completará en Fase 2.
 * @module User
 * @layer Domain
 */
import { IsString, MinLength } from 'class-validator';

export class ChangePasswordRequestDto {
  @IsString() currentPassword!: string;
  @IsString() @MinLength(8) newPassword!: string;
}
