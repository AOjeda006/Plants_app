/// @file plants_list_page.dart
/// @description Pantalla principal de la lista de plantas del usuario.
/// Muestra un grid de tarjetas con pull-to-refresh, estado vacío y FAB para añadir planta.
/// @module Plants
/// @layer Presentation
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_theme.dart';
import '../../core/di/container.dart';
import '../../core/errors/app_error.dart';
import '../../domain/entities/plant_species.dart';
import '../routes/app_router.dart';
import '../viewmodels/plants/plants_list_viewmodel.dart';
import '../widgets/plant_card.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PLANTS LIST PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Pantalla de la lista de plantas del usuario.
///
/// Crea un [PlantsListViewModel] propio mediante [ChangeNotifierProvider]
/// y lo destruye al salir de la ruta.
class PlantsListPage extends StatelessWidget {
  const PlantsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // .value: el Provider escucha el singleton sin apropiarse de su ciclo de vida.
    // La carga inicial la dispara MainTabsPage.initState() en cada nuevo login.
    return ChangeNotifierProvider<PlantsListViewModel>.value(
      value: sl<PlantsListViewModel>(),
      child: const _PlantsListContent(),
    );
  }
}

// ─── Contenido principal ──────────────────────────────────────────────────────

class _PlantsListContent extends StatefulWidget {
  const _PlantsListContent();

  @override
  State<_PlantsListContent> createState() => _PlantsListContentState();
}

class _PlantsListContentState extends State<_PlantsListContent> {
  bool _searchActive = false;
  final _searchCtrl  = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _activateSearch() {
    setState(() => _searchActive = true);
  }

  void _deactivateSearch() {
    _searchCtrl.clear();
    context.read<PlantsListViewModel>().filterPlants('');
    setState(() => _searchActive = false);
  }

  Future<void> _openSpeciesFilter() async {
    final vm = context.read<PlantsListViewModel>();
    await vm.loadAvailableSpecies();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _SpeciesFilterSheet(
        species:         vm.availableSpecies,
        selectedId:      vm.filterSpeciesId,
        onSelected:      (id) {
          vm.filterBySpecies(id);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _openCityFilter() {
    final vm     = context.read<PlantsListViewModel>();
    final cities = vm.availableCities;
    if (cities.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _CityFilterSheet(
        cities:     cities,
        selectedCity: vm.filterCity,
        onSelected: (city) {
          vm.filterByCity(city);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filterSpeciesId =
        context.select<PlantsListViewModel, String?>((vm) => vm.filterSpeciesId);
    final filterCity =
        context.select<PlantsListViewModel, String?>((vm) => vm.filterCity);
    final availableSpecies =
        context.select<PlantsListViewModel, List<PlantSpecies>>((vm) => vm.availableSpecies);
    final availableCities =
        context.select<PlantsListViewModel, List<String>>((vm) => vm.availableCities);

    final hasAnyFilter = filterSpeciesId != null || filterCity != null;

    // Nombre de la especie actualmente filtrada (para el chip).
    final activeSpeciesName = filterSpeciesId == null
        ? null
        : availableSpecies
            .where((s) => s.id == filterSpeciesId)
            .map((s) => s.name)
            .firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: _searchActive
            ? TextField(
                controller:    _searchCtrl,
                autofocus:     true,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText:   'Buscar planta...',
                  border:     InputBorder.none,
                  filled:     false,
                ),
                onChanged: (q) =>
                    context.read<PlantsListViewModel>().filterPlants(q),
              )
            : const Text('Mis Plantas'),
        leading: _searchActive
            ? IconButton(
                icon:    const Icon(Icons.arrow_back_rounded),
                tooltip: 'Cancelar búsqueda',
                onPressed: _deactivateSearch,
              )
            : null,
        actions: _searchActive
            ? [
                IconButton(
                  icon:    const Icon(Icons.close_rounded),
                  tooltip: 'Limpiar',
                  onPressed: () {
                    _searchCtrl.clear();
                    context.read<PlantsListViewModel>().filterPlants('');
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.filter_list_rounded,
                    color: hasAnyFilter ? AppColors.primary : null,
                  ),
                  tooltip: 'Filtrar por especie',
                  onPressed: _openSpeciesFilter,
                ),
                if (availableCities.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.location_city_rounded,
                      color: filterCity != null ? AppColors.primary : null,
                    ),
                    tooltip: 'Filtrar por ciudad',
                    onPressed: _openCityFilter,
                  ),
              ]
            : [
                IconButton(
                  icon:    const Icon(Icons.search_rounded),
                  tooltip: 'Buscar planta',
                  onPressed: _activateSearch,
                ),
                IconButton(
                  icon: Icon(
                    Icons.filter_list_rounded,
                    color: hasAnyFilter ? AppColors.primary : null,
                  ),
                  tooltip: 'Filtrar por especie',
                  onPressed: _openSpeciesFilter,
                ),
                if (availableCities.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.location_city_rounded,
                      color: filterCity != null ? AppColors.primary : null,
                    ),
                    tooltip: 'Filtrar por ciudad',
                    onPressed: _openCityFilter,
                  ),
              ],
      ),
      body: Column(
        children: [
          // Chips de filtros activos.
          if (activeSpeciesName != null)
            _ActiveFilterBar(
              label:     activeSpeciesName,
              onRemove:  () => context.read<PlantsListViewModel>().filterBySpecies(null),
            ),
          if (filterCity != null)
            _ActiveFilterBar(
              label:   filterCity,
              prefix:  'Ciudad',
              icon:    Icons.location_city_rounded,
              onRemove: () => context.read<PlantsListViewModel>().filterByCity(null),
            ),
          const Expanded(child: _PlantsBody()),
        ],
      ),
      floatingActionButton: const _AddPlantFab(),
    );
  }
}

// ─── Cuerpo principal ─────────────────────────────────────────────────────────

class _PlantsBody extends StatelessWidget {
  const _PlantsBody();

