/// @file settings_page.dart
/// @description Pantalla de ajustes del usuario.
/// Toggles de notificaciones, unidades, privacidad. Link a gestión de cuenta.
/// @module Settings
/// @layer Presentation
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_theme.dart';
import '../../core/di/container.dart';
import '../../core/errors/app_error.dart';
import '../routes/app_router.dart';
import '../viewmodels/auth/auth_viewmodel.dart';
import '../viewmodels/profile/settings_viewmodel.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// HELPERS DE PLATAFORMA
// ═══════════════════════════════════════════════════════════════════════════════

/// True solo en Android/iOS — únicas plataformas donde FCM está activo
/// y el toggle de notificaciones push tiene efecto observable.
///
/// Override `debugMobilePushPlatformOverride` para tests: permite
/// simular plataforma móvil/desktop sin recurrir a mocks de Platform.
@visibleForTesting
bool? debugMobilePushPlatformOverride;

@visibleForTesting
bool isMobilePushPlatform() {
  final override = debugMobilePushPlatformOverride;
  if (override != null) return override;
  if (kIsWeb) return false;
  try {
    return Platform.isAndroid || Platform.isIOS;
  } catch (_) {
    // Plataforma desconocida (Linux/macOS/Windows desktop o ambiente
    // de test) — no mostrar el toggle: no hay FCM real detrás.
    return false;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SETTINGS PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Pantalla de ajustes. Sin argumentos de ruta.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SettingsViewModel>(
      create: (_) => sl<SettingsViewModel>()..loadPreferences(),
      child: const _SettingsContent(),
    );
  }
}

// ─── Contenido principal ──────────────────────────────────────────────────────

class _SettingsContent extends StatelessWidget {
  const _SettingsContent();

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<SettingsViewModel, bool>((vm) => vm.isLoading);
    final isSaving  = context.select<SettingsViewModel, bool>((vm) => vm.isSaving);
    final error     = context.select<SettingsViewModel, AppError?>((vm) => vm.error);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        actions: [
          if (isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child:   Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Error banner
                if (error != null)
                  _ErrorBanner(error: error),

                // ── Notificaciones (solo en plataformas con FCM activo) ──────
                // El toggle solo se renderiza en Android/iOS. En
                // web/desktop no hay FCM, así que la fila se omite por
                // completo (no se muestra deshabilitada). Si la sección
                // queda vacía, también se oculta el header.
                if (isMobilePushPlatform()) ...[
                  _SectionHeader(title: 'Notificaciones'),
                  _ToggleTile(
                    icon:     Icons.phone_android_outlined,
                    label:    'Notificaciones push',
                    subtitle: 'Recibe avisos en la barra del sistema cuando la app está cerrada',
                    value:    context.select<SettingsViewModel, bool>((vm) => vm.pushNotifications),
                    onChanged: (v) {
                      context.read<SettingsViewModel>().setPushNotifications(v);
                      _save(context);
                    },
                  ),
                ],

                // ── Privacidad ───────────────────────────────────────────────
                _SectionHeader(title: 'Privacidad'),

                _ToggleTile(
                  icon:    Icons.public_outlined,
                  label:   'Perfil público',
                  subtitle: 'Visible para otros usuarios en la comunidad',
                  value:   context.select<SettingsViewModel, bool>((vm) => vm.profilePublic),
                  onChanged: (v) {
                    context.read<SettingsViewModel>().setProfilePublic(v);
                    _save(context);
                  },
                ),

                // ── Cuenta ───────────────────────────────────────────────────
                _SectionHeader(title: 'Cuenta'),

                ListTile(
                  leading:  const Icon(Icons.manage_accounts_outlined, color: AppColors.primary),
                  title:    const Text('Gestión de cuenta'),
                  subtitle: const Text('Contraseña, exportar datos, eliminar cuenta'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap:    () => Navigator.of(context).pushNamed(AppRoutes.settingsAccount),
                ),

                // ── Soporte ──────────────────────────────────────────────────
                _SectionHeader(title: 'Soporte'),

                ListTile(
                  leading:  const Icon(Icons.flag_outlined, color: AppColors.primary),
                  title:    const Text('Reportar incidencia'),
                  subtitle: const Text('Notifica un problema al equipo de administración'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap:    () => Navigator.of(context).pushNamed(AppRoutes.reportIncident),
                ),

                // ── Administración (solo admin) ───────────────────────────────
                if (context.watch<AuthViewModel>().currentUser?.isAdmin == true) ...[
                  _SectionHeader(title: 'Administración'),
                  ListTile(
                    leading:  const Icon(Icons.admin_panel_settings_outlined, color: AppColors.primary),
                    title:    const Text('Panel de administración'),
                    subtitle: const Text('Usuarios, estadísticas, elementos eliminados'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap:    () => Navigator.of(context).pushNamed(AppRoutes.admin),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final updated = await context.read<SettingsViewModel>().savePreferences();
    // Propagar el User actualizado al AuthViewModel global para que
    // cualquier consumidor de `currentUser.preferences` vea el cambio
    // (toggle push, isPrivate, idioma, etc.) sin lag.
    if (updated != null && context.mounted) {
      context.read<AuthViewModel>().updateCurrentUser(updated);
    }
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color:         AppColors.primary,
          fontSize:      11,
          fontWeight:    FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData     icon;
  final String       label;
  final String?      subtitle;
  final bool         value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary:    Icon(icon, color: AppColors.primary),
      title:        Text(label),
      subtitle:     subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12)) : null,
      value:        value,
      onChanged:    onChanged,
      activeThumbColor:  AppColors.primary,
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error});
  final AppError error;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Text(
        error.message,
        style: const TextStyle(color: AppColors.error, fontSize: 13),
      ),
    );
  }
}
