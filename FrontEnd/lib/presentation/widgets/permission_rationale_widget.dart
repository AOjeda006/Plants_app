/// @file permission_rationale_widget.dart
/// @description Widget que explica por qué se necesita un permiso antes de solicitarlo.
/// Debe mostrarse como bottom sheet o diálogo antes de invocar permission_handler.
/// @module Core
/// @layer Presentation
library;

import 'package:flutter/material.dart';

import '../../core/config/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PERMISSION RATIONALE WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

/// Widget informativo que explica el uso de un permiso al usuario
/// antes de que el sistema operativo muestre el diálogo nativo.
///
/// Usar como contenido de [showModalBottomSheet] o [showDialog].
/// Siempre mostrar este widget primero para mejorar la tasa de aceptación.
class PermissionRationaleWidget extends StatelessWidget {
  const PermissionRationaleWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onAllow,
    this.onDeny,
    this.allowLabel = 'Permitir',
    this.denyLabel  = 'Ahora no',
  });

  /// Icono representativo del permiso (cámara, ubicación, notificaciones…).
  final IconData icon;

  /// Título corto que describe el permiso solicitado.
  final String title;

  /// Descripción detallada de por qué la app necesita este permiso.
  final String description;

  /// Callback invocado cuando el usuario acepta conceder el permiso.
  final VoidCallback onAllow;

  /// Callback invocado cuando el usuario rechaza. null desactiva el botón de rechazo.
  final VoidCallback? onDeny;

  /// Texto del botón de aceptación.
  final String allowLabel;

  /// Texto del botón de rechazo.
  final String denyLabel;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Indicador de arrastre del bottom sheet ────────────────────
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color:        AppColors.surface,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // ── Icono del permiso ─────────────────────────────────────────
            Container(
              width:      72,
              height:     72,
              decoration: const BoxDecoration(
                color: Color(0x1A2E8B57), // primary con 10% opacidad
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),

            // ── Título ────────────────────────────────────────────────────
            Text(
              title,
              style:     tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color:      AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // ── Descripción ───────────────────────────────────────────────
            Text(
              description,
              style:     tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // ── Botón principal (Permitir) ─────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAllow,
                child:     Text(allowLabel),
              ),
            ),

            // ── Botón secundario (Ahora no) ────────────────────────────────
            if (onDeny != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onDeny,
                  child:     Text(
                    denyLabel,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
