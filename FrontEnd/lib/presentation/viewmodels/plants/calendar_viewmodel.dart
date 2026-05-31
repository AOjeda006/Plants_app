/// @file calendar_viewmodel.dart
/// @description ViewModel para la página de calendario de recordatorios.
/// Calcula eventos de riego, poda y cosecha a partir de las plantas del usuario
/// y sus especies asociadas. No requiere endpoint adicional.
/// @module Plants
/// @layer Presentation
library;

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../domain/entities/plant.dart';
import '../../../domain/entities/plant_species.dart';
import '../../../domain/interfaces/usecases/plants/i_get_user_plants_use_case.dart';
import '../../../domain/interfaces/usecases/plants/i_search_species_use_case.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CALENDAR EVENT
// ═══════════════════════════════════════════════════════════════════════════════

/// Tipo de evento del calendario.
enum CalendarEventType { watering, pruning, harvest }

/// Evento individual del calendario: un recordatorio calculado para una planta.
class CalendarEvent {
  final String            plantName;
  final String            plantId;
  final CalendarEventType type;

  const CalendarEvent({
    required this.plantName,
    required this.plantId,
    required this.type,
  });

  /// Icono representativo del evento.
  String get icon => switch (type) {
    CalendarEventType.watering => '💧',
    CalendarEventType.pruning  => '✂️',
    CalendarEventType.harvest  => '🍎',
  };

