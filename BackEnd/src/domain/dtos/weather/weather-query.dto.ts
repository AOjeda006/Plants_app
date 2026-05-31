/**
 * @file weather-query.dto.ts
 * @description DTO de consulta de clima. Se completará en Fase 2.
 * @module Weather
 * @layer Domain
 */
import { IsString, IsOptional, IsInt, Min, Max } from 'class-validator';

export class WeatherQueryDto {
  @IsString() location!: string;
  @IsOptional() @IsInt() @Min(1) @Max(14) days?: number;
}