  @override
  Widget build(BuildContext context) {
    final isLoading       = context.select<PlantsListViewModel, bool>((vm) => vm.isLoading);
    final error           = context.select<PlantsListViewModel, AppError?>((vm) => vm.error);
    final isEmpty         = context.select<PlantsListViewModel, bool>((vm) => vm.isEmpty);
    final isFilteredEmpty = context.select<PlantsListViewModel, bool>((vm) => vm.isFilteredEmpty);
    final filterQuery     = context.select<PlantsListViewModel, String>((vm) => vm.filterQuery);
    final filterSpeciesId = context.select<PlantsListViewModel, String?>((vm) => vm.filterSpeciesId);

    if (isLoading) return const _LoadingGrid();
    if (error != null) return _ErrorState(error: error);
    if (isEmpty) return const _EmptyState();
    if (isFilteredEmpty) {
      return _NoResultsState(
        query:          filterQuery,
        hasSpeciesFilter: filterSpeciesId != null,
      );
    }
    return const _PlantGrid();
  }
}

// ─── Grid de plantas ──────────────────────────────────────────────────────────

class _PlantGrid extends StatelessWidget {
  const _PlantGrid();

  @override
  Widget build(BuildContext context) {
    final plants = context.watch<PlantsListViewModel>().filteredPlants;

    return LayoutBuilder(
      builder: (context, constraints) {
        // En web/tablet (>600px): 4 columnas compactas para aprovechar el ancho.
        // En móvil (≤600px): 2 columnas con proporción original.
        final isWide         = constraints.maxWidth > 600;
        final crossAxisCount = isWide ? 4 : 2;
        final aspectRatio    = isWide ? 1.0 : 0.78;

        return RefreshIndicator(
          color:     AppColors.primary,
          onRefresh: context.read<PlantsListViewModel>().refresh,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:   crossAxisCount,
              mainAxisSpacing:  12,
              crossAxisSpacing: 12,
              childAspectRatio: aspectRatio,
            ),
            itemCount: plants.length,
            itemBuilder: (ctx, i) {
              final plant = plants[i];
              return PlantCard(
                plant: plant,
                onTap: () async {
                  // Navegar al detalle y recargar la lista al volver (por si se editó/eliminó).
                  await Navigator.of(ctx).pushNamed(
                    AppRoutes.plantDetail,
                    arguments: plant.id,
                  );
                  if (ctx.mounted) {
                    ctx.read<PlantsListViewModel>().loadPlants(showLoading: false);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Estado de carga (skeletons) ──────────────────────────────────────────────

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide         = constraints.maxWidth > 600;
        final crossAxisCount = isWide ? 4 : 2;
        final aspectRatio    = isWide ? 1.0 : 0.78;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:   crossAxisCount,
            mainAxisSpacing:  12,
            crossAxisSpacing: 12,
            childAspectRatio: aspectRatio,
          ),
          itemCount:   isWide ? 8 : 6,
          itemBuilder: (_, _) => const _SkeletonCard(),
        );
      },
    );
  }
}

/// Tarjeta esqueleto mientras se carga la lista.
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: Container(color: AppColors.surface)),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 100, decoration: BoxDecoration(
                  color:        AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                )),
                const SizedBox(height: 6),
                Container(height: 12, width: 70, decoration: BoxDecoration(
                  color:        AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Estado vacío ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_florist_outlined,
              size:  72,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 20),
            Text(
              'Aún no tienes plantas',
              style:     tt.titleMedium?.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Pulsa el botón + para añadir tu primera planta.',
              style:     tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sin resultados de búsqueda ───────────────────────────────────────────────

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({
    required this.query,
    this.hasSpeciesFilter = false,
  });

  final String query;
  final bool   hasSpeciesFilter;

  @override
  Widget build(BuildContext context) {
    final tt      = Theme.of(context).textTheme;
    final message = query.isNotEmpty
        ? 'Sin resultados para "$query"'
        : hasSpeciesFilter
            ? 'Sin plantas de esta especie'
            : 'Sin resultados';
    final hint = query.isNotEmpty || hasSpeciesFilter
        ? 'Prueba con otros filtros o añade una nueva planta.'
        : 'Prueba con otro nombre.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size:  64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style:     tt.titleSmall?.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              style:     tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Estado de error ──────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final AppError error;

  @override
  Widget build(BuildContext context) {
    final tt      = Theme.of(context).textTheme;
    final message = switch (error.code) {
      ErrorCode.network      => 'Sin conexión. Mostrando datos en caché.',
      ErrorCode.unauthorized => 'Sesión expirada. Vuelve a iniciar sesión.',
      _                      => 'Error al cargar las plantas. Inténtalo de nuevo.',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              error.code == ErrorCode.network
                  ? Icons.wifi_off_rounded
                  : Icons.error_outline_rounded,
              size:  64,
              color: AppColors.warning,
            ),
            const SizedBox(height: 16),
            Text(message, style: tt.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.read<PlantsListViewModel>().refresh(),
              icon:  const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── FAB añadir planta ────────────────────────────────────────────────────────

class _AddPlantFab extends StatelessWidget {
  const _AddPlantFab();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'fab_plants',
      onPressed: () async {
        await Navigator.of(context).pushNamed(AppRoutes.plantCreate);
        // Recargar la lista al volver del formulario.
        if (context.mounted) {
          context.read<PlantsListViewModel>().loadPlants(showLoading: false);
        }
      },
      tooltip: 'Añadir planta',
      child: const Icon(Icons.add_rounded),
    );
  }
}

// ─── Barra de filtro activo ───────────────────────────────────────────────────

/// Banda superior que indica un filtro activo con botón para eliminarlo.
class _ActiveFilterBar extends StatelessWidget {
  const _ActiveFilterBar({
    required this.label,
    required this.onRemove,
    this.prefix = 'Especie',
    this.icon = Icons.filter_list_rounded,
  });

  final String       label;
  final VoidCallback onRemove;
  final String       prefix;
  final IconData     icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color:   AppColors.primary.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$prefix: $label',
              style: const TextStyle(
                color:    AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 16, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ─── BottomSheet selector de especie ─────────────────────────────────────────

/// Hoja inferior para seleccionar (o limpiar) el filtro de especie.
class _SpeciesFilterSheet extends StatelessWidget {
  const _SpeciesFilterSheet({
    required this.species,
    required this.selectedId,
    required this.onSelected,
  });

  final List<PlantSpecies>    species;
  final String?               selectedId;
  final void Function(String?) onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Filtrar por especie',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (selectedId != null)
                  TextButton(
                    onPressed: () => onSelected(null),
                    child: const Text('Quitar filtro'),
                  ),
              ],
            ),
          ),
          if (species.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount:  species.length,
                itemBuilder: (_, i) {
                  final s          = species[i];
                  final isSelected = s.id == selectedId;
                  return ListTile(
                    leading: Icon(
                      Icons.eco_outlined,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    title:    Text(s.name),
                    subtitle: Text(
                      s.scientificName,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize:  12,
                        color:     AppColors.textSecondary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_rounded, color: AppColors.primary)
                        : null,
                    onTap: () => onSelected(s.id),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── BottomSheet selector de ciudad ──────────────────────────────────────────

/// Hoja inferior para seleccionar (o limpiar) el filtro de ciudad.
class _CityFilterSheet extends StatelessWidget {
  const _CityFilterSheet({
    required this.cities,
    required this.selectedCity,
    required this.onSelected,
  });

  final List<String>            cities;
  final String?                 selectedCity;
  final void Function(String?)  onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Filtrar por ciudad',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (selectedCity != null)
                  TextButton(
                    onPressed: () => onSelected(null),
                    child: const Text('Quitar filtro'),
                  ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount:  cities.length,
              itemBuilder: (_, i) {
                final city       = cities[i];
                final isSelected = city == selectedCity;
                return ListTile(
                  leading: Icon(
                    Icons.location_on_outlined,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  title: Text(city),
                  trailing: isSelected
                      ? const Icon(Icons.check_rounded, color: AppColors.primary)
                      : null,
                  onTap: () => onSelected(city),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
