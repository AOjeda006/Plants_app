/// @file account_management_page.dart
/// @description Pantalla de gestión de cuenta.
/// Permite cambiar la contraseña, exportar datos personales (RGPD)
/// y eliminar la cuenta con confirmación.
/// @module User
/// @layer Presentation
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app.dart' show appProviderGeneration;
import '../../core/config/app_theme.dart';
import '../../core/di/container.dart';
import '../../core/errors/app_error.dart';
import '../../core/utils/download_helper.dart';
import '../routes/app_router.dart';
import '../viewmodels/profile/account_management_viewmodel.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ACCOUNT MANAGEMENT PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Pantalla de gestión de cuenta. Sin argumentos de ruta.
class AccountManagementPage extends StatelessWidget {
  const AccountManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AccountManagementViewModel>(
      create: (_) => sl<AccountManagementViewModel>(),
      child: const _AccountManagementContent(),
    );
  }
}

// ─── Contenido principal ──────────────────────────────────────────────────────

class _AccountManagementContent extends StatelessWidget {
  const _AccountManagementContent();

  @override
  Widget build(BuildContext context) {
    final error = context.select<AccountManagementViewModel, AppError?>((vm) => vm.error);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Gestión de cuenta')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Error banner
          if (error != null)
            Container(
              margin:  const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border:       Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Text(error.message, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ),

          // ── Cambiar contraseña ────────────────────────────────────────────
          _SectionCard(
            title: 'Cambiar contraseña',
            icon:  Icons.lock_outline_rounded,
            child: _ChangePasswordForm(),
          ),
          const SizedBox(height: 20),

          // ── Exportar datos ────────────────────────────────────────────────
          _SectionCard(
            title: 'Exportar mis datos',
            icon:  Icons.download_outlined,
            child: _ExportDataSection(),
          ),
          const SizedBox(height: 20),

          // ── Eliminar cuenta ───────────────────────────────────────────────
          _SectionCard(
            title:       'Eliminar cuenta',
            icon:        Icons.delete_forever_outlined,
            titleColor:  AppColors.error,
            child:       _DeleteAccountSection(),
          ),
        ],
      ),
    );
  }
}

// ─── Cambiar contraseña ───────────────────────────────────────────────────────

class _ChangePasswordForm extends StatefulWidget {
  @override
  State<_ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<_ChangePasswordForm> {
  final _currentCtrl = TextEditingController();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool  _obscureCurrent = true;
  bool  _obscureNew     = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.select<AccountManagementViewModel, bool>(
      (vm) => vm.isChangingPassword,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller:  _currentCtrl,
          obscureText: _obscureCurrent,
          decoration: InputDecoration(
            labelText: 'Contraseña actual',
            suffixIcon: IconButton(
              tooltip:   _obscureCurrent ? 'Mostrar contraseña' : 'Ocultar contraseña',
              icon:      Icon(_obscureCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller:  _newCtrl,
          obscureText: _obscureNew,
          decoration: InputDecoration(
            labelText: 'Nueva contraseña',
            suffixIcon: IconButton(
              tooltip:   _obscureNew ? 'Mostrar contraseña' : 'Ocultar contraseña',
              icon:      Icon(_obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller:  _confirmCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Confirmar nueva contraseña'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: isSaving ? null : _submit,
          child: isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Cambiar contraseña'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_newCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden.')),
      );
      return;
    }
    final ok = await context.read<AccountManagementViewModel>().changePassword(
      _currentCtrl.text,
      _newCtrl.text,
    );
    if (ok && mounted) {
      _currentCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña cambiada correctamente.')),
      );
    }
  }
}

// ─── Exportar datos ───────────────────────────────────────────────────────────

class _ExportDataSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isExporting  = context.select<AccountManagementViewModel, bool>((vm) => vm.isExporting);
    final exportedData = context.select<AccountManagementViewModel, String?>((vm) => vm.exportedData);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Descarga una copia de todos tus datos personales almacenados '
          'en la app (RGPD).',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: isExporting
              ? null
              : () async {
                  await context.read<AccountManagementViewModel>().exportUserData();
                  if (!context.mounted) return;
                  final data = context.read<AccountManagementViewModel>().exportedData;
                  if (data != null) {
                    final filename =
                        'plantas_export_${DateTime.now().toIso8601String().substring(0, 10)}.json';
                    downloadTextFile(data, filename);
                  }
                },
          icon:  const Icon(Icons.download_rounded),
          label: isExporting
              ? const Text('Exportando...')
              : const Text('Exportar mis datos'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.info),
        ),
        if (exportedData != null) ...[
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 16),
              SizedBox(width: 6),
              Text(
                'Datos exportados correctamente.',
                style: TextStyle(color: AppColors.success, fontSize: 13),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Eliminar cuenta ──────────────────────────────────────────────────────────

class _DeleteAccountSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDeleting      = context.select<AccountManagementViewModel, bool>((vm) => vm.isDeleting);
    final preserveContent = context.select<AccountManagementViewModel, bool>((vm) => vm.preserveContent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Esta acción es irreversible. Tu cuenta y todos tus datos '
          'serán eliminados permanentemente.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 8),
        // Toggle: mantener publicaciones de forma anónima.
        SwitchListTile(
          value:         preserveContent,
          onChanged:     isDeleting
              ? null
              : (v) => context.read<AccountManagementViewModel>()
                    .setPreserveContent(value: v),
          activeThumbColor:  AppColors.primary,
          activeTrackColor:  AppColors.primary.withValues(alpha: 0.5),
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Mantener mis publicaciones de forma anónima',
            style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
          subtitle: const Text(
            'Tus posts y comentarios permanecerán visibles sin nombre de autor.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 4),
        ElevatedButton.icon(
          onPressed: isDeleting ? null : () => _confirmDelete(context),
          icon:  const Icon(Icons.delete_forever_rounded),
          label: isDeleting
              ? const Text('Eliminando...')
              : const Text('Eliminar cuenta'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ctrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text('Eliminar cuenta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Introduce tu contraseña para confirmar la eliminación.'),
            const SizedBox(height: 12),
            TextField(
              controller:  ctrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child:     const Text('Cancelar'),
          ),
          TextButton(
            style:     TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child:     const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final ok = await context.read<AccountManagementViewModel>().deleteAccount(ctrl.text);
    if (ok && context.mounted) {
      // Tras eliminar la cuenta, el árbol Provider también debe
      // reconstruirse para limpiar el estado heredado.
      appProviderGeneration.value++;
      Navigator.of(context, rootNavigator: true)
          .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    }
  }
}

// ─── Card de sección ──────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.titleColor,
  });

  final String    title;
  final IconData  icon;
  final Widget    child;
  final Color?    titleColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color:     AppColors.surface,
      shape:     RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: titleColor ?? AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color:      titleColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize:   15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
