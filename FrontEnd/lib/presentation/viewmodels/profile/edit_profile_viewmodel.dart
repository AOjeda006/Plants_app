/// @file edit_profile_viewmodel.dart
/// @description ViewModel de la pantalla de edición de perfil.
/// Gestiona el formulario de edición y la llamada al use case de actualización.
/// Depende SOLO de interfaces de use cases.
/// @module User
/// @layer Presentation
library;

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../data/datasources/remote/location_remote_data_source.dart';
import '../../../domain/dtos/user/update_profile_request_dto.dart';
import '../../../domain/entities/location.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/interfaces/usecases/user/i_update_user_profile_use_case.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// EDIT PROFILE VIEWMODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// ViewModel de la pantalla de edición de perfil.
///
/// Estado gestionado:
///  - [isSaving] — true mientras se guarda el perfil.
///  - [error]    — último error ocurrido.
///  - Campos del formulario: name, bio, location, locationLat, locationLon.
///
/// [injectable] registrar en container.dart como factory.
/// [dependencies] IUpdateUserProfileUseCase, LocationRemoteDataSource.
class EditProfileViewModel extends ChangeNotifier {
  final IUpdateUserProfileUseCase  _updateProfile;
  final LocationRemoteDataSource   _locationDs;

  EditProfileViewModel({
    required IUpdateUserProfileUseCase updateUserProfileUseCase,
    required LocationRemoteDataSource  locationDataSource,
  })  : _updateProfile = updateUserProfileUseCase,
        _locationDs    = locationDataSource;

  // ─── Estado del formulario ────────────────────────────────────────────────────

  String    _name             = '';
  String    _bio              = '';
  String    _location         = '';
  double?   _locationLat;
  double?   _locationLon;
  String?   _photo;
  String?   _bannerPhoto;
  bool      _isSaving         = false;
  bool      _isUploadingPhoto  = false;
  bool      _isUploadingBanner = false;
  AppError? _error;

  String    get name              => _name;
  String    get bio               => _bio;
  String    get location          => _location;
  double?   get locationLat       => _locationLat;
  double?   get locationLon       => _locationLon;
  String?   get photo             => _photo;
  String?   get bannerPhoto       => _bannerPhoto;
  bool      get isSaving          => _isSaving;
  /// true mientras se sube la foto de perfil al servidor.
  bool      get isUploadingPhoto  => _isUploadingPhoto;
  /// true mientras se sube el banner al servidor.
  bool      get isUploadingBanner => _isUploadingBanner;
  AppError? get error             => _error;

  // ─── Inicializar con datos existentes ─────────────────────────────────────────

  /// Rellena el formulario con los datos actuales del usuario.
  void initFromUser(User user) {
    _name        = user.name;
    _bio         = user.bio         ?? '';
    _location    = user.location    ?? '';
    _locationLat = user.locationLat;
    _locationLon = user.locationLon;
    _photo       = user.photo;
    _bannerPhoto = user.bannerPhoto;
    notifyListeners();
  }

  // ─── Setters del formulario ───────────────────────────────────────────────────

  void setName(String v)     { _name = v;     notifyListeners(); }
  void setBio(String v)      { _bio = v;      notifyListeners(); }

  /// Actualiza la ubicación libre (sin coordenadas — limpia las coords previas).
  void setLocation(String v) {
    _location    = v;
    _locationLat = null;
    _locationLon = null;
    notifyListeners();
  }

  /// Selecciona una ubicación del catálogo (con nombre completo y coordenadas).
  void selectLocation(Location loc) {
    _location    = loc.fullName;
    _locationLat = loc.lat;
    _locationLon = loc.lon;
    notifyListeners();
  }

  /// Busca capitales de provincia que coincidan con [query].
  /// Devuelve la lista de resultados para el Autocomplete.
  Future<List<Location>> searchLocations(String query) =>
      _locationDs.search(query);

  /// Actualiza la URL de foto de perfil (llamado tras subir la imagen al backend).
  void setPhoto(String url)        { _photo = url;        notifyListeners(); }

  /// Actualiza la URL de banner (llamado tras subir la imagen al backend).
  void setBannerPhoto(String url)  { _bannerPhoto = url;  notifyListeners(); }

  /// Marca el inicio/fin de la subida de foto de perfil.
  void setUploadingPhoto(bool v)   { _isUploadingPhoto  = v; notifyListeners(); }

  /// Marca el inicio/fin de la subida del banner.
  void setUploadingBanner(bool v)  { _isUploadingBanner = v; notifyListeners(); }

  // ─── Guardar ──────────────────────────────────────────────────────────────────

  /// Guarda los cambios del perfil. Devuelve el [User] actualizado o null si hay error.
  Future<User?> save() async {
    if (_name.trim().isEmpty) {
      _error = AppError.validation('El nombre no puede estar vacío.');
      notifyListeners();
      return null;
    }

    _isSaving = true;
    _error    = null;
    notifyListeners();

    try {
      final dto = UpdateProfileRequestDto(
        name:        _name.trim(),
        bio:         _bio.trim().isEmpty      ? null : _bio.trim(),
        location:    _location.trim().isEmpty ? null : _location.trim(),
        locationLat: _locationLat,
        locationLon: _locationLon,
        photo:       _photo,
        bannerPhoto: _bannerPhoto,
      );
      return await _updateProfile.execute(dto);
    } on AppError catch (e) {
      _error = e;
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
