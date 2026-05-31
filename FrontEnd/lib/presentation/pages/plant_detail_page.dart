/// @file plant_detail_page.dart
/// @description Pantalla de detalle de una planta del usuario.
/// Muestra foto, información de cuidados, countdown de riego y acciones (editar/eliminar).
/// Incluye banner de estado del clima si la planta tiene ubicación.
/// @module Plants
/// @layer Presentation
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_theme.dart';
import '../../core/di/container.dart';
import '../../core/errors/app_error.dart';
import '../../domain/entities/plant.dart';
import '../../domain/entities/plant_species.dart';
import '../routes/app_router.dart';
import '../viewmodels/auth/auth_viewmodel.dart';
import '../viewmodels/plants/plant_detail_viewmodel.dart';
import '../widgets/image_viewer.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PLANT DETAIL PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Pantalla de detalle de planta. Recibe [plantId] como parámetro de ruta.
class PlantDetailPage extends StatelessWidget {
  const PlantDetailPage({super.key, required this.plantId});

  final String plantId;

  @override
  Widget build(BuildContext context) {
    final userLocation = context.read<AuthViewModel>().currentUser?.location;
    return ChangeNotifierProvider<PlantDetailViewModel>(
      create: (_) => sl<PlantDetailViewModel>()
          ..loadPlant(plantId, userLocation: userLocation),
      child: _PlantDetailContent(plantId: plantId),
    );
  }
}

// ─── Contenido principal ──────────────────────────────────────────────────────

class _PlantDetailContent extends StatelessWidget {
  const _PlantDetailContent({required this.plantId});

  final String plantId;

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<PlantDetailViewModel, bool>((vm) => vm.isLoading);
    final error     = context.select<PlantDetailViewModel, AppError?>((vm) => vm.error);

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body:   const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body:   _ErrorBody(error: error, plantId: plantId),
      );
    }

    final plant = context.select<PlantDetailViewModel, Plant?>((vm) => vm.plant);
    if (plant == null) return const SizedBox.shrink();

    return _PlantScaffold(plant: plant, plantId: plantId);
  }
}

// ─── Scaffold principal ───────────────────────────────────────────────────────

class _PlantScaffold extends StatelessWidget {
  const _PlantScaffold({required this.plant, required this.plantId});

  final Plant  plant;
  final String plantId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── AppBar con foto ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned:         true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                plant.name,
                style: const TextStyle(
                  color:   Colors.white,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
              background: plant.hasPhoto
                  ? GestureDetector(
                      onTap: () => showFullScreenImage(context, plant.photo!),
                      child: Image.network(
                        plant.photo!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
                      ),
                    )
                  : const _PhotoPlaceholder(),
            ),
            actions: [
              // Botón editar
              IconButton(
                icon:    const Icon(Icons.edit_outlined, color: Colors.white),
                tooltip: 'Editar planta',
                onPressed: () async {
                  await Navigator.of(context).pushNamed(
                    AppRoutes.plantEdit,
                    arguments: plant,
                  );
                  // Recargar tras editar.
                  if (context.mounted) {
                    context.read<PlantDetailViewModel>().loadPlant(plantId);
                  }
                },
              ),
              // Botón eliminar
              IconButton(
                icon:    const Icon(Icons.delete_outline_rounded, color: Colors.white),
                tooltip: 'Eliminar planta',
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),

          // ── Contenido ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner de estado del clima
                  _WeatherBanner(),
                  const SizedBox(height: 4),

                  // Información de riego (lee del ViewModel para refrescar tras riego)
                  const _WateringCard(),
                  const SizedBox(height: 16),

                  // Detalles de la planta
                  _PlantDetailsSection(plant: plant),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Diálogo de confirmación de borrado ───────────────────────────────────

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text('Eliminar planta'),
        content: Text('¿Eliminar "${plant.name}"? Esta acción no se puede deshacer.'),
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

    final isDeleting = context.read<PlantDetailViewModel>().isDeleting;
    if (isDeleting) return;

    final ok = await context.read<PlantDetailViewModel>().deletePlant();
    if (!context.mounted) return;

    if (ok) {
      Navigator.of(context).pop('deleted');
    } else {
      final err = context.read<PlantDetailViewModel>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            err?.code == ErrorCode.network
                ? 'Sin conexión. La eliminación se ha encolado.'
                : 'Error al eliminar la planta.',
          ),
        ),
      );
    }
  }
}

