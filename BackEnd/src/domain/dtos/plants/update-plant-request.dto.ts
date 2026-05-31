/**
 * @file update-plant-request.dto.ts
 * @description DTO de actualización de planta (todos los campos son opcionales).
 * Compromiso TFG: decoradores de validación en DTO de dominio para simplificar la arquitectura.
 * @module Plants
 * @layer Domain
 */

import {
  IsString, IsOptional, IsInt, IsNumber, Min, Max,
  IsIn, IsBoolean, MaxLength, IsDateString,
} from 'class-validator';
import { Type } from 'class-transformer';

/**
 * DTO de actualización parcial de planta.
 * Solo se actualizan los campos enviados (PATCH semantics).
 */
export class UpdatePlantRequestDTO {
  @IsOptional()
  @IsString()
  @MaxLength(100)
  name?: string;

  @IsOptional()
  @IsString()
  speciesId?: string;

  @IsOptional()
  @IsString()
  photo?: string;

  @IsOptional()
  @IsIn(['Interior', 'Exterior'])
  location?: 'Interior' | 'Exterior';

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(365)
  wateringFrequency?: number;

  @IsOptional()
  @IsIn(['Low', 'Medium', 'High'])
  lightNeed?: 'Low' | 'Medium' | 'High';

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(365)
  pruningFrequency?: number;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;

  @IsOptional()
  @IsBoolean()
  considerWeatherForWatering?: boolean;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  plantLocation?: string;

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  plantLocationLat?: number;

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  plantLocationLon?: number;

  /** ISO-8601: fecha del último riego. Usada por el endpoint POST /plants/:id/water. */
  @IsOptional()
  @IsDateString()
  lastWatered?: string;
}
