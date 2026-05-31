/// @file error_handler.dart
/// @description Manejador global de errores para la capa de presentación.
/// Muestra SnackBars informativos con acciones de Reintentar, Usar caché
/// y Reportar según el tipo de error (AppError).
/// @module Core
/// @layer Presentation
library;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../../app.dart' show appProviderGeneration;
import '../../core/config/app_theme.dart';
import '../../core/errors/app_error.dart';
import '../routes/app_router.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ERROR HANDLER
// ═══════════════════════════════════════════════════════════════════════════════

/// Utilidad estática para presentar errores de forma consistente en toda la app.
///
/// Uso típico desde un ViewModel listener:
/// ```dart
/// if (vm.error != null) {
///   ErrorHandler.show(
///     context,
///     vm.error!,
///     onRetry:    () => vm.loadData(),
///     onUseCache: () => vm.loadFromCache(),
///   );
/// }
/// ```
abstract final class ErrorHandler {

  // ─── Método principal ─────────────────────────────────────────────────────

  /// Muestra un [SnackBar] con el mensaje de error y, según el tipo, botones
  /// de acción:
  ///
  /// - **Reintentar** — si [onRetry] != null y el error es [AppError.isRetryable].
  /// - **Usar caché** — si [onUseCache] != null (datos offline disponibles).
  /// - **Reportar**  — siempre disponible cuando no hay otras acciones (logs debug).
  ///
  /// Si el error es [AppError.requiresReauth], redirige al login.
  static void show(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
    VoidCallback? onUseCache,
  }) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    final message = _localizeError(error);

    // Construir lista de acciones disponibles para la fila de botones
    final actions = <_ErrorAction>[
      if (onRetry != null && error.isRetryable)
        _ErrorAction(
          label:    'Reintentar',
          onPressed: () {
            messenger.clearSnackBars();
            onRetry();
          },
        ),
      if (onUseCache != null)
        _ErrorAction(
          label:    'Usar caché',
          onPressed: () {
            messenger.clearSnackBars();
            onUseCache();
          },
        ),
      if (onRetry == null && onUseCache == null)
        _ErrorAction(
          label:    'Reportar',
          onPressed: () {
            messenger.clearSnackBars();
            _report(error);
          },
        ),
    ];

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        behavior:        SnackBarBehavior.floating,
        duration:        const Duration(seconds: 6),
        margin:          const EdgeInsets.all(12),
        shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            // Botones de acción compactos en la misma fila
            ...actions.map(
              (a) => TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding:         const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize:     Size.zero,
                  tapTargetSize:   MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: a.onPressed,
                child: Text(
                  a.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize:   12,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Si el error requiere reautenticación, redirigir al login tras un breve delay.
    // El token JWT ya quedó inválido — incrementamos `appProviderGeneration`
    // para forzar la reconstrucción del árbol Provider y descartar el
    // estado de la sesión expirada.
    if (error.requiresReauth && context.mounted) {
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        if (context.mounted) {
          appProviderGeneration.value++;
          Navigator.of(context, rootNavigator: true)
              .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
        }
      });
    }
  }

  // ─── Error de validación inline ───────────────────────────────────────────

  /// Muestra un SnackBar de aviso para errores de validación de formulario.
  /// Usa color [AppColors.warning] en lugar de error.
  static void showValidation(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.warning,
          behavior:        SnackBarBehavior.floating,
          duration:        const Duration(seconds: 4),
          margin:          const EdgeInsets.all(12),
          shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ─── Patrón: errores transitorios sin AppError ────────────────────────────

  /// Muestra un SnackBar de error simple a partir de un mensaje en español
  /// (sin AppError ni acciones de reintentar). Pensado para errores
  /// transitorios o no críticos disparados desde la UI (no desde la API):
  /// p.ej. un like que falla, una validación local rápida, etc.
  ///
  /// Para errores con [AppError] (incluyen retry/caché), usar [show].
  static void showTransient(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          behavior:        SnackBarBehavior.floating,
          duration:        const Duration(seconds: 4),
          margin:          const EdgeInsets.all(12),
          shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ─── Patrón: banner inline (cuando la pantalla no puede mostrar contenido) ─

  /// Construye un widget banner para insertarlo en el body de una pantalla
  /// cuando el error impide mostrar el contenido principal (ej. GET /plants
  /// falló y la lista está vacía). Incluye un botón "Reintentar" si se
  /// proporciona [onRetry].
  ///
  /// Uso típico:
  /// ```dart
  /// if (vm.error != null) {
  ///   return ErrorHandler.inlineBanner(
  ///     message:  'No se pudieron cargar las plantas.',
  ///     onRetry:  () => vm.loadPlants(),
  ///   );
  /// }
  /// ```
  static Widget inlineBanner({
    required String message,
    VoidCallback?   onRetry,
    IconData        icon = Icons.error_outline,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color:      AppColors.textPrimary,
                fontSize:   14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon:      const Icon(Icons.refresh_rounded, size: 18),
                label:     const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Patrón: errores críticos con confirmación obligatoria ────────────────

  /// Muestra un [AlertDialog] modal para errores críticos que requieren que
  /// el usuario lo lea y confirme (no se cierra solo). Pensado para fallos
  /// que dejan datos en estado dudoso o requieren acción consciente:
  /// p.ej. eliminar cuenta falló por contraseña incorrecta, exportación de
  /// datos falló a mitad de proceso.
  ///
  /// Para errores no críticos, usar [show] o [showTransient].
  ///
  /// [returns] true si el usuario pulsa el botón principal, false si cierra
  ///           el diálogo de cualquier otra forma.
  static Future<bool> showCritical(
    BuildContext context, {
    required String title,
    required String message,
    String          confirmLabel = 'Entendido',
    String?         cancelLabel,
  }) async {
    if (!context.mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_rounded, color: AppColors.error),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          if (cancelLabel != null)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child:     Text(cancelLabel),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child:     Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ─── Éxito ────────────────────────────────────────────────────────────────

  /// Muestra un SnackBar de confirmación de operación correcta.
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          behavior:        SnackBarBehavior.floating,
          duration:        const Duration(seconds: 3),
          margin:          const EdgeInsets.all(12),
          shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ─── Privado ──────────────────────────────────────────────────────────────

  /// Traduce el [AppError] a un mensaje legible en español.
  static String _localizeError(AppError error) {
    // 429 (rate limit) trae el mensaje localizado del backend con el tiempo
    // restante calculado: respetarlo en lugar de mostrar genérico.
    if (error.statusCode == 429) {
      return error.message;
    }
    switch (error.code) {
      case ErrorCode.network:
        return 'Sin conexión. Comprueba tu red.';
      case ErrorCode.unauthorized:
        return 'Sesión expirada. Inicia sesión de nuevo.';
      case ErrorCode.notFound:
        return 'El recurso solicitado no existe.';
      case ErrorCode.validation:
        return error.message; // El mensaje de validación ya viene en español del servidor.
      case ErrorCode.server:
        return 'Error del servidor. Inténtalo más tarde.';
      case ErrorCode.externalService:
        return 'Servicio externo no disponible. Inténtalo más tarde.';
      case ErrorCode.unknown:
        return 'Error inesperado. Inténtalo de nuevo.';
    }
  }

  /// Registra el error en consola (solo en modo debug) y podría enviarlo a un
  /// sistema de telemetría en producción.
  // TFG: en producción sustituir por Firebase Crashlytics o Sentry.
  static void _report(AppError error) {
    if (kDebugMode) {
      debugPrint('[ErrorHandler] Reported: $error');
    }
  }
}

// ─── Modelo auxiliar ──────────────────────────────────────────────────────────

class _ErrorAction {
  const _ErrorAction({required this.label, required this.onPressed});
  final String       label;
  final VoidCallback onPressed;
}
