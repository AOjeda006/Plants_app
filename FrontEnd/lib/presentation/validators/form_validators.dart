/// @file form_validators.dart
/// @description Validadores de formulario centralizados para la capa de presentación.
/// Agrupa las reglas de validación por dominio de formulario (auth, planta, post,
/// perfil) reutilizando el núcleo de [Validators] con mensajes específicos en español.
/// @module Core
/// @layer Presentation
library;

import '../../core/utils/validators.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// FORM VALIDATORS
// ═══════════════════════════════════════════════════════════════════════════════

/// Validadores específicos de formulario para cada pantalla.
///
/// Todos los métodos siguen la firma `String? Function(String? value)`
/// compatible con [TextFormField.validator].
abstract final class FormValidators {

  // ─── Auth ──────────────────────────────────────────────────────────────────

  /// Valida el campo de email en login y registro.
  static String? authEmail(String? value) => Validators.email(value);

  /// Valida la contraseña en registro (mínimo 8 chars, mayús+minús+dígito).
  static String? authPassword(String? value) => Validators.password(value);

  /// Valida la contraseña en login (solo obligatoriedad — la validez la decide el servidor).
  static String? loginPassword(String? value) =>
      Validators.required(value, fieldName: 'contraseña');

  /// Valida que la confirmación de contraseña coincida con [original].
  static String? Function(String?) confirmPassword(String original) =>
      (v) => Validators.confirmPassword(v, original);

  /// Valida el nombre completo en el formulario de registro.
  static String? authName(String? value) => Validators.name(value);

  // ─── Planta ────────────────────────────────────────────────────────────────

  /// Valida el nombre de la planta (obligatorio, máx. 100 caracteres).
  static String? plantName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre de la planta es obligatorio.';
    }
    if (value.trim().length > 100) {
      return 'El nombre no puede superar los 100 caracteres.';
    }
    return null;
  }

  /// Valida las notas de la planta (opcional, máx. 1000 caracteres).
  static String? plantNotes(String? value) {
    if (value != null && value.length > 1000) {
      return 'Las notas no pueden superar los 1000 caracteres.';
    }
    return null;
  }

  // ─── Post / Comunidad ─────────────────────────────────────────────────────

  /// Valida el título de un post (obligatorio, máx. 120 caracteres).
  static String? postTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El título es obligatorio.';
    }
    if (value.trim().length > 120) {
      return 'El título no puede superar los 120 caracteres.';
    }
    return null;
  }

  /// Valida el contenido de un post (obligatorio, mínimo 10 caracteres).
  static String? postContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El contenido es obligatorio.';
    }
    if (value.trim().length < 10) {
      return 'El contenido debe tener al menos 10 caracteres.';
    }
    return null;
  }

  /// Valida el texto de un comentario (obligatorio, mínimo 1 carácter).
  static String? commentText(String? value) =>
      Validators.required(value, fieldName: 'comentario');

  // ─── Perfil ────────────────────────────────────────────────────────────────

  /// Valida el nombre de usuario en la edición de perfil (obligatorio, máx. 50).
  static String? profileName(String? value) => Validators.name(value);

  /// Valida la biografía (opcional, máx. 500 caracteres).
  static String? profileBio(String? value) {
    if (value != null && value.length > 500) {
      return 'La bio no puede superar los 500 caracteres.';
    }
    return null;
  }

  /// Valida la ubicación del perfil (opcional, máx. 100 caracteres).
  static String? profileLocation(String? value) {
    if (value != null && value.length > 100) {
      return 'La ubicación no puede superar los 100 caracteres.';
    }
    return null;
  }

  // ─── Cambio de contraseña ─────────────────────────────────────────────────

  /// Valida la contraseña actual en el formulario de cambio (solo obligatoriedad).
  static String? currentPassword(String? value) =>
      Validators.required(value, fieldName: 'contraseña actual');

  /// Valida la nueva contraseña con todas las reglas de seguridad.
  static String? newPassword(String? value) => Validators.password(value);

  // ─── Utilidad ─────────────────────────────────────────────────────────────

  /// Campo obligatorio genérico. [fieldName] aparece en el mensaje de error.
  static String? required(String? value, {String fieldName = 'campo'}) =>
      Validators.required(value, fieldName: fieldName);
}