  /// Etiqueta del tipo de evento.
  String get label => switch (type) {
    CalendarEventType.watering => 'Regar',
    CalendarEventType.pruning  => 'Podar',
    CalendarEventType.harvest  => 'Cosechar',
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// CALENDAR VIEWMODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// ViewModel que calcula los eventos del calendario a partir de las plantas
/// del usuario y sus especies. Genera eventos para los próximos 90 días.
///
/// [injectable] registrar en container.dart como factory.
/// [dependencies] IGetUserPlantsUseCase, ISearchSpeciesUseCase.
class CalendarViewModel extends ChangeNotifier {
  final IGetUserPlantsUseCase _getUserPlants;
  final ISearchSpeciesUseCase _searchSpecies;

  CalendarViewModel({
    required IGetUserPlantsUseCase getUserPlantsUseCase,
    required ISearchSpeciesUseCase searchSpeciesUseCase,
  })  : _getUserPlants = getUserPlantsUseCase,
        _searchSpecies = searchSpeciesUseCase;

  // ─── Estado ───────────────────────────────────────────────────────────────

  bool      _isLoading = false;
  AppError? _error;

  /// Mapa de fecha (normalizada a medianoche UTC) → lista de eventos de ese día.
  Map<DateTime, List<CalendarEvent>> _events = {};

  /// Día seleccionado actualmente en el calendario.
  DateTime _selectedDay = _normalizeDate(DateTime.now());

  /// Día con foco visual en el calendario.
  DateTime _focusedDay = DateTime.now();

  bool                                get isLoading   => _isLoading;
  AppError?                           get error       => _error;
  Map<DateTime, List<CalendarEvent>>  get events      => _events;
  DateTime                            get selectedDay => _selectedDay;
  DateTime                            get focusedDay  => _focusedDay;

  /// Eventos del día seleccionado.
  List<CalendarEvent> get selectedDayEvents =>
      _events[_normalizeDate(_selectedDay)] ?? [];

  // ─── Selección de día ──────────────────────────────────────────────────────

  /// Actualiza el día seleccionado y notifica a la vista.
  void selectDay(DateTime day) {
    _selectedDay = _normalizeDate(day);
    _focusedDay  = day;
    notifyListeners();
  }

  /// Actualiza el día con foco (cambio de mes).
  void updateFocusedDay(DateTime day) {
    _focusedDay = day;
    notifyListeners();
  }

  // ─── Carga de datos ────────────────────────────────────────────────────────

  /// Carga las plantas del usuario, obtiene las especies asociadas
  /// y calcula los eventos del calendario para los próximos 90 días.
  Future<void> loadCalendar() async {
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      // Obtener plantas del usuario.
      final plants = await _getUserPlants.execute();

      // Obtener todas las especies para resolver poda/cosecha.
      // Query vacío devuelve todas las especies públicas del catálogo.
      final allSpecies = await _searchSpecies.execute('');

      // Índice de especies por ID para acceso rápido.
      final speciesMap = <String, PlantSpecies>{};
      for (final sp in allSpecies) {
        speciesMap[sp.id] = sp;
      }

      _events = _computeEvents(plants, speciesMap);
    } on AppError catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Cálculo de eventos ────────────────────────────────────────────────────

  /// Horizonte de cálculo: 90 días desde hoy.
  static const int _horizonDays = 90;

  /// Genera el mapa de eventos a partir de las plantas y sus especies.
  Map<DateTime, List<CalendarEvent>> _computeEvents(
    List<Plant> plants,
    Map<String, PlantSpecies> speciesMap,
  ) {
    final result = <DateTime, List<CalendarEvent>>{};
    final today  = _normalizeDate(DateTime.now());

    for (final plant in plants) {
      // Riego: proyectar desde nextWatering con wateringFrequencyDays.
      _addWateringEvents(result, plant, today);

      // Poda y cosecha: según la especie asociada.
      if (plant.speciesId != null) {
        final species = speciesMap[plant.speciesId];
        if (species != null) {
          _addPruningEvents(result, plant, species, today);
          _addHarvestEvents(result, plant, species, today);
        }
      }
    }

    return result;
  }

  /// Proyecta eventos de riego desde nextWatering en intervalos de wateringFrequencyDays.
  void _addWateringEvents(
    Map<DateTime, List<CalendarEvent>> result,
    Plant plant,
    DateTime today,
  ) {
    if (plant.nextWatering == null || plant.wateringFrequencyDays <= 0) return;

    final freq  = plant.wateringFrequencyDays;
    final limit = today.add(const Duration(days: _horizonDays));
    var   date  = _normalizeDate(plant.nextWatering!);

    // Si nextWatering es pasado, avanzar hasta hoy o después.
    while (date.isBefore(today)) {
      date = date.add(Duration(days: freq));
    }

    // Generar eventos futuros hasta el horizonte.
    while (!date.isAfter(limit)) {
      _addEvent(result, date, CalendarEvent(
        plantName: plant.name,
        plantId:   plant.id,
        type:      CalendarEventType.watering,
      ));
      date = date.add(Duration(days: freq));
    }
  }

  /// Añade eventos de poda los días 1 y 15 de cada mes de poda en el horizonte.
  void _addPruningEvents(
    Map<DateTime, List<CalendarEvent>> result,
    Plant plant,
    PlantSpecies species,
    DateTime today,
  ) {
    if (species.requiresPruning != true || species.pruningMonths == null) return;

    final limit = today.add(const Duration(days: _horizonDays));

    // Comprobar día 1 y 15 de cada mes de poda en el año actual y el siguiente.
    for (final month in species.pruningMonths!) {
      for (final year in [today.year, today.year + 1]) {
        for (final day in [1, 15]) {
          final date = DateTime.utc(year, month, day);
          if (!date.isBefore(today) && !date.isAfter(limit)) {
            _addEvent(result, date, CalendarEvent(
              plantName: plant.name,
              plantId:   plant.id,
              type:      CalendarEventType.pruning,
            ));
          }
        }
      }
    }
  }

  /// Añade eventos de cosecha los días 1 y 15 de cada mes de cosecha en el horizonte.
  void _addHarvestEvents(
    Map<DateTime, List<CalendarEvent>> result,
    Plant plant,
    PlantSpecies species,
    DateTime today,
  ) {
    if (species.produceFruit != true ||
        species.harvestMonths == null ||
        species.harvestMonths!.isEmpty) {
      return;
    }

    final limit = today.add(const Duration(days: _horizonDays));

    for (final month in species.harvestMonths!) {
      for (final year in [today.year, today.year + 1]) {
        for (final day in [1, 15]) {
          final date = DateTime.utc(year, month, day);
          if (!date.isBefore(today) && !date.isAfter(limit)) {
            _addEvent(result, date, CalendarEvent(
              plantName: plant.name,
              plantId:   plant.id,
              type:      CalendarEventType.harvest,
            ));
          }
        }
      }
    }
  }

  /// Añade un evento a la lista del día correspondiente.
  void _addEvent(
    Map<DateTime, List<CalendarEvent>> map,
    DateTime date,
    CalendarEvent event,
  ) {
    final key = _normalizeDate(date);
    (map[key] ??= []).add(event);
  }

  /// Normaliza una fecha a medianoche UTC (sin hora) para usar como clave del mapa.
  static DateTime _normalizeDate(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day);
}