// ─── Tarjeta de información de riego ─────────────────────────────────────────

class _WateringCard extends StatelessWidget {
  const _WateringCard();

  @override
  Widget build(BuildContext context) {
    // Lee la planta directamente del ViewModel (no por constructor) para que
    // la tarjeta se reconstruya tras waterPlant() — Plant.== compara solo por id,
    // context.select<..., Plant?> no detectaría el cambio.
    final vm         = context.watch<PlantDetailViewModel>();
    final plant      = vm.plant;
    if (plant == null) return const SizedBox.shrink();

    final days       = plant.daysUntilNextWatering;
    final needsWater = plant.needsWatering;

    final Color    color;
    final String   label;
    final IconData icon;

    if (needsWater && days < 0) {
      color = AppColors.error;
      label = 'Atrasado ${-days} ${-days == 1 ? "día" : "días"}';
      icon  = Icons.warning_amber_rounded;
    } else if (needsWater) {
      color = AppColors.warning;
      label = '¡Regar hoy!';
      icon  = Icons.water_drop_rounded;
    } else if (days == 1) {
      color = AppColors.primary;
      label = 'Regar mañana';
      icon  = Icons.water_drop_outlined;
    } else {
      color = AppColors.textSecondary;
      label = 'Regar en $days días';
      icon  = Icons.water_drop_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color:      color,
                    fontWeight: FontWeight.w600,
                    fontSize:   16,
                  ),
                ),
                if (plant.nextWatering != null)
                  Text(
                    'Próximo riego: ${_formatDate(plant.nextWatering!)}',
                    style: TextStyle(
                      color:    color.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          // Botón de riego manual.
          const SizedBox(width: 8),
          vm.isWatering
              ? const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  onPressed: () => _onWater(context),
                  icon: const Icon(Icons.water_drop_rounded),
                  color: AppColors.primary,
                  tooltip: 'Registrar riego',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _onWater(BuildContext context) async {
    final vm = context.read<PlantDetailViewModel>();
    final ok = await vm.waterPlant();
    if (!context.mounted) return;
    final plant = vm.plant;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '¡Riego registrado! Próximo en ${plant?.wateringFrequencyDays ?? 0} días.'
              : 'Error al registrar el riego.',
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, "0")}/'
      '${date.month.toString().padLeft(2, "0")}/'
      '${date.year}';
}

// ─── Helpers de factor estacional ────────────────────────────────────────────

/// Devuelve el factor estacional de riego para la fecha [now] aplicado a la
/// especie [species], o null si la especie no tiene
/// `seasonalWateringAdjustment` configurado.
///
/// Réplica exacta de la fórmula del backend
/// (`ProcessPendingRemindersUseCase.getSeasonalFactor`):
/// - mes 6-8  → summer (default 1.0 si no se configuró).
/// - mes 12-2 → winter (default 1.0).
/// - resto    → primavera/otoño = SIEMPRE 1.0.
///
/// [now] es opcional para facilitar tests; por defecto usa `DateTime.now()`.
@visibleForTesting
double? currentSeasonalFactor(PlantSpecies? species, {DateTime? now}) {
  final adj = species?.seasonalWateringAdjustment;
  if (adj == null) return null;
  final month = (now ?? DateTime.now()).month;
  if (month >= 6 && month <= 8)  return adj.summer ?? 1.0;
  if (month >= 12 || month <= 2) return adj.winter ?? 1.0;
  return 1.0;
}

/// Devuelve el nombre legible de la estación actual.
@visibleForTesting
String currentSeasonLabel({DateTime? now}) {
  final month = (now ?? DateTime.now()).month;
  if (month >= 6  && month <= 8 ) return 'verano';
  if (month >= 9  && month <= 11) return 'otoño';
  if (month >= 12 || month <= 2 ) return 'invierno';
  return 'primavera';
}

// ─── Sección de detalles de la planta ────────────────────────────────────────

class _PlantDetailsSection extends StatelessWidget {
  const _PlantDetailsSection({required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    final tt      = Theme.of(context).textTheme;
    // Especie cargada de forma asíncrona por PlantDetailViewModel.
    final species = context.select<PlantDetailViewModel, PlantSpecies?>(
      (vm) => vm.species,
    );

    // Desglose del cálculo de riego si la especie tiene
    // `seasonalWateringAdjustment` y el factor de la estación actual
    // es ≠ 1.0. Evita la confusión del usuario que ve un número distinto
    // al `wateringFrequencyDays` configurado por culpa del ajuste estacional.
    final seasonalFactor = currentSeasonalFactor(species);
    final showSeasonalBreakdown = seasonalFactor != null && seasonalFactor != 1.0;
    final adjustedDays = showSeasonalBreakdown
        ? math.max(1, (plant.wateringFrequencyDays * seasonalFactor).round())
        : plant.wateringFrequencyDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Frecuencia de riego
        _InfoRow(
          icon:  Icons.repeat_rounded,
          label: 'Frecuencia de riego',
          value: 'Cada ${plant.wateringFrequencyDays} días',
        ),

        // Desglose estacional (solo si el factor no es 1.0).
        if (showSeasonalBreakdown)
          _InfoRow(
            icon:  Icons.wb_twilight_rounded,
            label: 'En esta estación (${currentSeasonLabel()})',
            value: 'Cada $adjustedDays días (factor ${seasonalFactor.toStringAsFixed(1)})',
          ),

        // Ubicación (Interior / Exterior)
        if (plant.location?.isNotEmpty == true)
          _InfoRow(
            icon:  Icons.location_on_outlined,
            label: 'Ubicación',
            value: plant.location!,
          ),

        // Ciudad de la planta
        if (plant.plantLocation?.isNotEmpty == true)
          _InfoRow(
            icon:  Icons.location_city_outlined,
            label: 'Ciudad',
            value: plant.plantLocation!,
          ),

        // Necesidad de luz
        if (plant.careOverrides?.lightNeed?.isNotEmpty == true)
          _InfoRow(
            icon:  Icons.wb_sunny_outlined,
            label: 'Luz necesaria',
            value: switch (plant.careOverrides!.lightNeed) {
              'Low'  => 'Poca',
              'High' => 'Alta',
              _      => 'Media',
            },
          ),

        // Especie: muestra nombre (scientificName) y abre popup de info técnica.
        if (plant.hasSpecies)
          _InfoRow(
            icon:  Icons.eco_outlined,
            label: 'Especie',
            // Mientras se carga la especie: texto de espera; una vez cargada: nombre completo.
            value: species != null
                ? '${species.name} (${species.scientificName})'
                : 'Cargando…',
            onTap: species != null
                ? () {
                    showModalBottomSheet<void>(
                      context:            context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (_) => _SpeciesInfoSheet(
                        species: species,
                      ),
                    );
                  }
                : null,
          ),

        // Poda: visible cuando la especie ya ha sido cargada.
        if (plant.hasSpecies && species != null)
          _InfoRow(
            icon:  Icons.content_cut_outlined,
            label: 'Poda',
            value: species.requiresPruning == true
                ? (species.pruningMonths?.isNotEmpty == true
                    ? species.pruningMonths!.map(_monthName).join(', ')
                    : 'Anual')
                : 'No requiere',
          ),

        // Cosecha: solo si la especie produce fruto.
        if (plant.hasSpecies && species != null && species.produceFruit == true)
          _InfoRow(
            icon:  Icons.agriculture_outlined,
            label: 'Cosecha',
            value: species.harvestMonths?.isNotEmpty == true
                ? species.harvestMonths!.map(_monthName).join(', ')
                : 'Consulta la especie',
          ),

        // Agua por riego (informativo): solo si la especie lo define.
        if (plant.hasSpecies && species != null && species.waterLitersPerWatering != null)
          _InfoRow(
            icon:  Icons.local_drink_outlined,
            label: 'Agua por riego',
            value: '${_fmtNumber(species.waterLitersPerWatering!)} L',
          ),

        // Umbral de lluvia: solo si la especie lo define.
        if (plant.hasSpecies && species != null && species.minRainfallMm != null)
          _InfoRow(
            icon:  Icons.cloud_outlined,
            label: 'Umbral de lluvia',
            value: '${_fmtNumber(species.minRainfallMm!)} mm',
          ),

        // Notas
        if (plant.notes?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          Text(
            'Notas',
            style: tt.titleSmall?.copyWith(
              color:      Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            plant.notes!,
            style: tt.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

}

/// Devuelve el nombre del mes en español dado su número (1–12).
String _monthName(int month) => const [
  '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
][month.clamp(1, 12)];

/// Formatea un número en coma flotante sin decimales si es entero.
String _fmtNumber(double v) =>
    v == v.truncate() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData     icon;
  final String       label;
  final String       value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap:        onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  // Etiqueta: color secundario adaptado al tema.
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  children: [
                    TextSpan(text: '$label: '),
                    TextSpan(
                      text:  value,
                      style: TextStyle(
                        // Valor: primary si es tappable, onSurface del tema en caso contrario.
                        color:      onTap != null ? AppColors.primary : cs.onSurface,
                        fontWeight: FontWeight.w500,
                        decoration: onTap != null ? TextDecoration.underline : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Banner de clima ──────────────────────────────────────────────────────────

class _WeatherBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isLoadingWeather = context.select<PlantDetailViewModel, bool>(
      (vm) => vm.isLoadingWeather,
    );
    final weatherError = context.select<PlantDetailViewModel, AppError?>(
      (vm) => vm.weatherError,
    );
    final plant = context.read<PlantDetailViewModel>().plant;

    // No mostrar banner si la planta no tiene ubicación.
    if (plant?.location == null || plant!.location!.isEmpty) {
      return const SizedBox.shrink();
    }

    if (isLoadingWeather) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child:   LinearProgressIndicator(color: AppColors.info),
      );
    }

    if (weatherError != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:        AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_off_outlined, size: 16, color: AppColors.info),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Datos de clima no disponibles.',
                  style: TextStyle(fontSize: 12, color: AppColors.info),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding:         EdgeInsets.zero,
                  tapTargetSize:   MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.info,
                ),
                onPressed: () =>
                    context.read<PlantDetailViewModel>().refreshWeather(),
                child: const Text('Reintentar', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// ─── Placeholder de foto ──────────────────────────────────────────────────────

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: const Center(
        child: Icon(
          Icons.local_florist_outlined,
          size:  80,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ─── Popup de información de especie ─────────────────────────────────────────

/// BottomSheet con la información técnica de la especie: cuidados, clima y consejos.
class _SpeciesInfoSheet extends StatelessWidget {
  const _SpeciesInfoSheet({required this.species});

  final PlantSpecies species;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize:     0.4,
      maxChildSize:     0.9,
      expand:           false,
      builder: (_, scrollCtrl) => ListView(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // Indicador de arrastre
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color:        cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Nombre y nombre científico
          Text(
            species.name,
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color:      cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            species.scientificName,
            style: tt.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color:     cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // Requisitos de cuidado
          Text(
            'Requisitos de cuidado',
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color:      cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          _SheetCareRow(
            icon:  Icons.water_drop_outlined,
            label: 'Riego',
            value: 'Cada ${species.careRequirements.wateringDays} días',
          ),
          if (species.seasonalWateringAdjustment != null) ...[
            const SizedBox(height: 8),
            _SheetCareRow(
              icon:  Icons.device_thermostat_outlined,
              label: 'Ajuste estacional',
              value: _seasonalLabel(species.careRequirements.wateringDays, species.seasonalWateringAdjustment!),
            ),
          ],
          const SizedBox(height: 8),
          _SheetCareRow(
            icon:  Icons.wb_sunny_outlined,
            label: 'Luz',
            value: _lightLabel(species.careRequirements.lightNeed),
          ),
          if (species.careRequirements.temperatureRange != null) ...[
            const SizedBox(height: 8),
            _SheetCareRow(
              icon:  Icons.thermostat_outlined,
              label: 'Temperatura',
              value: '${_formatTemp(species.careRequirements.temperatureRange!.min)}'
                  ' – '
                  '${_formatTemp(species.careRequirements.temperatureRange!.max)}',
            ),
          ],
          if (species.requiresPruning == true) ...[
            const SizedBox(height: 8),
            _SheetCareRow(
              icon:  Icons.content_cut_outlined,
              label: 'Poda',
              value: species.pruningMonths?.isNotEmpty == true
                  ? species.pruningMonths!.map(_monthName).join(', ')
                  : 'Anual',
            ),
          ],
          if (species.produceFruit == true) ...[
            const SizedBox(height: 8),
            _SheetCareRow(
              icon:  Icons.agriculture_outlined,
              label: 'Cosecha',
              value: species.harvestMonths?.isNotEmpty == true
                  ? species.harvestMonths!.map(_monthName).join(', ')
                  : 'Consulta la especie',
            ),
          ],
          if (species.waterLitersPerWatering != null) ...[
            const SizedBox(height: 8),
            _SheetCareRow(
              icon:  Icons.local_drink_outlined,
              label: 'Agua por riego',
              value: '${_formatLiters(species.waterLitersPerWatering!)} L',
            ),
          ],
          if (species.minRainfallMm != null) ...[
            const SizedBox(height: 8),
            _SheetCareRow(
              icon:  Icons.cloud_outlined,
              label: 'Umbral de lluvia',
              value: '${_formatMm(species.minRainfallMm!)} mm',
            ),
          ],

          // Compatibilidad climática
          if (species.climateCompatibility.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Compatibilidad climática',
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color:      cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 6,
              children: species.climateCompatibility
                  .map((c) => Chip(
                        label:           Text(c),
                        backgroundColor: cs.surfaceContainerHighest,
                        labelStyle:      TextStyle(color: cs.onSurface),
                      ))
                  .toList(),
            ),
          ],

          // Consejos de cuidado
          if (species.tips.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Consejos de cuidado',
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color:      cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ...species.tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.tips_and_updates_outlined,
                      size: 16, color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(tip, style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _seasonalLabel(int baseDays, SeasonalWateringAdjustment adj) {
    final parts = <String>[];
    if (adj.summer != null) {
      final days = (baseDays * adj.summer!).round().clamp(1, 365);
      parts.add('Verano: cada $days días');
    }
    if (adj.winter != null) {
      final days = (baseDays * adj.winter!).round().clamp(1, 365);
      parts.add('Invierno: cada $days días');
    }
    return parts.isEmpty ? 'Sin ajuste' : parts.join(' · ');
  }

  String _lightLabel(String lightNeed) => switch (lightNeed.toLowerCase()) {
    'low'    => 'Baja',
    'medium' => 'Media',
    'high'   => 'Alta',
    _        => lightNeed,
  };

  /// Formatea [celsius] en grados Celsius.
  String _formatTemp(double celsius) => '${celsius.toStringAsFixed(0)}°C';

  /// Formatea litros eliminando decimales cuando son 0.
  String _formatLiters(double l) => l == l.truncate() ? l.toStringAsFixed(0) : l.toStringAsFixed(1);

  /// Formatea milímetros eliminando decimales cuando son 0.
  String _formatMm(double mm) => mm == mm.truncate() ? mm.toStringAsFixed(0) : mm.toStringAsFixed(1);
}

class _SheetCareRow extends StatelessWidget {
  const _SheetCareRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String   label;
  final String   value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text('$label: ', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color:      cs.onSurface,
              fontWeight: FontWeight.w500,
              fontSize:   14,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Estado de error ──────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error, required this.plantId});

  final AppError error;
  final String   plantId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size:  64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'No se pudo cargar la planta.',
              style:     Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<PlantDetailViewModel>().loadPlant(plantId),
              icon:  const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
