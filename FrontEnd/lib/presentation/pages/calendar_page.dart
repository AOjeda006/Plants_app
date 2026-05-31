/// @file calendar_page.dart
/// @description Página de calendario de recordatorios de plantas.
/// Muestra un calendario mensual con marcadores de riego, poda y cosecha.
/// Al tocar un día marcado se despliega un bottom sheet con los eventos.
/// @module Plants
/// @layer Presentation
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/config/app_theme.dart';
import '../../core/di/container.dart';
import '../viewmodels/plants/calendar_viewmodel.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CALENDAR PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Página de calendario de recordatorios. Sin argumentos de ruta.
class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CalendarViewModel>(
      create: (_) => sl<CalendarViewModel>()..loadCalendar(),
      child: const _CalendarContent(),
    );
  }
}

// ─── Contenido ───────────────────────────────────────────────────────────────

class _CalendarContent extends StatelessWidget {
  const _CalendarContent();

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<CalendarViewModel, bool>((vm) => vm.isLoading);
    final error     = context.select<CalendarViewModel, dynamic>((vm) => vm.error);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Calendario'),
        actions: [
          IconButton(
            icon:    const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: () => context.read<CalendarViewModel>().loadCalendar(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : error != null
              ? _ErrorState(onRetry: () => context.read<CalendarViewModel>().loadCalendar())
              : const _CalendarBody(),
    );
  }
}

// ─── Cuerpo del calendario ───────────────────────────────────────────────────

class _CalendarBody extends StatelessWidget {
  const _CalendarBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CalendarViewModel>();

    return Column(
      children: [
        // Leyenda de colores.
        const _Legend(),

        // Calendario mensual.
        _CalendarWidget(
          focusedDay:  vm.focusedDay,
          selectedDay: vm.selectedDay,
          events:      vm.events,
          onDaySelected: (day, focused) {
            vm.selectDay(day);
          },
          onPageChanged: (day) {
            vm.updateFocusedDay(day);
          },
        ),

        const Divider(height: 1),

        // Lista de eventos del día seleccionado.
        Expanded(child: _EventsList(events: vm.selectedDayEvents)),
      ],
    );
  }
}

// ─── Widget del calendario ───────────────────────────────────────────────────

class _CalendarWidget extends StatelessWidget {
  const _CalendarWidget({
    required this.focusedDay,
    required this.selectedDay,
    required this.events,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  final DateTime focusedDay;
  final DateTime selectedDay;
  final Map<DateTime, List<CalendarEvent>> events;
  final void Function(DateTime selected, DateTime focused) onDaySelected;
  final void Function(DateTime focused) onPageChanged;

  @override
  Widget build(BuildContext context) {
    return TableCalendar<CalendarEvent>(
      firstDay:        DateTime.utc(2025, 1, 1),
      lastDay:         DateTime.utc(2030, 12, 31),
      focusedDay:      focusedDay,
      selectedDayPredicate: (day) => isSameDay(day, selectedDay),
      onDaySelected:   onDaySelected,
      onPageChanged:   onPageChanged,
      locale:          'es_ES',
      startingDayOfWeek: StartingDayOfWeek.monday,

      // Cargar eventos para cada día.
      eventLoader: (day) {
        final key = DateTime.utc(day.year, day.month, day.day);
        return events[key] ?? [];
      },

      // Estilo del calendario.
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered:       true,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize:   16,
          color:      AppColors.textPrimary,
        ),
        leftChevronIcon:  Icon(Icons.chevron_left_rounded,  color: AppColors.primary),
        rightChevronIcon: Icon(Icons.chevron_right_rounded, color: AppColors.primary),
      ),

      calendarStyle: CalendarStyle(
        // Días normales: texto negro sobre fondo blanco.
        defaultTextStyle: const TextStyle(color: Colors.black),
        // Fines de semana (domingos): texto rojo.
        weekendTextStyle: const TextStyle(color: AppColors.error),
        todayDecoration: BoxDecoration(
          color: AppColors.primary.withAlpha(51),
          shape: BoxShape.circle,
        ),
        todayTextStyle: const TextStyle(
          color:      AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
        selectedDecoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(
          color:      Colors.white,
          fontWeight: FontWeight.w700,
        ),
        outsideDaysVisible: false,
        markersMaxCount: 3,
      ),

      // Marcadores debajo de cada día con eventos.
      calendarBuilders: CalendarBuilders<CalendarEvent>(
        markerBuilder: (ctx, day, eventsList) {
          if (eventsList.isEmpty) return null;

          // Colores únicos de los tipos presentes en ese día.
          final types = eventsList.map((e) => e.type).toSet();

          return Positioned(
            bottom: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: types.map((type) {
                return Container(
                  width:  6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _colorForType(type),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

// ─── Lista de eventos del día ────────────────────────────────────────────────

class _EventsList extends StatelessWidget {
  const _EventsList({required this.events});

  final List<CalendarEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Sin recordatorios este día',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.separated(
      padding:      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount:    events.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final event = events[i];
        return _EventTile(event: event);
      },
    );
  }
}

// ─── Tile de evento ──────────────────────────────────────────────────────────

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(event.type);

    return Container(
      padding:    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:        color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        children: [
          Text(event.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${event.label} ${event.plantName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize:   14,
                    color:      AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.plantName,
                  style: const TextStyle(
                    fontSize: 12,
                    color:    AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:        color.withAlpha(38),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              event.label,
              style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w600,
                color:      color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Leyenda ─────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendDot(color: _colorForType(CalendarEventType.watering), label: 'Riego'),
          const SizedBox(width: 16),
          _LegendDot(color: _colorForType(CalendarEventType.pruning),  label: 'Poda'),
          const SizedBox(width: 16),
          _LegendDot(color: _colorForType(CalendarEventType.harvest),  label: 'Cosecha'),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color  color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width:  10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ─── Estado de error ─────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Error al cargar el calendario',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style:     ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child:     const Text('Reintentar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Color asociado a cada tipo de evento.
Color _colorForType(CalendarEventType type) => switch (type) {
  CalendarEventType.watering => AppColors.primary,
  CalendarEventType.pruning  => AppColors.warning,
  CalendarEventType.harvest  => AppColors.secondary,
};
