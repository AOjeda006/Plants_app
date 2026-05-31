/// @file admin_dashboard_page.dart
/// @description Panel de administración principal.
/// Muestra estado del socket, cola offline, diagnósticos del servidor
/// y accesos rápidos a las secciones de administración.
/// @module Admin
/// @layer Presentation
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_theme.dart';
import '../../../core/di/container.dart';
import '../../../core/errors/app_error.dart';
import '../../routes/app_router.dart';
import '../../viewmodels/admin/admin_viewmodel.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ADMIN DASHBOARD PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Panel de administración. Solo accesible para usuarios con rol 'admin'.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminViewModel>(
      create: (_) => sl<AdminViewModel>()..loadDashboard(),
      child: const _AdminDashboardContent(),
    );
  }
}

// ─── Contenido ────────────────────────────────────────────────────────────────

class _AdminDashboardContent extends StatelessWidget {
  const _AdminDashboardContent();

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AdminViewModel, bool>((vm) => vm.isLoading);
    final error     = context.select<AdminViewModel, AppError?>((vm) => vm.error);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Panel de administración'),
        actions: [
          IconButton(
            icon:      const Icon(Icons.refresh_rounded),
            tooltip:   'Actualizar',
            onPressed: () => context.read<AdminViewModel>().loadDashboard(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => context.read<AdminViewModel>().loadDashboard(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Error banner
                  if (error != null)
                    _ErrorBanner(error: error),

                  // ── Accesos rápidos ────────────────────────────────────
                  _SectionHeader(title: 'Gestión'),
                  const SizedBox(height: 8),
                  _AdminNavTileWithBadge(
                    icon:    Icons.flag_outlined,
                    label:   'Reportes de incidencias',
                    badgeCount: context.select<AdminViewModel, int>(
                      (vm) => vm.pendingReportsCount,
                    ),
                    onTap:   () => Navigator.of(context).pushNamed(AppRoutes.adminReports),
                  ),
                  _AdminNavTile(
                    icon:    Icons.restore_from_trash_outlined,
                    label:   'Elementos eliminados',
                    onTap:   () => Navigator.of(context).pushNamed(AppRoutes.adminDeleted),
                  ),

                  const SizedBox(height: 24),

                  // ── Acciones ──────────────────────────────────────────
                  _SectionHeader(title: 'Acciones'),
                  const SizedBox(height: 8),
                  const _RunCronButton(),
                  const SizedBox(height: 8),
                  const _SimulateRainButton(),
                  const SizedBox(height: 8),
                  const _SimulateStormButton(),
                ],
              ),
            ),
    );
  }
}

// ─── Tile de navegación admin ─────────────────────────────────────────────────

class _AdminNavTile extends StatelessWidget {
  const _AdminNavTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData     icon;
  final String       label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color:     AppColors.surface,
      shape:     RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading:  Icon(icon, color: AppColors.primary),
        // b) Color explícito para evitar texto blanco en temas oscuros o cards de color.
        title:    Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        onTap:    onTap,
      ),
    );
  }
}

/// Tile de navegación con badge numérico para indicar elementos pendientes.
class _AdminNavTileWithBadge extends StatelessWidget {
  const _AdminNavTileWithBadge({
    required this.icon,
    required this.label,
    required this.badgeCount,
    required this.onTap,
  });

