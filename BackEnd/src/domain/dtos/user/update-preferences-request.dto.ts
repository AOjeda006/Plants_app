/**
 * @file update-preferences-request.dto.ts
 * @description DTO para actualizar las preferencias de notificación y comportamiento del usuario.
 * Todos los campos son opcionales: solo se actualizan los que se envían.
 * @module User
 * @layer Domain
 */

import { IsBoolean, IsOptional } from 'class-validator';

/**
 * Campos de preferencias actualizables.
 * Coincide con la interfaz UserPreferences de la entidad User.
 */
export class UpdatePreferencesRequestDto {
  /** Aparecer en búsquedas de chat de otros usuarios */
  @IsOptional() @IsBoolean() appearInChatSearch?: boolean;

  /** Considerar el clima al calcular recordatorios de riego por defecto */
  @IsOptional() @IsBoolean() considerWeatherByDefault?: boolean;

  /** Si true, el perfil no aparece en el feed público ni acepta nuevas conversaciones */
  @IsOptional() @IsBoolean() isPrivate?: boolean;

  /**
   * Si false, el backend no envía push FCM aunque el usuario tenga
   * fcmToken registrado. Las capas in-app y socket no se ven afectadas.
   */
  @IsOptional() @IsBoolean() pushNotifications?: boolean;
}
