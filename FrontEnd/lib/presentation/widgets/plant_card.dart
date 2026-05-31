/// @file plant_card.dart
/// @description Widget de tarjeta de planta para la lista.
/// Muestra foto, nombre, próximo riego y badge de alerta cuando la planta necesita riego.
/// @module Plants
/// @layer Presentation
library;

import 'package:flutter/material.dart';

import '../../core/config/app_theme.dart';
import '../../domain/entities/plant.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PLANT CARD
// ═══════════════════════════════════════════════════════════════════════════════

/// Tarjeta que muestra el resumen de una planta: foto, nombre y próximo riego.
///
/// Muestra un badge naranja si la planta necesita riego hoy o está atrasada.
/// Widget stateless — no mantiene estado propio.
class PlantCard extends StatelessWidget {
  const PlantCard({
    super.key,
    required this.plant,
    this.onTap,
  });

  /// La planta a representar.
  final Plant plant;

  /// Callback al pulsar la tarjeta.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    // onSurface se adapta al tema activo: textPrimary en claro, blanco en oscuro.
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Foto de la planta ──────────────────────────────────────────
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Imagen o placeholder verde
                  plant.hasPhoto
                      ? Image.network(
                          plant.photo!,
                          fit: BoxFit.cover,
                          semanticLabel: 'Foto de la planta ${plant.name}',
                          errorBuilder: (_, _, _) => _PhotoPlaceholder(),
                        )
                      : _PhotoPlaceholder(),

                  // Badge naranja de alerta de riego
                  if (plant.needsWatering)
                    Positioned(
                      top:   8,
                      right: 8,
                      child: _WateringBadge(
                        daysOverdue: -plant.daysUntilNextWatering,
                      ),
                    ),
                ],
              ),
            ),

            // ── Info de la planta ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre: usa onSurface para contraste correcto en light y dark.
                  Text(
                    plant.name,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:      onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Próximo riego
                  _NextWateringLabel(plant: plant),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Subwidgets privados ──────────────────────────────────────────────────────

/// Placeholder verde cuando la planta no tiene foto.
class _PhotoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: const Center(
        child: Icon(
          Icons.local_florist_outlined,
          size:  48,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// Badge naranja superpuesto a la foto cuando la planta necesita riego.
class _WateringBadge extends StatelessWidget {
  const _WateringBadge({required this.daysOverdue});

  /// Días de retraso (0 = hoy; positivo = ya superado).
  final int daysOverdue;

  @override
  Widget build(BuildContext context) {
    final label = daysOverdue <= 0
        ? '¡Riego hoy!'
        : 'Riego +$daysOverdue ${daysOverdue == 1 ? "día" : "días"}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:        AppColors.warning,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.water_drop_outlined, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color:      Colors.white,
              fontSize:   11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta que describe cuándo es el próximo riego en lenguaje natural.
class _NextWateringLabel extends StatelessWidget {
  const _NextWateringLabel({required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    if (plant.nextWatering == null) {
      return Text(
        'Sin fecha de riego',
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      );
    }

    final days = plant.daysUntilNextWatering;
    final String label;
    final Color  color;

    if (days < 0) {
      label = 'Atrasado ${-days} ${-days == 1 ? "día" : "días"}';
      color = AppColors.error;
    } else if (days == 0) {
      label = 'Regar hoy';
      color = AppColors.warning;
    } else if (days == 1) {
      label = 'Regar mañana';
      color = AppColors.textPrimary;
    } else {
      label = 'Regar en $days días';
      color = AppColors.textSecondary;
    }

    return Row(
      children: [
        Icon(Icons.water_drop_outlined, size: 13, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize:   12,
              color:      color,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
