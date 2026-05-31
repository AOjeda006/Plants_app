/// @file deleted_items_page.dart
/// @description Panel de elementos eliminados (soft-delete).
/// Permite al administrador ver y restaurar usuarios, plantas y posts eliminados.
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
// DELETED ITEMS PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Pantalla de elementos eliminados. Sin argumentos de ruta.
class DeletedItemsPage extends StatelessWidget {
  const DeletedItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminViewModel>(
      create: (_) => sl<AdminViewModel>()..loadDeletedItems(),
      child: const _DeletedItemsContent(),
    );
  }
}

// ─── Contenido ────────────────────────────────────────────────────────────────

class _DeletedItemsContent extends StatelessWidget {
  const _DeletedItemsContent();

  @override
  Widget build(BuildContext context) {
    final isLoading   = context.select<AdminViewModel, bool>((vm) => vm.isLoading);
    final isRestoring = context.select<AdminViewModel, bool>((vm) => vm.isRestoring);
    final error       = context.select<AdminViewModel, AppError?>((vm) => vm.error);
    final deleted     = context.select<AdminViewModel, Map<String, dynamic>?>((vm) => vm.deletedItems);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Elementos eliminados'),
        actions: [
          if (isRestoring)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            ),
          IconButton(
            icon:      const Icon(Icons.refresh_rounded),
            tooltip:   'Actualizar',
            onPressed: () => context.read<AdminViewModel>().loadDeletedItems(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => context.read<AdminViewModel>().loadDeletedItems(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (error != null)
                    _ErrorBanner(error: error),
                  ..._buildContent(context, deleted),
                ],
              ),
            ),
    );
  }

  String _sectionLabel(String key) => switch (key.toLowerCase()) {
    'users'    => 'Usuarios',
    'plants'   => 'Plantas',
    'posts'    => 'Posts',
    'comments' => 'Comentarios',
    _          => key,
  };

  List<Widget> _buildContent(BuildContext context, Map<String, dynamic>? deleted) {
    if (deleted == null) return [const _EmptyState()];

    final sections = <Widget>[];
    for (final entry in deleted.entries) {
      if (entry.value is! List) continue;
      final list = (entry.value as List)
          .whereType<Map<String, dynamic>>()
          .toList();
      if (list.isEmpty) continue;

      sections.add(_SectionHeader(title: _sectionLabel(entry.key)));
      sections.add(const SizedBox(height: 8));
      for (final item in list) {
        sections.add(_DeletedItemTile(type: entry.key, item: item));
      }
      sections.add(const SizedBox(height: 16));
    }

    if (sections.isEmpty) return [const _EmptyState()];
    return sections;
  }
}

// ─── Header de sección ────────────────────────────────────────────────────────

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

// ─── Tile de elemento eliminado ───────────────────────────────────────────────

class _DeletedItemTile extends StatelessWidget {
  const _DeletedItemTile({required this.type, required this.item});

  final String               type;
  final Map<String, dynamic> item;

  String get _id =>
      item['_id'] as String? ?? item['id'] as String? ?? '';

  /// Etiqueta descriptiva del tipo de elemento.
  String get _typeLabel {
    final lower = type.toLowerCase();
    if (lower.contains('comment')) return 'Comentario';
    if (lower.contains('user'))    return 'Usuario';
    if (lower.contains('plant'))   return 'Planta';
    if (lower.contains('post'))    return 'Publicación';
    return type;
  }

