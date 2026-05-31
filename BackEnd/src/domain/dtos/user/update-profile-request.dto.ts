/**
 * @file update-profile-request.dto.ts
 * @description DTO de actualización de perfil de usuario. Se completará en Fase 2.
 * @module User
 * @layer Domain
 */
import { IsString, IsOptional, IsNumber, MaxLength } from 'class-validator';

export class UpdateProfileRequestDto {
  @IsOptional() @IsString() @MaxLength(50)  name?: string;
  @IsOptional() @IsString() @MaxLength(200) bio?: string;
  @IsOptional() @IsString() location?: string;
  /** Latitud de la ubicación seleccionada del catálogo de capitales */
  @IsOptional() @IsNumber() locationLat?: number;
  /** Longitud de la ubicación seleccionada del catálogo de capitales */
  @IsOptional() @IsNumber() locationLon?: number;
  /** URL Cloudinary de la foto de perfil */
  @IsOptional() @IsString() photo?: string;
  /** URL Cloudinary del banner/fondo de perfil */
  @IsOptional() @IsString() bannerPhoto?: string;
}
