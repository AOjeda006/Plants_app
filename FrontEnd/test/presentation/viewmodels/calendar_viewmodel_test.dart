/// @file calendar_viewmodel_test.dart
/// @description Tests unitarios para CalendarViewModel.
/// Verifica cálculo de eventos de riego, poda y cosecha a 90 días.
/// @module Plants
/// @layer Presentation
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:plants_app/core/errors/app_error.dart';
import 'package:plants_app/domain/entities/plant.dart';
import 'package:plants_app/domain/entities/plant_species.dart'
    show PlantSpecies, SpeciesCareRequirements;
import 'package:plants_app/domain/interfaces/usecases/plants/i_get_user_plants_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/plants/i_search_species_use_case.dart';
import 'package:plants_app/presentation/viewmodels/plants/calendar_viewmodel.dart';

// ─── Mocks manuales ───────────────────────────────────────────────────────────

class _MockGetUserPlants implements IGetUserPlantsUseCase {
  List<Plant> returnValue = [];
  AppError?   throwError;

  @override
  Future<List<Plant>> execute() async {
    if (throwError != null) throw throwError!;
    return returnValue;
  }
}

class _MockSearchSpecies implements ISearchSpeciesUseCase {
  List<PlantSpecies> returnValue = [];
  AppError?          throwError;

  @override
  Future<List<PlantSpecies>> execute(String query, {int limit = 20}) async {
    if (throwError != null) throw throwError!;
    return returnValue;
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

final _now  = DateTime.now().toUtc();
final _today = DateTime.utc(_now.year, _now.month, _now.day);

final _care = SpeciesCareRequirements(wateringDays: 7, lightNeed: 'Medium');

Plant _makePlant({
  String id   = 'plant-001',
  String name = 'Monstera',
  String? speciesId,
  int wateringDays = 7,
  DateTime? nextWatering,
}) =>
    Plant(
      id:                    id,
      userId:                'user-001',
      name:                  name,
      speciesId:             speciesId,
      wateringFrequencyDays: wateringDays,
      isActive:              true,
      createdAt:             _now,
      updatedAt:             _now,
      nextWatering:          nextWatering,
    );

PlantSpecies _makeSpecies({
  String id            = 'species-001',
  String name          = 'Monstera deliciosa',
  bool? requiresPruning,
  List<int>? pruningMonths,
  bool? produceFruit,
  List<int>? harvestMonths,
}) =>
    PlantSpecies(
      id:                   id,
      name:                 name,
      scientificName:       name,
      image:                '',
      careRequirements:     _care,
      climateCompatibility: const ['tropical'],
      tips:                 const [],
      isPublic:             true,
      createdBy:            'admin',
      createdAt:            _now,
      updatedAt:            _now,
      requiresPruning:      requiresPruning,
      pruningMonths:        pruningMonths,
      produceFruit:         produceFruit,
      harvestMonths:        harvestMonths,
    );

CalendarViewModel _makeViewModel({
  _MockGetUserPlants? get,
  _MockSearchSpecies? search,
}) =>
    CalendarViewModel(
      getUserPlantsUseCase: get    ?? _MockGetUserPlants(),
      searchSpeciesUseCase: search ?? _MockSearchSpecies(),
    );

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  // ── loadCalendar() ─────────────────────────────────────────────────────────

  group('loadCalendar()', () {
    test('debe generar eventos de riego proyectados desde nextWatering', () async {
      final nextWatering = _today.add(const Duration(days: 3));
      final getPlants = _MockGetUserPlants()
        ..returnValue = [
          _makePlant(
            nextWatering: nextWatering,
            wateringDays: 7,
          ),
        ];
      final vm = _makeViewModel(get: getPlants);

      await vm.loadCalendar();

      expect(vm.isLoading, isFalse);
      expect(vm.error, isNull);

      // Debe tener al menos el primer evento en nextWatering (+3 días)
      final eventsDay3 = vm.events[nextWatering];
      expect(eventsDay3, isNotNull);
      expect(eventsDay3!.length, 1);
      expect(eventsDay3.first.type, CalendarEventType.watering);
      expect(eventsDay3.first.plantName, 'Monstera');

      // También debe haber evento en +10 (3+7)
      final eventsDay10 = vm.events[_today.add(const Duration(days: 10))];
      expect(eventsDay10, isNotNull);
      expect(eventsDay10!.first.type, CalendarEventType.watering);
    });

    test('debe manejar error y establecer _error', () async {
      final getPlants = _MockGetUserPlants()..throwError = AppError.network();
      final vm = _makeViewModel(get: getPlants);

      await vm.loadCalendar();

      expect(vm.error, isNotNull);
      expect(vm.isLoading, isFalse);
      expect(vm.events, isEmpty);
    });

    test('debe generar eventos de poda si la especie tiene requiresPruning', () async {
      // Usar un mes dentro de los próximos 90 días
      final targetMonth = _today.add(const Duration(days: 30)).month;
      final getPlants = _MockGetUserPlants()
        ..returnValue = [
          _makePlant(speciesId: 'sp-1', nextWatering: _today.add(const Duration(days: 100))),
        ];
      final searchSpecies = _MockSearchSpecies()
        ..returnValue = [
          _makeSpecies(id: 'sp-1', requiresPruning: true, pruningMonths: [targetMonth]),
        ];
      final vm = _makeViewModel(get: getPlants, search: searchSpecies);

      await vm.loadCalendar();

      // Buscar eventos de poda en alguno de los días del mes target
      final pruningEvents = vm.events.entries
          .where((e) => e.value.any((ev) => ev.type == CalendarEventType.pruning))
          .toList();
      expect(pruningEvents.isNotEmpty, isTrue);
    });

    test('debe devolver eventos vacíos si no hay plantas', () async {
      final getPlants = _MockGetUserPlants()..returnValue = [];
      final vm = _makeViewModel(get: getPlants);

      await vm.loadCalendar();

      expect(vm.events, isEmpty);
      expect(vm.error, isNull);
    });
  });

  // ── selectDay() ────────────────────────────────────────────────────────────

  group('selectDay()', () {
    test('debe actualizar selectedDay y selectedDayEvents', () async {
      final nextWatering = _today.add(const Duration(days: 5));
      final getPlants = _MockGetUserPlants()
        ..returnValue = [_makePlant(nextWatering: nextWatering, wateringDays: 7)];
      final vm = _makeViewModel(get: getPlants);

      await vm.loadCalendar();
      vm.selectDay(nextWatering);

      expect(vm.selectedDay, nextWatering);
      expect(vm.selectedDayEvents.length, 1);
      expect(vm.selectedDayEvents.first.label, 'Regar');
    });
  });

  // ── CalendarEvent ─────────────────────────────────────────────────────────

  group('CalendarEvent', () {
    test('debe tener iconos y labels correctos por tipo', () {
      const watering = CalendarEvent(plantName: 'X', plantId: 'x', type: CalendarEventType.watering);
      const pruning  = CalendarEvent(plantName: 'X', plantId: 'x', type: CalendarEventType.pruning);
      const harvest  = CalendarEvent(plantName: 'X', plantId: 'x', type: CalendarEventType.harvest);

      expect(watering.icon,  '💧');
      expect(watering.label, 'Regar');
      expect(pruning.icon,   '✂️');
      expect(pruning.label,  'Podar');
      expect(harvest.icon,   '🍎');
      expect(harvest.label,  'Cosechar');
    });
  });
}