  /// Vista previa del contenido: texto truncado o descripción según el tipo.
  String get _preview {
    final lower = type.toLowerCase();

    // Usuarios: nombre + email.
    if (lower.contains('user')) {
      final name  = item['name']  as String? ?? '';
      final email = item['email'] as String? ?? '';
      if (name.isNotEmpty && email.isNotEmpty) return '$name ($email)';
      if (name.isNotEmpty)  return name;
      if (email.isNotEmpty) return email;
      return _id;
    }

    // Plantas: nombre de la planta.
    if (lower.contains('plant')) {
      final name = item['name'] as String? ?? item['nickname'] as String? ?? '';
      return name.isNotEmpty ? name : _id;
    }

    // Posts: contenido truncado o indicador de foto.
    if (lower.contains('post')) {
      final content  = item['content'] as String? ?? '';
      final imageUrl = item['imageUrl'] as String? ?? item['image'] as String? ?? '';
      if (content.isNotEmpty) {
        final truncated = content.length > 80 ? '${content.substring(0, 80)}…' : content;
        return imageUrl.isNotEmpty ? '$truncated  📷' : truncated;
      }
      return imageUrl.isNotEmpty ? 'Publicación con foto' : _id;
    }

    // Comentarios: contenido truncado.
    if (lower.contains('comment')) {
      final content = item['content'] as String? ?? '';
      if (content.isNotEmpty) {
        return content.length > 80 ? '${content.substring(0, 80)}…' : content;
      }
      return _id;
    }

    return _id;
  }

  String get _deletedAt {
    final raw = item['deletedAt'] as String?;
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  /// Para comentarios, devuelve el postId padre si existe.
  String? get _parentPostId => item['postId'] as String?;

  @override
  Widget build(BuildContext context) {
    final isComment    = type.toLowerCase().contains('comment');
    final hasParentPost = isComment && _parentPostId != null && _parentPostId!.isNotEmpty;

    return Card(
      elevation: 0,
      color:     AppColors.surface,
      margin:    const EdgeInsets.only(bottom: 8),
      shape:     RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila superior: icono + badge de tipo + fecha.
            Row(
              children: [
                Icon(_iconFor(type), color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:        AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _typeLabel,
                    style: const TextStyle(
                      fontSize:   10,
                      fontWeight: FontWeight.w700,
                      color:      AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                if (_deletedAt.isNotEmpty)
                  Text(
                    _deletedAt,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Vista previa del contenido.
            Text(
              _preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize:   14,
                fontWeight: FontWeight.w500,
                color:      AppColors.textPrimary,
              ),
            ),
            // Enlace al post padre (solo para comentarios).
            if (hasParentPost) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.postDetail,
                  arguments: _parentPostId,
                ),
                child: const Text(
                  'Ver publicación original',
                  style: TextStyle(
                    fontSize: 12,
                    color:    AppColors.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            // Botón de restaurar alineado a la derecha.
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style:     TextButton.styleFrom(foregroundColor: AppColors.success),
                onPressed: () => _confirmRestore(context),
                icon:      const Icon(Icons.restore_rounded, size: 16),
                label:     const Text('Restaurar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRestore(BuildContext context) async {
    final typeKey = _normalizeType(type);
    if (typeKey.isEmpty || _id.isEmpty) return;

    final ok = await context.read<AdminViewModel>().restoreItem(typeKey, _id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:         Text(ok ? 'Elemento restaurado correctamente.' : 'Error al restaurar.'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  // Devuelve el tipo en plural que espera POST /admin/restore/:type/:id.
  String _normalizeType(String t) {
    final lower = t.toLowerCase();
    if (lower.contains('comment')) return 'comments';
    if (lower.contains('user'))    return 'users';
    if (lower.contains('plant'))   return 'plants';
    if (lower.contains('post'))    return 'posts';
    return '';
  }

  IconData _iconFor(String t) {
    final lower = t.toLowerCase();
    if (lower.contains('comment')) return Icons.comment_outlined;
    if (lower.contains('user'))    return Icons.person_outline;
    if (lower.contains('plant'))   return Icons.eco_outlined;
    if (lower.contains('post'))    return Icons.article_outlined;
    return Icons.delete_outline;
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.delete_sweep_outlined, size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              'Sin elementos eliminados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            SizedBox(height: 8),
            Text(
              'Los elementos eliminados aparecerán aquí y podrán ser restaurados.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error banner ─────────────────────────────────────────────────────────────

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
          Expanded(
            child: Text(error.message, style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ),
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
