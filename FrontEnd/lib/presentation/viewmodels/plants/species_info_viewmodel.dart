/// @file species_info_viewmodel.dart
/// @description ViewModel de la pantalla de información de especie.
/// Permite cargar la especie directamente desde una entidad o buscarla por nombre.
/// Depende SOLO de interfaces de use cases — nunca de implementaciones concretas.
/// @module Plants
/// @layer Presentation
library;

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../domain/entities/plant_species.dart';
import '../../../domain/interfaces/usecases/plants/i_search_species_use_case.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SPECIES INFO VIEWMODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// ViewModel de la pantalla de detalle de especie. Extiende [ChangeNotifier] para Provider.
///
/// Estado gestionado:
///  - [species]   — especie a mostrar (null mientras se carga o si hay error).
///  - [isLoading] — true mientras se busca la especie en la API.
///  - [error]     — último error ocurrido (null si no hay error).
///
/// Uso típico:
///  1. Si se navega con un objeto [PlantSpecies] completo, llamar [loadFromEntity].
///  2. Si solo se tiene el nombre, llamar [searchByName] para buscarlo en la API.
///
/// [injectable] registrar en container.dart como factory.
/// [dependencies] ISearchSpeciesUseCase.
class SpeciesInfoViewModel extends ChangeNotifier {
  final ISearchSpeciesUseCase _searchSpecies;

  SpeciesInfoViewModel({required ISearchSpeciesUseCase searchSpeciesUseCase})
      : _searchSpecies = searchSpeciesUseCase;

  // ─── Estado ───────────────────────────────────────────────────────────────────

  PlantSpecies? _species;
  bool          _isLoading = false;
  AppError?     _error;

  PlantSpecies? get species   => _species;
  bool          get isLoading => _isLoading;
  AppError?     get error     => _error;

  // ─── Carga de especie ─────────────────────────────────────────────────────────

  /// Carga la especie directamente desde una entidad ya disponible (sin llamada a la API).
  void loadFromEntity(PlantSpecies species) {
    _species   = species;
    _isLoading = false;
    _error     = null;
    notifyListeners();
  }

  /// Busca la especie por [name] (coge el primer resultado) y carga su información.
  /// Se usa cuando solo se dispone del nombre pero no del objeto completo.
  Future<void> searchByName(String name) async {
    _isLoading = true;
    _error     = null;
    _species   = null;
    notifyListeners();

    try {
      final results = await _searchSpecies.execute(name.trim(), limit: 1);
      _species = results.isNotEmpty ? results.first : null;
      if (_species == null) {
        _error = AppError.notFound('No se encontró la especie "$name".');
      }
    } on AppError catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Helpers de estado ────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
