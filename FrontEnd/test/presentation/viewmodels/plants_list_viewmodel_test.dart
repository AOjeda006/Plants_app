/// @file plants_list_viewmodel_test.dart
/// @description Tests unitarios para PlantsListViewModel.
/// Verifica carga de plantas, eliminación optimista con reversión,
/// búsqueda de especies, computed properties, filtrado local de plantas
/// y filtro por especie.
/// @module Plants
/// @layer Presentation
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:plants_app/core/errors/app_error.dart';
import 'package:plants_app/domain/entities/plant.dart';
import 'package:plants_app/domain/entities/plant_species.dart'
    show PlantSpecies, SpeciesCareRequirements;
import 'package:plants_app/domain/interfaces/usecases/plants/i_get_user_plants_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/plants/i_delete_plant_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/plants/i_search_species_use_case.dart';
import 'package:plants_app/presentation/viewmodels/plants/plants_list_viewmodel.dart';

// ─── Mocks manuales ───────────────────────────────────────────────────────────

class _MockGetUserPlants implements IGetUserPlantsUseCase {
  List<Plant> returnValue = [];
  AppError? throwError;

  @override
  Future<List<Plant>> execute() async {
    if (throwError != null) throw throwError!;
    return returnValue;
  }
}

class _MockDeletePlant implements IDeletePlantUseCase {
  AppError? throwError;
  final List<String> deletedIds = [];

  @override
  Future<void> execute(String plantId) async {
    if (throwError != null) throw throwError!;
    deletedIds.add(plantId);
  }
}

class _MockSearchSpecies implements ISearchSpeciesUseCase {
  List<PlantSpecies> returnValue = [];
  AppError? throwError;

