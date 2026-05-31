/// @file reports_page.dart
/// @description Panel de reportes de incidencias enviados por usuarios.
/// Muestra la lista de reportes con filtros (ticketNumber, estado, rango de
/// fechas), ID visible "INC-XXX", historial de resolución (resolvedBy) y
/// posibilidad de reabrir reportes cerrados.
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
import '../../widgets/image_viewer.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// REPORTS PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Pantalla de reportes de incidencias (solo admin). Sin argumentos de ruta.
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminViewModel>(
      create: (_) => sl<AdminViewModel>()..loadIncidentReports(),
      child: const _ReportsContent(),
    );
  }
}

// ─── Contenido ────────────────────────────────────────────────────────────────

class _ReportsContent extends StatelessWidget {
  const _ReportsContent();

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AdminViewModel, bool>((vm) => vm.isLoading);
    final error     = context.select<AdminViewModel, AppError?>((vm) => vm.error);
    final reports   = context.select<AdminViewModel, List<dynamic>>((vm) => vm.incidentReports);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Reportes de incidencias'),
        actions: [
          IconButton(
            icon:      const Icon(Icons.refresh_rounded),
            tooltip:   'Actualizar',
            onPressed: () => context.read<AdminViewModel>().loadIncidentReports(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Barra de filtros ──
          const _FiltersBar(),
          // ── Lista de reportes ──
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => context.read<AdminViewModel>().loadIncidentReports(),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (error != null)
                          _ErrorBanner(error: error),
                        if (reports.isEmpty)
                          const _EmptyState()
                        else
                          ...reports.map(
                            (r) => _ReportCard(report: r as Map<String, dynamic>),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Barra de filtros ────────────────────────────────────────────────────────

class _FiltersBar extends StatefulWidget {
  const _FiltersBar();

  @override
  State<_FiltersBar> createState() => _FiltersBarState();
}

class _FiltersBarState extends State<_FiltersBar> {
  final _ticketCtrl = TextEditingController();
  String? _selectedStatus;
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _ticketCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final vm = context.read<AdminViewModel>();
    final ticketText = _ticketCtrl.text.trim();
    // Soportar "INC-042" o solo "42".
    final cleaned = ticketText.replaceAll(RegExp(r'[^0-9]'), '');
    final ticketNum = cleaned.isNotEmpty ? int.tryParse(cleaned) : null;

    vm.setFilters(
      ticketNumber: ticketNum,
      status:       _selectedStatus,
      from:         _dateRange?.start.toIso8601String(),
      to:           _dateRange?.end.toIso8601String(),
    );
  }

  void _clearFilters() {
    setState(() {
      _ticketCtrl.clear();
      _selectedStatus = null;
      _dateRange      = null;
    });
    context.read<AdminViewModel>().setFilters(clear: true);
  }

  Future<void> _pickDateRange() async {
    final now    = DateTime.now();
    final picked = await showDateRangePicker(
      context:   context,
      firstDate: DateTime(2025),
      lastDate:  now,
      initialDateRange: _dateRange,
      locale:    const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _applyFilters();
    }
  }

  bool get _hasActiveFilters =>
      _ticketCtrl.text.trim().isNotEmpty ||
      _selectedStatus != null ||
      _dateRange != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      color:   AppColors.backgroundLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          // Fila 1: buscador de ticket + botón fecha
          Row(
            children: [
              // Campo de búsqueda por ticketNumber
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _ticketCtrl,
                    decoration: InputDecoration(
                      hintText:      'Buscar INC-XXX…',
                      hintStyle:     const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      prefixIcon:    const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense:       true,
                    ),
                    style:             const TextStyle(fontSize: 13),
                    textInputAction:   TextInputAction.search,
                    onSubmitted:       (_) => _applyFilters(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Botón de rango de fechas
              SizedBox(
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon:      const Icon(Icons.date_range_rounded, size: 18),
                  label:     Text(
                    _dateRange != null
                        ? '${_dateRange!.start.day}/${_dateRange!.start.month} – ${_dateRange!.end.day}/${_dateRange!.end.month}'
                        : 'Fechas',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding:         const EdgeInsets.symmetric(horizontal: 10),
                    foregroundColor: AppColors.primary,
                    side:            const BorderSide(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Fila 2: chips de estado + limpiar filtros
          Row(
            children: [
              _StatusChip(
                label:      'Pendiente',
                value:      'pending',
                selected:   _selectedStatus == 'pending',
                onSelected: (sel) {
                  setState(() => _selectedStatus = sel ? 'pending' : null);
                  _applyFilters();
                },
              ),
              const SizedBox(width: 6),
              _StatusChip(
                label:      'Resuelto',
                value:      'resolved',
                selected:   _selectedStatus == 'resolved',
                onSelected: (sel) {
                  setState(() => _selectedStatus = sel ? 'resolved' : null);
                  _applyFilters();
                },
              ),
              const SizedBox(width: 6),
              _StatusChip(
                label:      'Descartado',
                value:      'dismissed',
                selected:   _selectedStatus == 'dismissed',
                onSelected: (sel) {
                  setState(() => _selectedStatus = sel ? 'dismissed' : null);
                  _applyFilters();
                },
              ),
              const Spacer(),
              if (_hasActiveFilters)
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon:      const Icon(Icons.clear_rounded, size: 16),
                  label:     const Text('Limpiar', style: TextStyle(fontSize: 12)),
                  style:     TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding:         const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Chip de estado ──────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  final String              label;
  final String              value;
  final bool                selected;
  final ValueChanged<bool>  onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label:           Text(label, style: const TextStyle(fontSize: 11)),
      selected:        selected,
      onSelected:      onSelected,
      selectedColor:   AppColors.primary.withValues(alpha: 0.15),
      checkmarkColor:  AppColors.primary,
      labelStyle:      TextStyle(
        color: selected ? AppColors.primary : AppColors.textSecondary,
      ),
      padding:         const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity:   VisualDensity.compact,
    );
  }
}

// ─── Tarjeta de reporte ───────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});
  final Map<String, dynamic> report;

  @override
  Widget build(BuildContext context) {
    final String  id           = report['id']     as String? ?? '';
    final String  type         = report['type']   as String? ?? 'general';
    final String  text         = report['text']   as String? ?? '';
    final String  status       = report['status'] as String? ?? 'pending';
    final String? imageUrl     = report['imageUrl'] as String?;
    final String? targetId     = report['targetId'] as String?;
    final String? postId       = report['postId']   as String?;
    final int?    ticketNumber = report['ticketNumber'] as int?;
    final Map<String, dynamic>? resolvedBy =
        report['resolvedBy'] as Map<String, dynamic>?;
    final String  dateRaw      = report['createdAt'] as String? ?? '';
    final String  dateStr      = dateRaw.isNotEmpty
        ? dateRaw.substring(0, 10)
        : '—';

    final String ticketLabel = ticketNumber != null
        ? 'INC-${ticketNumber.toString().padLeft(3, '0')}'
        : id.substring(0, 6).toUpperCase();

    final bool isPending       = status == 'pending';
    final bool isClosed        = status == 'resolved' || status == 'dismissed';
    final bool hasTarget       = targetId != null && targetId.isNotEmpty;
    final bool isContentReport = (type == 'post' || type == 'comment') && hasTarget;

    return Card(
      elevation: 0,
      color:     AppColors.backgroundLight,
      margin:    const EdgeInsets.only(bottom: 12),
      shape:     RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: ticketNumber + tipo + estado + fecha
            Row(
              children: [
                // Ticket ID visible
                Text(
                  ticketLabel,
                  style: const TextStyle(
                    fontSize:      13,
                    fontWeight:    FontWeight.w700,
                    color:         AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                _TypeBadge(type: type),
                const SizedBox(width: 8),
                _StatusBadge(status: status),
                const Spacer(),
                Text(
                  dateStr,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Texto del reporte
            Text(
              text,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => showFullScreenImage(context, imageUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    height:    150,
                    fit:       BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
            // Historial de resolución
            if (resolvedBy != null && resolvedBy['adminName'] != null) ...[
              const SizedBox(height: 8),
              _ResolvedByInfo(resolvedBy: resolvedBy),
            ],
            // Enlace directo al contenido reportado
            if (isContentReport) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  final navigateToId = type == 'comment' && postId != null
                      ? postId
                      : targetId;
                  Navigator.of(context).pushNamed(
                    AppRoutes.postDetail,
                    arguments: {
                      'postId':             navigateToId,
                      'reportTicket':       ticketLabel,
                      // Si el reporte es de un comentario, pasar su ID para
                      // que la etiqueta INC-XXX aparezca junto al comentario.
                      if (type == 'comment')
                        'reportedCommentId': targetId,
                    },
                  );
                },
                icon:  const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(
                  type == 'comment'
                      ? 'Ver comentario en su publicación'
                      : 'Ver publicación reportada',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding:         const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
            // Botones de acción
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _resolve(context, id, 'dismissed'),
                    style:     TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                    child:     const Text('Descartar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _resolve(context, id, 'resolved'),
                    style:     FilledButton.styleFrom(backgroundColor: AppColors.primary),
                    child:     const Text('Resolver'),
                  ),
                ],
              ),
            ],
            // Botón de reabrir para reportes cerrados
            if (isClosed) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _resolve(context, id, 'pending'),
                  icon:      const Icon(Icons.replay_rounded, size: 16),
                  label:     const Text('Reabrir'),
                  style:     TextButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    padding:         const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _resolve(BuildContext context, String id, String status) async {
    final vm      = context.read<AdminViewModel>();
    final success = await vm.resolveIncidentReport(id, status);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.error?.message ?? 'Error al actualizar el reporte')),
      );
    }
  }
}

// ─── Info de resolución ──────────────────────────────────────────────────────

class _ResolvedByInfo extends StatelessWidget {
  const _ResolvedByInfo({required this.resolvedBy});
  final Map<String, dynamic> resolvedBy;

  @override
  Widget build(BuildContext context) {
    final adminName  = resolvedBy['adminName'] as String? ?? 'Admin';
    final resolvedAt = resolvedBy['resolvedAt'] as String? ?? '';
    final dateStr    = resolvedAt.length >= 10 ? resolvedAt.substring(0, 10) : '';

    return Container(
      padding:    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:        AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            'Gestionado por $adminName',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          if (dateStr.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              '· $dateStr',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Badge de tipo ────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.toUpperCase(),
        style: const TextStyle(
          fontSize:      10,
          fontWeight:    FontWeight.w700,
          color:         AppColors.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Badge de estado ──────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = switch (status) {
      'resolved'  => (const Color(0xFFE8F5E9), const Color(0xFF388E3C), 'Resuelto'),
      'dismissed' => (const Color(0xFFF5F5F5), AppColors.textSecondary,  'Descartado'),
      _           => (const Color(0xFFFFF8E1), const Color(0xFFF57F17),  'Pendiente'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize:   10,
          fontWeight: FontWeight.w700,
          color:      fg,
        ),
      ),
    );
  }
}

// ─── Estado vacío ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Column(
          children: [
            Icon(Icons.flag_outlined, size: 48, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text(
              'No hay reportes de incidencias.',
              style: TextStyle(color: AppColors.textSecondary),
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
