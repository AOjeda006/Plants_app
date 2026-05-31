/// @file notifications_page.dart
/// @description Pantalla de notificaciones in-app generadas por el cron de recordatorios.
/// Lista las notificaciones del usuario con icono por tipo, punto de no leída,
/// selección múltiple con checkboxes y AppBar contextual con acciones sobre la selección.
/// @module Reminders
/// @layer Presentation
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_theme.dart';
import '../../core/di/container.dart';
import '../../domain/entities/notification.dart';
import '../viewmodels/reminders/notifications_viewmodel.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// NOTIFICATIONS PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Pantalla de notificaciones in-app del usuario.
///
/// Usa el singleton [NotificationsViewModel] registrado en el DI para que el
/// badge del BottomNav permanezca sincronizado.
///
/// Se convierte en [StatefulWidget] para mover la llamada a [load()] fuera
/// de [build()]: llamar load() en build() causa "setState during build" porque
/// [NotificationsViewModel.load] llama notifyListeners() sincrónicamente antes
/// del primer await, disparando _onNotificationsChanged → setState en MainTabsPage
/// mientras el árbol aún se está construyendo.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    // Diferir load() al post-frame para no disparar notifyListeners()
    // durante el build activo del árbol padre (MainTabsPage).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) sl<NotificationsViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: sl<NotificationsViewModel>(),
      child: const _NotificationsView(),
    );
  }
}

// ─── Vista principal con selección múltiple ───────────────────────────────────

/// Vista stateful que gestiona la selección múltiple de notificaciones.
/// El estado de selección es puramente local (UI); las operaciones de datos
/// se delegan al [NotificationsViewModel].
class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  /// IDs de las notificaciones actualmente seleccionadas.
  final Set<String> _selected = {};

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selected.clear());
  }

  @override
  Widget build(BuildContext context) {
    final vm           = context.watch<NotificationsViewModel>();
    final hasSelection = _selected.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(context, vm, hasSelection),
      body:   _buildBody(context, vm),
    );
  }

  // ── AppBar: modo normal vs modo selección ───────────────────────────────────

  AppBar _buildAppBar(
    BuildContext context,
    NotificationsViewModel vm,
    bool hasSelection,
  ) {
    if (hasSelection) {
      return AppBar(
        // Botón X para salir del modo selección.
        leading: IconButton(
          icon:     const Icon(Icons.close_rounded),
          tooltip:  'Cancelar selección',
          onPressed: _clearSelection,
        ),
        title: Text('${_selected.length} seleccionada${_selected.length == 1 ? '' : 's'}'),
        actions: [
          // Marcar seleccionadas como leídas.
          IconButton(
            icon:     const Icon(Icons.check_circle_outline_rounded),
            tooltip:  'Marcar como leídas',
            onPressed: () {
              vm.markSelectedAsRead(Set.from(_selected));
              _clearSelection();
            },
          ),
          // Eliminar seleccionadas.
          IconButton(
            icon:     const Icon(Icons.delete_outline_rounded),
            tooltip:  'Eliminar seleccionadas',
            onPressed: () {
              vm.deleteSelected(Set.from(_selected));
              _clearSelection();
            },
          ),
        ],
      );
    }

    // AppBar normal con acciones globales.
    return AppBar(
      title: const Text('Notificaciones'),
      actions: [
        IconButton(
          icon:     const Icon(Icons.check_circle_outline_rounded),
          tooltip:  'Marcar todo como leído',
          onPressed: vm.unreadCount > 0 && !vm.isProcessing
              ? () => vm.markAllAsRead()
              : null,
        ),
        IconButton(
          icon:     const Icon(Icons.delete_outline_rounded),
          tooltip:  'Eliminar todo',
          onPressed: vm.notifications.isNotEmpty && !vm.isProcessing
              ? () {
                  _clearSelection();
                  vm.deleteAll();
                }
              : null,
        ),
      ],
    );
  }

  // ── Cuerpo ─────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, NotificationsViewModel vm) {
    if (vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (vm.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              vm.error!.message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () { vm.clearError(); vm.load(); },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (vm.notifications.isEmpty) {
      return const _EmptyState();
    }

    return RefreshIndicator(
      color:     AppColors.primary,
      onRefresh: () async {
        _clearSelection();
        await vm.load();
      },
      child: ListView.builder(
        padding:     const EdgeInsets.symmetric(vertical: 8),
        itemCount:   vm.notifications.length,
        itemBuilder: (ctx, i) {
          final notif = vm.notifications[i];
          return _NotificationTile(
            notification: notif,
            isSelected:   _selected.contains(notif.id),
            onToggle:     () => _toggle(notif.id),
          );
        },
      ),
    );
  }
}

// ─── Tile de notificación ─────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.isSelected,
    required this.onToggle,
  });

  final AppNotification notification;
  final bool            isSelected;
  final VoidCallback    onToggle;

  @override
  Widget build(BuildContext context) {
    final tt      = Theme.of(context).textTheme;
    final isUnread = !notification.isRead;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.08)
            : isUnread
                ? AppColors.secondary.withValues(alpha: 0.08)
                : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
            : null,
      ),
      // InkWell sobre el tile completo para seleccionar con un tap.
      child: InkWell(
        onTap:        onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono según tipo de notificación.
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  _iconForType(notification.type),
                  color: _colorForType(notification.type),
                  size:  22,
                ),
              ),
              const SizedBox(width: 12),
              // Contenido textual.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.message,
                            style: tt.bodyMedium?.copyWith(
                              color:      AppColors.textPrimary,
                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        // Punto azul indicador de no leída (solo si no está seleccionada).
                        if (isUnread && !isSelected)
                          Container(
                            width:  8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6, top: 4),
                            decoration: const BoxDecoration(
                              color:  AppColors.info,
                              shape:  BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(notification.createdAt),
                      style: tt.labelSmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              // Checkbox de selección a la derecha.
              Checkbox(
                value:       isSelected,
                onChanged:   (_) => onToggle(),
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) => switch (type) {
    'watering'      => Icons.water_drop_outlined,
    'pruning'       => Icons.content_cut_rounded,
    'fertilizing'   => Icons.science_outlined,
    'repotting'     => Icons.yard_outlined,
    'harvest'       => Icons.agriculture_outlined,
    'custom'        => Icons.info_outline_rounded,
    'admin_warning' => Icons.gavel_rounded,
    _               => Icons.notifications_outlined,
  };

  Color _colorForType(String type) => switch (type) {
    'watering'      => AppColors.info,
    'pruning'       => AppColors.secondary,
    'fertilizing'   => AppColors.warning,
    'repotting'     => AppColors.primary,
    'harvest'       => AppColors.accent,
    'custom'        => AppColors.info,
    'admin_warning' => AppColors.error,
    _               => AppColors.textSecondary,
  };

  String _formatDate(DateTime date) {
    final now  = DateTime.now();
    final diff = now.difference(date.toLocal());
    if (diff.inDays == 0) return 'Hoy ${DateFormat('HH:mm').format(date.toLocal())}';
    if (diff.inDays == 1) return 'Ayer ${DateFormat('HH:mm').format(date.toLocal())}';
    if (diff.inDays  < 0) return DateFormat("d MMM · HH:mm", 'es').format(date.toLocal());
    return DateFormat("d MMM yyyy · HH:mm", 'es').format(date.toLocal());
  }
}

// ─── Estado vacío ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            size:  72,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes notificaciones',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los recordatorios de riego y poda\naparecerán aquí.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
