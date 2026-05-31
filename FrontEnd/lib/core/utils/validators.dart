/// @file validators.dart
/// @description Validadores reutilizables para formularios de la app.
/// Devuelven String? (null = válido, String = mensaje de error) para ser
/// usados directamente como validator en TextFormField.
/// También exponen métodos booleanos para validación programática.
/// @module Core
/// @layer Core
library;

// ═══════════════════════════════════════════════════════════════════════════════
// CONSTANTES
// ═══════════════════════════════════════════════════════════════════════════════

/// Longitud mínima de contraseña aceptada.
const int _kMinPasswordLength = 8;

/// Longitud máxima de contraseña aceptada.
const int _kMaxPasswordLength = 128;

/// Longitud máxima de nombre de usuario.
const int _kMaxNameLength = 50;

/// Patrón de email según RFC 5322 simplificado (cubre el 99.9% de emails reales).
final RegExp _emailRegex = RegExp(
  r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
);

/// Una mayúscula, una minúscula y un dígito (fuerza mínima de contraseña).
final RegExp _passwordStrengthRegex = RegExp(
  r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$',
);

// ═══════════════════════════════════════════════════════════════════════════════
// VALIDATORS
// ═══════════════════════════════════════════════════════════════════════════════

/// Colección de validadores estáticos para formularios Flutter.
abstract final class Validators {

  // ─── Email ───────────────────────────────────────────────────────────────────

  /// Valida formato de email. Devuelve null si es válido.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es obligatorio.';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Introduce un email válido.';
    }
    return null;
  }

  /// Versión booleana para validación programática.
  static bool isValidEmail(String value) => _emailRegex.hasMatch(value.trim());

  // ─── Contraseña ───────────────────────────────────────────────────────────────

  /// Valida fuerza y longitud de contraseña. Devuelve null si es válida.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria.';
    }
    if (value.length < _kMinPasswordLength) {
      return 'La contraseña debe tener al menos $_kMinPasswordLength caracteres.';
    }
    if (value.length > _kMaxPasswordLength) {
      return 'La contraseña no puede superar $_kMaxPasswordLength caracteres.';
    }
    if (!_passwordStrengthRegex.hasMatch(value)) {
      return 'La contraseña debe contener al menos una mayúscula, una minúscula y un número.';
    }
    return null;
  }

  /// true si la contraseña cumple todos los requisitos.
  static bool isStrongPassword(String value) =>
      value.length >= _kMinPasswordLength &&
      value.length <= _kMaxPasswordLength &&
      _passwordStrengthRegex.hasMatch(value);

  // ─── Confirmación de contraseña ───────────────────────────────────────────────

  /// Valida que [confirmation] coincida con [original].
  static String? confirmPassword(String? confirmation, String original) {
    if (confirmation == null || confirmation.isEmpty) {
      return 'Confirma tu contraseña.';
    }
    if (confirmation != original) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }

  // ─── Nombre ───────────────────────────────────────────────────────────────────

  /// Valida nombre de usuario (no vacío, longitud razonable).
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio.';
    }
    if (value.trim().length > _kMaxNameLength) {
      return 'El nombre no puede superar $_kMaxNameLength caracteres.';
    }
    return null;
  }

  // ─── Campo requerido genérico ─────────────────────────────────────────────────

  /// Valida que el campo no esté vacío. [fieldName] se incluye en el mensaje.
  static String? required(String? value, {String fieldName = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio.';
    }
    return null;
  }

  // ─── Rangos numéricos ─────────────────────────────────────────────────────────

  /// Valida que [value] sea un entero dentro del rango [[min], [max]].
  static String? intInRange(
    String? value, {
    required int min,
    required int max,
    String fieldName = 'El valor',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio.';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return '$fieldName debe ser un número entero.';
    }
    if (parsed < min || parsed > max) {
      return '$fieldName debe estar entre $min y $max.';
    }
    return null;
  }

  /// Valida que [value] sea un decimal dentro del rango [[min], [max]].
  static String? doubleInRange(
    String? value, {
    required double min,
    required double max,
    String fieldName = 'El valor',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio.';
    }
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null) {
      return '$fieldName debe ser un número.';
    }
    if (parsed < min || parsed > max) {
      return '$fieldName debe estar entre $min y $max.';
    }
    return null;
  }
}
