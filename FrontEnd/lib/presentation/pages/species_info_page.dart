/// @file species_info_page.dart
/// @description Pantalla de información detallada de una especie de planta.
/// Muestra nombre científico, imagen, requisitos de cuidado, compatibilidad climática y consejos.
/// @module Plants
/// @layer Presentation
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_theme.dart';
import '../../core/di/container.dart';
import '../../domain/entities/plant_species.dart';
import '../viewmodels/plants/species_info_viewmodel.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SPECIES INFO PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Página de detalle de especie.
///
/// Acepta [species] (objeto completo) o [speciesName] (para buscarlo en la API).
/// Siempre proporcionar al menos uno de los dos.
class SpeciesInfoPage extends StatelessWidget {
  const SpeciesInfoPage({
    super.key,
    this.species,
    this.speciesName,
  }) : assert(
          species != null || speciesName != null,
          'Proporcionar species o speciesName.',
        );

  /// Objeto de especie completo (cuando viene de PlantDetail o de la búsqueda).
  final PlantSpecies? species;

  /// Nombre de la especie para buscarla si no se dispone del objeto completo.
  final String? speciesName;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SpeciesInfoViewModel>(
      create: (_) {
        final vm = sl<SpeciesInfoViewModel>();
        if (species != null) {
          vm.loadFromEntity(species!);
        } else {
          vm.searchByName(speciesName!);
        }
        return vm;
      },
      child: const _SpeciesInfoContent(),
    );
  }
}

// ─── Contenido principal ──────────────────────────────────────────────────────

class _SpeciesInfoContent extends StatelessWidget {
  const _SpeciesInfoContent();

  @override
  Widget build(BuildContext context) {
    final isLoading  = context.select<SpeciesInfoViewModel, bool>((vm) => vm.isLoading);
    final species    = context.select<SpeciesInfoViewModel, PlantSpecies?>((vm) => vm.species);
    final hasError   = context.select<SpeciesInfoViewModel, bool>((vm) => vm.error != null);

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Especie')),
        body:   const Center(child: CircularProgressIndicator()),
      );
    }

    if (hasError || species == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Especie')),
        body:   const Center(
          child: Text('No se pudo cargar la información de la especie.'),
        ),
      );
    }

    return _SpeciesScaffold(species: species);
  }
}

// ─── Scaffold de la especie ───────────────────────────────────────────────────

class _SpeciesScaffold extends StatelessWidget {
  const _SpeciesScaffold({required this.species});

  final PlantSpecies species;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── AppBar con imagen ────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned:         true,
            flexibleSpace:  FlexibleSpaceBar(
              title: Text(
                species.name,
                style: const TextStyle(
                  color:   Colors.white,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
              background: (species.image?.isNotEmpty == true)
                  ? Image.network(
                      species.image!,
                      fit:          BoxFit.cover,
                      errorBuilder: (_, _, _) => const _ImagePlaceholder(),
                    )
                  : const _ImagePlaceholder(),
            ),
          ),

          // ── Contenido ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre científico
                  Text(
                    species.scientificName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      color:     AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Requisitos de cuidado
                  _SectionTitle('Requisitos de cuidado'),
                  const SizedBox(height: 12),
                  _CareRequirementsCard(species: species),
                  const SizedBox(height: 20),

                  // Compatibilidad climática
                  if (species.climateCompatibility.isNotEmpty) ...[
                    _SectionTitle('Compatibilidad climática'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing:    8,
                      runSpacing: 6,
                      children: species.climateCompatibility
                          .map(
                            (c) => Chip(
                              label:           Text(c),
                              backgroundColor: AppColors.surface,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Consejos de cuidado
                  if (species.tips.isNotEmpty) ...[
                    _SectionTitle('Consejos de cuidado'),
                    const SizedBox(height: 8),
                    ...species.tips.map(
                      (tip) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.tips_and_updates_outlined,
                              size:  16,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tip,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tarjeta de requisitos de cuidado ────────────────────────────────────────

class _CareRequirementsCard extends StatelessWidget {
  const _CareRequirementsCard({required this.species});

  final PlantSpecies species;

  @override
  Widget build(BuildContext context) {
    final care = species.careRequirements;

    return Container(
      padding:    const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _CareRow(
            icon:  Icons.water_drop_outlined,
            label: 'Riego',
            value: 'Cada ${care.wateringDays} días',
          ),
          const Divider(height: 20),
          _CareRow(
            icon:  Icons.wb_sunny_outlined,
            label: 'Luz',
            value: _lightNeedLabel(care.lightNeed),
          ),
          if (care.temperatureRange != null) ...[
            const Divider(height: 20),
            _CareRow(
              icon:  Icons.thermostat_outlined,
              label: 'Temperatura',
              value: '${care.temperatureRange!.min.round()}°C'
                  ' – '
                  '${care.temperatureRange!.max.round()}°C',
            ),
          ],
          if (species.waterLitersPerWatering != null) ...[
            const Divider(height: 20),
            _CareRow(
              icon:  Icons.local_drink_outlined,
              label: 'Agua por riego',
              value: '${_fmt(species.waterLitersPerWatering!)} L',
            ),
          ],
          if (species.minRainfallMm != null) ...[
            const Divider(height: 20),
            _CareRow(
              icon:  Icons.cloud_outlined,
              label: 'Umbral de lluvia',
              value: '${_fmt(species.minRainfallMm!)} mm',
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(double v) => v == v.truncate() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  String _lightNeedLabel(String lightNeed) => switch (lightNeed.toLowerCase()) {
        'low'    => 'Baja',
        'medium' => 'Media',
        'high'   => 'Alta',
        _        => lightNeed,
      };
}

class _CareRow extends StatelessWidget {
  const _CareRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String   label;
  final String   value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              color:      AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Utilidades ───────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color:      AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: const Center(
        child: Icon(Icons.eco_outlined, size: 64, color: AppColors.primary),
      ),
    );
  }
}