  final IconData     icon;
  final String       label;
  final int          badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color:     AppColors.surface,
      shape:     RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading:  Icon(icon, color: AppColors.primary),
        title:    Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeCount > 0)
              Container(
                padding:    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin:     const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color:        AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

// ─── Botón Run Cron ──────────────────────────────────────────────────────────

/// Botón de acción directa para ejecutar el procesamiento de recordatorios.
/// Muestra diálogo de confirmación, indicador de progreso y resultado.
class _RunCronButton extends StatelessWidget {
  const _RunCronButton();

  Future<void> _handleRunCron(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ejecutar procesamiento'),
        content: const Text(
          '¿Ejecutar el procesamiento de recordatorios para todos los usuarios?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ejecutar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final vm      = context.read<AdminViewModel>();
    final success  = await vm.runCron();

    if (!context.mounted) return;

    if (success && vm.cronResult != null) {
      final result   = vm.cronResult!;
      final duration = result['durationMs'] ?? '—';
      final message  = result['message'] ?? 'Completado';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$message (${duration}ms)')),
      );
    } else if (vm.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:         Text(vm.error!.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = context.select<AdminViewModel, bool>(
      (vm) => vm.isRunningCron,
    );

    return Card(
      elevation: 0,
      color:     AppColors.surface,
      shape:     RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: isRunning
            ? const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_circle_outline_rounded, color: AppColors.primary),
        title: Text(
          isRunning ? 'Procesando recordatorios…' : 'Ejecutar cron de recordatorios',
          style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        ),
        subtitle: const Text(
          'Procesa riego, poda, cosecha y clima',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: isRunning
            ? null
            : const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        onTap: isRunning ? null : () => _handleRunCron(context),
      ),
    );
  }
}

// ─── Botón Simular Lluvia ────────────────────────────────────────────────────

/// Botón para generar notificaciones de lluvia simulada para todas las plantas.
class _SimulateRainButton extends StatelessWidget {
  const _SimulateRainButton();

  Future<void> _handle(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:   const Text('Simular lluvia'),
        content: const Text(
          '¿Generar notificaciones de lluvia (80%) para todas las plantas activas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Simular'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final vm      = context.read<AdminViewModel>();
    final success = await vm.simulateRain();

    if (!context.mounted) return;

    if (success && vm.simulateResult != null) {
      final count   = vm.simulateResult!['count'] ?? 0;
      final message = vm.simulateResult!['message'] ?? 'Completado';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$message ($count notificaciones)')),
      );
    } else if (vm.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:         Text(vm.error!.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = context.select<AdminViewModel, bool>(
      (vm) => vm.isSimulatingRain,
    );

    return Card(
      elevation: 0,
      color:     AppColors.surface,
      shape:     RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: isRunning
            ? const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.water_drop_outlined, color: AppColors.primary),
        title: Text(
          isRunning ? 'Generando alertas de lluvia…' : 'Simular lluvia',
          style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        ),
        subtitle: const Text(
          'Genera notificaciones de lluvia (80%) para todas las plantas',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: isRunning
            ? null
            : const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        onTap: isRunning ? null : () => _handle(context),
      ),
    );
  }
}

// ─── Botón Simular Tormenta ──────────────────────────────────────────────────

/// Botón para generar notificaciones de tormenta simulada para todas las plantas.
class _SimulateStormButton extends StatelessWidget {
  const _SimulateStormButton();

  Future<void> _handle(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:   const Text('Simular tormenta'),
        content: const Text(
          '¿Generar alertas de tormenta para todas las plantas activas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Simular'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final vm      = context.read<AdminViewModel>();
    final success = await vm.simulateStorm();

    if (!context.mounted) return;

    if (success && vm.simulateResult != null) {
      final count   = vm.simulateResult!['count'] ?? 0;
      final message = vm.simulateResult!['message'] ?? 'Completado';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$message ($count notificaciones)')),
      );
    } else if (vm.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:         Text(vm.error!.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = context.select<AdminViewModel, bool>(
      (vm) => vm.isSimulatingStorm,
    );

    return Card(
      elevation: 0,
      color:     AppColors.surface,
      shape:     RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: isRunning
            ? const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.thunderstorm_outlined, color: AppColors.warning),
        title: Text(
          isRunning ? 'Generando alertas de tormenta…' : 'Simular tormenta',
          style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        ),
        subtitle: const Text(
          'Genera alertas de protección por tormenta para todas las plantas',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: isRunning
            ? null
            : const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        onTap: isRunning ? null : () => _handle(context),
      ),
    );
  }
}

// ─── Auxiliares ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color:         AppColors.primary,
        fontSize:      11,
        fontWeight:    FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error});
  final AppError error;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(error.message, style: const TextStyle(color: AppColors.error, fontSize: 13))),
          TextButton(
            style:     TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: AppColors.error),
            onPressed: () => context.read<AdminViewModel>().clearError(),
            child:     const Text('×'),
          ),
        ],
      ),
    );
  }
}