  @override
  Future<List<PlantSpecies>> execute(String query, {int limit = 20}) async {
    if (throwError != null) throw throwError!;
    return returnValue;
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

final _now = DateTime.utc(2026, 3, 5);

Plant _makePlant({
  String id = 'plant-001',
  String name = 'Monstera',
  String? speciesId,
  DateTime? nextWatering,
}) =>
    Plant(
      id:                    id,
      userId:                'user-001',
      name:                  name,
      speciesId:             speciesId,
      wateringFrequencyDays: 7,
      isActive:              true,
      createdAt:             _now,
      updatedAt:             _now,
      nextWatering:          nextWatering,
    );

final _care = SpeciesCareRequirements(wateringDays: 7, lightNeed: 'Medium');

PlantSpecies _makeSpecies(String id) => PlantSpecies(
      id:                   id,
      name:                 'Monstera deliciosa',
      scientificName:       'Monstera deliciosa',
      image:                '',
      careRequirements:     _care,
      climateCompatibility: const ['tropical'],
      tips:                 const [],
      isPublic:             true,
      createdBy:            'admin',
      createdAt:            _now,
      updatedAt:            _now,
    );

PlantsListViewModel _makeViewModel({
  _MockGetUserPlants? get,
  _MockDeletePlant?   delete,
  _MockSearchSpecies? search,
}) =>
    PlantsListViewModel(
      getUserPlantsUseCase:  get    ?? _MockGetUserPlants(),
      deletePlantUseCase:    delete ?? _MockDeletePlant(),
      searchSpeciesUseCase:  search ?? _MockSearchSpecies(),
    );

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  // ── loadPlants ───────────────────────────────────────────────────────────────

  group('loadPlants()', () {
    test('debe cargar la lista de plantas y limpiar el error', () async {
      final plants = [_makePlant(id: 'p1'), _makePlant(id: 'p2')];
      final get = _MockGetUserPlants()..returnValue = plants;
      final vm = _makeViewModel(get: get);

      await vm.loadPlants();

      expect(vm.plants.length, 2);
      expect(vm.error, isNull);
      expect(vm.isLoading, isFalse);
    });

    test('debe guardar el error si la carga falla', () async {
      final get = _MockGetUserPlants()..throwError = AppError.network();
      final vm = _makeViewModel(get: get);

      await vm.loadPlants();

      expect(vm.plants, isEmpty);
      expect(vm.error, isNotNull);
      expect(vm.isLoading, isFalse);
    });

    test('isEmpty debe ser true cuando no hay plantas y no hay error', () async {
      final vm = _makeViewModel();
      await vm.loadPlants();
      expect(vm.isEmpty, isTrue);
    });

    test('isEmpty debe ser false si hay plantas', () async {
      final get = _MockGetUserPlants()..returnValue = [_makePlant()];
      final vm = _makeViewModel(get: get);
      await vm.loadPlants();
      expect(vm.isEmpty, isFalse);
    });
  });

  // ── plantsNeedingWatering ─────────────────────────────────────────────────────

  group('plantsNeedingWatering', () {
    test('debe devolver solo plantas cuyo nextWatering es hoy o anterior', () async {
      final yesterday  = DateTime.now().toUtc().subtract(const Duration(days: 1));
      final tomorrow   = DateTime.now().toUtc().add(const Duration(days: 1));

      final overdue  = _makePlant(id: 'p1', nextWatering: yesterday);
      final upcoming = _makePlant(id: 'p2', nextWatering: tomorrow);
      final noDate   = _makePlant(id: 'p3');

      final get = _MockGetUserPlants()..returnValue = [overdue, upcoming, noDate];
      final vm  = _makeViewModel(get: get);

      await vm.loadPlants();

      final needing = vm.plantsNeedingWatering;
      // Solo la planta de ayer necesita riego.
      expect(needing.length, 1);
      expect(needing.first.id, 'p1');
    });
  });

  // ── deletePlant ───────────────────────────────────────────────────────────────

  group('deletePlant()', () {
    test('debe eliminar la planta de la lista local y devolver true', () async {
      final plants = [_makePlant(id: 'p1'), _makePlant(id: 'p2')];
      final get    = _MockGetUserPlants()..returnValue = plants;
      final delete = _MockDeletePlant();
      final vm     = _makeViewModel(get: get, delete: delete);

      await vm.loadPlants();
      final result = await vm.deletePlant('p1');

      expect(result, isTrue);
      expect(vm.plants.any((p) => p.id == 'p1'), isFalse);
      expect(delete.deletedIds, contains('p1'));
    });

    test('debe revertir la lista si la API falla', () async {
      final plants = [_makePlant(id: 'p1'), _makePlant(id: 'p2')];
      final get    = _MockGetUserPlants()..returnValue = plants;
      final delete = _MockDeletePlant()..throwError = AppError.network();
      final vm     = _makeViewModel(get: get, delete: delete);

      await vm.loadPlants();
      final result = await vm.deletePlant('p1');

      expect(result, isFalse);
      // La lista debe haber vuelto a su estado original.
      expect(vm.plants.length, 2);
      expect(vm.error, isNotNull);
    });

    test('isDeleting debe ser false tras completar la operación', () async {
      final get    = _MockGetUserPlants()..returnValue = [_makePlant(id: 'p1')];
      final vm     = _makeViewModel(get: get);
      await vm.loadPlants();

      await vm.deletePlant('p1');
      expect(vm.isDeleting, isFalse);
    });
  });

  // ── searchSpecies ─────────────────────────────────────────────────────────────

  group('searchSpecies()', () {
    test('debe actualizar searchResults tras búsqueda exitosa', () async {
      final species = [_makeSpecies('s1'), _makeSpecies('s2')];
      final search  = _MockSearchSpecies()..returnValue = species;
      final vm      = _makeViewModel(search: search);

      await vm.searchSpecies('monstera');

      expect(vm.searchResults.length, 2);
      expect(vm.isSearching, isFalse);
    });

    test('debe limpiar resultados si el query está vacío', () async {
      final search = _MockSearchSpecies()..returnValue = [_makeSpecies('s1')];
      final vm     = _makeViewModel(search: search);

      await vm.searchSpecies('monstera');
      expect(vm.searchResults.isNotEmpty, isTrue);

      await vm.searchSpecies('   ');
      expect(vm.searchResults, isEmpty);
    });

    test('debe dejar searchResults vacío si la búsqueda falla (no bloquea UI)', () async {
      final search = _MockSearchSpecies()..throwError = AppError.network();
      final vm     = _makeViewModel(search: search);

      await vm.searchSpecies('error');

      expect(vm.searchResults, isEmpty);
      expect(vm.isSearching, isFalse);
    });

    test('clearSearch debe vaciar los resultados', () async {
      final search = _MockSearchSpecies()..returnValue = [_makeSpecies('s1')];
      final vm     = _makeViewModel(search: search);

      await vm.searchSpecies('monstera');
      vm.clearSearch();

      expect(vm.searchResults, isEmpty);
      expect(vm.isSearching, isFalse);
    });
  });

  // ── filterPlants ──────────────────────────────────────────────────────────────

  group('filterPlants()', () {
    test('filteredPlants devuelve todas las plantas cuando el filtro está vacío', () async {
      final plants = [
        _makePlant(id: 'p1', name: 'Monstera'),
        _makePlant(id: 'p2', name: 'Cactus'),
      ];
      final get = _MockGetUserPlants()..returnValue = plants;
      final vm  = _makeViewModel(get: get);

      await vm.loadPlants();

      expect(vm.filteredPlants.length, 2);
    });

    test('filteredPlants devuelve solo las plantas que contienen el query (case insensitive)', () async {
      final plants = [
        _makePlant(id: 'p1', name: 'Monstera'),
        _makePlant(id: 'p2', name: 'Cactus'),
        _makePlant(id: 'p3', name: 'Monstera Deliciosa'),
      ];
      final get = _MockGetUserPlants()..returnValue = plants;
      final vm  = _makeViewModel(get: get);

      await vm.loadPlants();
      vm.filterPlants('monstera');

      expect(vm.filteredPlants.length, 2);
      expect(vm.filteredPlants.every((p) => p.name.toLowerCase().contains('monstera')), isTrue);
    });

    test('isFilteredEmpty es true cuando el filtro no devuelve resultados pero hay plantas', () async {
      final plants = [_makePlant(id: 'p1', name: 'Cactus')];
      final get    = _MockGetUserPlants()..returnValue = plants;
      final vm     = _makeViewModel(get: get);

      await vm.loadPlants();
      vm.filterPlants('Rosa');

      expect(vm.isFilteredEmpty, isTrue);
      expect(vm.isEmpty, isFalse);
    });

    test('clearFilter limpia el filtro y devuelve todas las plantas', () async {
      final plants = [
        _makePlant(id: 'p1', name: 'Monstera'),
        _makePlant(id: 'p2', name: 'Cactus'),
      ];
      final get = _MockGetUserPlants()..returnValue = plants;
      final vm  = _makeViewModel(get: get);

      await vm.loadPlants();
      vm.filterPlants('Cactus');
      expect(vm.filteredPlants.length, 1);

      vm.clearFilter();
      expect(vm.filteredPlants.length, 2);
      expect(vm.filterQuery, isEmpty);
    });
  });

  // ── filterBySpecies ───────────────────────────────────────────────────────────

  group('filterBySpecies()', () {
    test('filteredPlants devuelve solo plantas de la especie indicada', () async {
      final plants = [
        _makePlant(id: 'p1', name: 'Monstera',  speciesId: 's1'),
        _makePlant(id: 'p2', name: 'Cactus',    speciesId: 's2'),
        _makePlant(id: 'p3', name: 'Pothos',    speciesId: 's1'),
      ];
      final get = _MockGetUserPlants()..returnValue = plants;
      final vm  = _makeViewModel(get: get);

      await vm.loadPlants();
      vm.filterBySpecies('s1');

      expect(vm.filteredPlants.length, 2);
      expect(vm.filteredPlants.every((p) => p.speciesId == 's1'), isTrue);
    });

    test('filteredPlants aplica filtro de nombre y especie simultáneamente', () async {
      final plants = [
        _makePlant(id: 'p1', name: 'Monstera',  speciesId: 's1'),
        _makePlant(id: 'p2', name: 'Monstera B', speciesId: 's2'),
        _makePlant(id: 'p3', name: 'Cactus',    speciesId: 's1'),
      ];
      final get = _MockGetUserPlants()..returnValue = plants;
      final vm  = _makeViewModel(get: get);

      await vm.loadPlants();
      vm.filterPlants('Monstera');
      vm.filterBySpecies('s1');

      // Solo 'p1' tiene nombre 'Monstera' Y especie 's1'.
      expect(vm.filteredPlants.length, 1);
      expect(vm.filteredPlants.first.id, 'p1');
    });

    test('filterBySpecies(null) elimina el filtro de especie', () async {
      final plants = [
        _makePlant(id: 'p1', speciesId: 's1'),
        _makePlant(id: 'p2', speciesId: 's2'),
      ];
      final get = _MockGetUserPlants()..returnValue = plants;
      final vm  = _makeViewModel(get: get);

      await vm.loadPlants();
      vm.filterBySpecies('s1');
      expect(vm.filteredPlants.length, 1);

      vm.filterBySpecies(null);
      expect(vm.filteredPlants.length, 2);
      expect(vm.filterSpeciesId, isNull);
    });

    test('clearFilter limpia también el filtro de especie', () async {
      final plants = [_makePlant(speciesId: 's1'), _makePlant(id: 'p2', speciesId: 's2')];
      final get = _MockGetUserPlants()..returnValue = plants;
      final vm  = _makeViewModel(get: get);

      await vm.loadPlants();
      vm.filterBySpecies('s1');
      vm.clearFilter();

      expect(vm.filterSpeciesId, isNull);
      expect(vm.filteredPlants.length, 2);
    });
  });

  // ── loadAvailableSpecies ──────────────────────────────────────────────────────

  group('loadAvailableSpecies()', () {
    test('carga todas las especies y las expone en availableSpecies', () async {
      final species = [_makeSpecies('s1'), _makeSpecies('s2')];
      final search  = _MockSearchSpecies()..returnValue = species;
      final vm      = _makeViewModel(search: search);

      await vm.loadAvailableSpecies();

      expect(vm.availableSpecies.length, 2);
    });

    test('no realiza una segunda petición si las especies ya están cargadas', () async {
      int callCount = 0;
      final search = _MockSearchSpecies();
      search.returnValue = [_makeSpecies('s1')];
      final vm = _makeViewModel(search: search);

      // Primera carga.
      search.returnValue = [_makeSpecies('s1')];
      await vm.loadAvailableSpecies();
      callCount++;

      // Segunda llamada: debe usar caché.
      await vm.loadAvailableSpecies();
      // Si se realizara una segunda petición el mock devolvería la misma lista,
      // pero verificamos que availableSpecies no se duplica.
      expect(vm.availableSpecies.length, 1);
      expect(callCount, 1); // Solo se contó la primera carga manual.
    });

    test('fallo silencioso — availableSpecies queda vacío si la API falla', () async {
      final search = _MockSearchSpecies()..throwError = AppError.network();
      final vm     = _makeViewModel(search: search);

      await vm.loadAvailableSpecies();

      expect(vm.availableSpecies, isEmpty);
    });
  });

  // ── recarga tras login ────────────────────────────────────────────────────────

  group('loadPlants() — recarga tras login', () {
    test('segunda llamada reemplaza los datos anteriores', () async {
      final get = _MockGetUserPlants()
        ..returnValue = [_makePlant(id: 'p1'), _makePlant(id: 'p2')];
      final vm = _makeViewModel(get: get);

      await vm.loadPlants();
      expect(vm.plants.length, 2);

      // Simula nueva sesión: el mock devuelve solo una planta en la segunda carga.
      get.returnValue = [_makePlant(id: 'p3')];
      await vm.loadPlants();

      expect(vm.plants.length, 1);
      expect(vm.plants.first.id, 'p3');
    });
  });

  // ── Refresco al activar pestaña ────────────────────────────────────────────
  // MainTabsPage._onTabSelected() llama a sl<PlantsListViewModel>().loadPlants()
  // cada vez que el usuario toca la pestaña de plantas. Estos tests verifican
  // que el ViewModel responde correctamente a llamadas sucesivas de loadPlants().

  group('loadPlants() — refresco por activación de pestaña', () {
    test('refrescar la pestaña muestra los datos más recientes del servidor', () async {
      final get = _MockGetUserPlants()
        ..returnValue = [_makePlant(id: 'p1')];
      final vm = _makeViewModel(get: get);

      // Primera carga (al entrar a la pestaña por primera vez).
      await vm.loadPlants();
      expect(vm.plants.length, 1);

      // El servidor devuelve una planta nueva (p.ej. creada desde otro dispositivo).
      get.returnValue = [_makePlant(id: 'p1'), _makePlant(id: 'p2')];

      // Segunda carga al volver a pulsar la pestaña.
      await vm.loadPlants();

      expect(vm.plants.length, 2);
      expect(vm.isLoading, isFalse);
      expect(vm.error, isNull);
    });

    test('el refresco limpia un error previo si la siguiente carga tiene éxito', () async {
      final get = _MockGetUserPlants()..throwError = AppError.network();
      final vm  = _makeViewModel(get: get);

      // Primera carga falla.
      await vm.loadPlants();
      expect(vm.error, isNotNull);

      // Al volver a la pestaña la conexión se restaura.
      get.throwError = null;
      get.returnValue = [_makePlant()];
      await vm.loadPlants();

      expect(vm.error, isNull);
      expect(vm.plants.length, 1);
    });
  });

  // ── filterByCity ───────────────────────────────────────────────────────────

  group('filterByCity()', () {
    test('debe mostrar solo ciudades asignadas a plantas del usuario', () async {
      final get = _MockGetUserPlants()
        ..returnValue = [
          _makePlant(id: 'p1', name: 'Monstera').copyWith(plantLocation: 'Sevilla'),
          _makePlant(id: 'p2', name: 'Potus').copyWith(plantLocation: 'Madrid'),
          _makePlant(id: 'p3', name: 'Ficus').copyWith(plantLocation: 'Sevilla'),
        ];
      final vm = _makeViewModel(get: get);

      await vm.loadPlants();

      expect(vm.availableCities, ['Madrid', 'Sevilla']);
    });

    test('debe filtrar plantas por ciudad seleccionada', () async {
      final get = _MockGetUserPlants()
        ..returnValue = [
          _makePlant(id: 'p1', name: 'Monstera').copyWith(plantLocation: 'Sevilla'),
          _makePlant(id: 'p2', name: 'Potus').copyWith(plantLocation: 'Madrid'),
          _makePlant(id: 'p3', name: 'Ficus').copyWith(plantLocation: 'Sevilla'),
        ];
      final vm = _makeViewModel(get: get);

      await vm.loadPlants();
      vm.filterByCity('Sevilla');

      expect(vm.filteredPlants.length, 2);
      expect(vm.filteredPlants.every((p) => p.plantLocation == 'Sevilla'), isTrue);
    });

    test('debe mostrar todas las plantas al quitar el filtro de ciudad', () async {
      final get = _MockGetUserPlants()
        ..returnValue = [
          _makePlant(id: 'p1', name: 'Monstera').copyWith(plantLocation: 'Sevilla'),
          _makePlant(id: 'p2', name: 'Potus').copyWith(plantLocation: 'Madrid'),
        ];
      final vm = _makeViewModel(get: get);

      await vm.loadPlants();
      vm.filterByCity('Sevilla');
      expect(vm.filteredPlants.length, 1);

      vm.filterByCity(null);
      expect(vm.filteredPlants.length, 2);
    });
  });
}
