/**
 * @file register-request.dto.ts
 * @description DTO de solicitud de registro de usuario con validaciones class-validator.
 * @module Auth
 * @layer Domain
 */

import { IsEmail, IsString, MinLength, MaxLength } from 'class-validator';

/**
 * DTO de registro. Validado en el controlador antes de llegar al use case.
 *
 * [⚠ TFG]: Los decoradores class-validator en DTOs de dominio son una
 * concesión de pragmatismo: en Clean Architecture pura los DTOs de dominio
 * no deberían depender de un framework de validación, pero se acepta el
 * acoplamiento por simplicidad para el alcance del proyecto.
 */
export class RegisterRequestDTO {
  /** Nombre completo del usuario */
  @IsString()
  @MinLength(2)
  @MaxLength(100)
  name!: string;

  /** Email único del usuario */
  @IsEmail()
  email!: string;

  /** Contraseña en texto plano (se hashea antes de persistir) */
  @IsString()
  @MinLength(8)
  @MaxLength(128)
  password!: string;
}
