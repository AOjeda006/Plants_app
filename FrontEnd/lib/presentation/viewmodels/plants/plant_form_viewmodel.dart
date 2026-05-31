/// @file plant_form_viewmodel.dart
/// @description ViewModel del formulario de creación y edición de planta.
/// Gestiona campos del formulario, búsqueda de especies y envío al repositorio.
/// Depende SOLO de interfaces de use cases — nunca de implementaciones concretas.
/// @module Plants
/// @layer Presentation
library;

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../domain/dtos/plants/create_plant_request_dto.dart';
import '../../../domain/dtos/plants/update_plant_request_dto.dart';
import '../../../domain/entities/location.dart';
import '../../../domain/entities/plant.dart';
import '../../../domain/entities/plant_species.dart';
import '../../../domain/interfaces/usecases/plants/i_create_plant_use_case.dart';
import '../../../domain/interfaces/usecases/plants/i_search_species_use_case.dart';
import '../../../domain/interfaces/usecases/plants/i_update_plant_use_case.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PLANT FORM VIEWMODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// ViewModel del formulario de creación/edición de planta. Extiende [ChangeNotifier] para Provider.
///
/// Soporta dos modos de uso:
///  - Crear planta: llamar [initForCreate] y después [submit].
///  - Editar planta: llamar [initForEdit] con la entidad existente y después [submit].
///
/// Estado gestionado:
///  - Campos del formulario: [name], [speciesId], [photo], [location], [notes], [wateringFrequencyDays].
///  - [isEditing]       — true si se está editando una planta existente.
///  - [isSubmitting]    — true mientras se procesa el envío.
///  - [error]           — último error de red/servidor (null si no hay error).
///  - [result]          — planta creada/actualizada tras un submit exitoso.
///  - [speciesResults]  — resultados de búsqueda de especies.
///  - [isSearching]     — true mientras se busca especie.
///
/// [injectable] registrar en container.dart como factory.
/// [dependencies] ICreatePlantUseCase, IUpdatePlantUseCase, ISearchSpeciesUseCase.
class PlantFormViewModel extends ChangeNotifier {
  final ICreatePlantUseCase   _createPlant;
  final IUpdatePlantUseCase   _updatePlant;
  final ISearchSpeciesUseCase _searchSpecies;

  PlantFormViewModel({
    required ICreatePlantUseCase   createPlantUseCase,
    required IUpdatePlantUseCase   updatePlantUseCase,
    required ISearchSpeciesUseCase searchSpeciesUseCase,
  })  : _createPlant  = createPlantUseCase,
        _updatePlant  = updatePlantUseCase,
        _searchSpecies = searchSpeciesUseCase;

  // ─── Estado ───────────────────────────────────────────────────────────────────

  bool               _isEditing            = false;
  String?            _editingPlantId;
  bool               _isSubmitting         = false;
  AppError?          _error;
  Plant?             _result;

  // Campos del formulario
  String             _name                 = '';
  String?            _speciesId;
  PlantSpecies?      _selectedSpecies;
  String?            _photo;
  String             _location             = 'Interior';
  String             _lightNeed            = 'Medium';
  String?            _notes;
  int                _wateringFrequencyDays = 7;
  String             _plantLocation        = '';
  double?            _plantLocationLat;
  double?            _plantLocationLon;

  bool               get isEditing             => _isEditing;
  bool               get isSubmitting           => _isSubmitting;
  AppError?          get error                  => _error;
  Plant?             get result                 => _result;
  String             get name                   => _name;
  String?            get speciesId              => _speciesId;
  PlantSpecies?      get selectedSpecies        => _selectedSpecies;
  String?            get photo                  => _photo;
  String             get location               => _location;
  String             get lightNeed              => _lightNeed;
  String?            get notes                  => _notes;
  int                get wateringFrequencyDays  => _wateringFrequencyDays;
  String             get plantLocation          => _plantLocation;
  double?            get plantLocationLat       => _plantLocationLat;
  double?            get plantLocationLon       => _plantLocationLon;

  // ─── Inicialización ───────────────────────────────────────────────────────────

  /// Prepara el ViewModel para crear una planta nueva (reinicia todos los campos).
  /// Si se proporciona [userLocation], [userLocationLat] y [userLocationLon],
  /// se pre-asignan como ciudad de la planta.
  void initForCreate({
    String? userLocation,
    double? userLocationLat,
    double? userLocationLon,
  }) {
    _isEditing      = false;
    _editingPlantId = null;
    _resetFields();
    if (userLocation != null && userLocation.isNotEmpty) {
      _plantLocation    = userLocation;
      _plantLocationLat = userLocationLat;
      _plantLocationLon = userLocationLon;
    }
  }

