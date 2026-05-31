/**
 * @file create-plant-request.dto.ts
 * @description DTO de creación de planta. Validado con class-validator.
 * Compromiso TFG: decoradores de validación en DTO de dominio para simplificar la arquitectura.
 * @module Plants
 * @layer Domain
 */

import {
  IsString, IsNotEmpty, IsOptional, IsInt, IsNumber, Min, Max,
  IsIn, IsBoolean, MaxLength,
} from 'class-validator';
import { Type } from 'class-transformer';

/**
 * DTO de creación de planta recibido del cliente.
 * La foto se gestiona por separado mediante el endpoint POST /upload/image.
 */
export class CreatePlantRequestDTO {
  /** Nombre personalizado de la planta */
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  name!: string;

  /** Id de la especie asociada (obligatorio) */
  @IsString()
  @IsNotEmpty()
  speciesId!: string;

  /** URL de imagen en Cloudinary (obtenida previamente de POST /upload/image) */
  @IsOptional()
  @IsString()
  photo?: string;

  /** Ubicación de la planta */
  @IsIn(['Interior', 'Exterior'])
  location!: 'Interior' | 'Exterior';

  /** Ciudad/municipio donde se encuentra la planta (del catálogo de capitales) */
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  plantLocation!: string;

  /** Latitud geográfica de la ubicación de la planta */
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  plantLocationLat?: number;

  /** Longitud geográfica de la ubicación de la planta */
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  plantLocationLon?: number;

  /** Frecuencia de riego en días */
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(365)
  wateringFrequency!: number;

  /** Necesidad de luz */
  @IsIn(['Low', 'Medium', 'High'])
  lightNeed!: 'Low' | 'Medium' | 'High';

  /** Frecuencia de poda en días (opcional) */
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(365)
  pruningFrequency?: number;

  /** Notas libres */
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;

  /** Si true, el riego considerará datos meteorológicos */
  @IsOptional()
  @IsBoolean()
  considerWeatherForWatering?: boolean;
}