  /// Prepara el ViewModel para editar [plant] existente (precarga los campos).
  void initForEdit(Plant plant) {
    _isEditing             = true;
    _editingPlantId        = plant.id;
    _name                  = plant.name;
    _speciesId             = plant.speciesId;
    _photo                 = plant.photo;
    _location              = plant.location ?? 'Interior';
    _plantLocation         = plant.plantLocation ?? '';
    _plantLocationLat      = plant.plantLocationLat;
    _plantLocationLon      = plant.plantLocationLon;
    _notes                 = plant.notes;
    _wateringFrequencyDays = plant.wateringFrequencyDays;
    notifyListeners();
  }

  // ─── Setters de campos ────────────────────────────────────────────────────────

  /// Actualiza el nombre de la planta.
  void setName(String value) { _name = value; }

  /// Actualiza la URL de la foto (Cloudinary).
  void setPhoto(String? value) {
    _photo = value;
    notifyListeners();
  }

  /// Actualiza la ubicación de la planta ('Interior' o 'Exterior').
  void setLocation(String value) {
    _location = value;
    notifyListeners();
  }

  /// Selecciona una ciudad del catálogo y guarda nombre + coordenadas.
  void selectPlantLocation(Location loc) {
    _plantLocation    = loc.fullName;
    _plantLocationLat = loc.lat;
    _plantLocationLon = loc.lon;
    notifyListeners();
  }

  /// Escribe manualmente el nombre de ciudad (limpia las coordenadas).
  void setPlantLocationText(String value) {
    _plantLocation    = value;
    _plantLocationLat = null;
    _plantLocationLon = null;
    notifyListeners();
  }

  /// Actualiza la necesidad de luz ('Low', 'Medium' o 'High').
  void setLightNeed(String value) {
    _lightNeed = value;
    notifyListeners();
  }

  /// Actualiza las notas personalizadas.
  void setNotes(String? value) { _notes = value; }

  /// Actualiza la frecuencia de riego en días.
  void setWateringFrequencyDays(int value) {
    _wateringFrequencyDays = value;
    notifyListeners();
  }

  // ─── Selección de especie ─────────────────────────────────────────────────────

  /// Selecciona una especie del catálogo y aplica sus valores de cuidado por defecto.
  void selectSpecies(PlantSpecies species) {
    _speciesId             = species.id;
    _selectedSpecies       = species;
    // Auto-rellenar frecuencia de riego y necesidad de luz desde la especie.
    _wateringFrequencyDays = species.careRequirements.wateringDays;
    _lightNeed             = species.careRequirements.lightNeed;
    notifyListeners();
  }

  /// Elimina la especie seleccionada del formulario.
  void clearSpecies() {
    _speciesId       = null;
    _selectedSpecies = null;
    notifyListeners();
  }

  // ─── Búsqueda de especies ─────────────────────────────────────────────────────

  /// Devuelve las opciones de especie para [query] (compatible con Autocomplete).
  /// Query vacío = todas las especies públicas del catálogo.
  ///
  /// [returns] Lista de especies coincidentes (vacía si hay error de red).
  Future<List<PlantSpecies>> fetchSpeciesOptions(String query) async {
    try {
      return await _searchSpecies.execute(query.trim());
    } on AppError {
      return []; // No bloquear UI por errores de búsqueda.
    }
  }

  // ─── Envío del formulario ─────────────────────────────────────────────────────

  /// Crea o actualiza la planta según [isEditing]. Devuelve true si fue exitoso.
  ///
  /// [returns] true si la operación fue exitosa; false si hubo error.
  Future<bool> submit() async {
    _isSubmitting = true;
    _error        = null;
    notifyListeners();

    try {
      if (_isEditing && _editingPlantId != null) {
        final dto = UpdatePlantRequestDto(
          name:                  _name.isNotEmpty ? _name : null,
          photo:                 _photo,
          location:              _location,
          plantLocation:         _plantLocation.isNotEmpty ? _plantLocation : null,
          plantLocationLat:      _plantLocationLat,
          plantLocationLon:      _plantLocationLon,
          notes:                 _notes,
          wateringFrequencyDays: _wateringFrequencyDays,
        );
        _result = await _updatePlant.execute(_editingPlantId!, dto);
      } else {
        final dto = CreatePlantRequestDto(
          name:             _name,
          location:         _location,
          plantLocation:    _plantLocation,
          plantLocationLat: _plantLocationLat,
          plantLocationLon: _plantLocationLon,
          wateringFrequency: _wateringFrequencyDays,
          lightNeed:        _lightNeed,
          speciesId:        _speciesId,
          photo:            _photo,
          notes:            _notes,
        );
        _result = await _createPlant.execute(dto);
      }
      return true;
    } on AppError catch (e) {
      _error = e;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ─── Helpers de estado ────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _resetFields() {
    _name                  = '';
    _speciesId             = null;
    _selectedSpecies       = null;
    _photo                 = null;
    _location              = 'Interior';
    _lightNeed             = 'Medium';
    _notes                 = null;
    _wateringFrequencyDays = 7;
    _plantLocation         = '';
    _plantLocationLat      = null;
    _plantLocationLon      = null;
    _error                 = null;
    _result                = null;
    notifyListeners();
  }
}
