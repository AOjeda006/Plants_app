/// @file settings_viewmodel.dart
/// @description ViewModel de la pantalla de ajustes.
/// Gestiona las preferencias del usuario: notificaciones, unidades, privacidad.
/// Depende SOLO de interfaces de use cases.
/// @module Settings
/// @layer Presentation
library;

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../domain/dtos/user/update_preferences_request_dto.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/interfaces/usecases/user/i_get_my_profile_use_case.dart';
import '../../../domain/interfaces/usecases/user/i_update_user_preferences_use_case.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SETTINGS VIEWMODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// ViewModel de la pantalla de ajustes del usuario.
///
/// Estado gestionado:
///  - Preferencias actuales del usuario (cargadas al inicio).
///  - [isLoading] / [isSaving] / [error].
///
/// [injectable] registrar en container.dart como factory.
/// [dependencies] IGetMyProfileUseCase, IUpdateUserPreferencesUseCase.
class SettingsViewModel extends ChangeNotifier {
  final IGetMyProfileUseCase          _getMyProfile;
  final IUpdateUserPreferencesUseCase _updatePreferences;

  SettingsViewModel({
    required IGetMyProfileUseCase          getMyProfileUseCase,
    required IUpdateUserPreferencesUseCase updateUserPreferencesUseCase,
  })  : _getMyProfile      = getMyProfileUseCase,
        _updatePreferences = updateUserPreferencesUseCase;

  // ─── Estado ───────────────────────────────────────────────────────────────────

  bool      _isLoading            = false;
  bool      _isSaving             = false;
  AppError? _error;

  // Preferencias locales (reflejan el estado actual, se modifican con toggles).
  bool   _pushNotifications    = true;
  bool   _profilePublic        = true;
  String _language             = 'es';

  bool      get isLoading            => _isLoading;
  bool      get isSaving             => _isSaving;
  AppError? get error                => _error;
  bool      get pushNotifications    => _pushNotifications;
  bool      get profilePublic        => _profilePublic;
  String    get language             => _language;

  // ─── Cargar preferencias ──────────────────────────────────────────────────────

  /// Carga el perfil del usuario y extrae sus preferencias actuales.
  Future<void> loadPreferences() async {
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      final user = await _getMyProfile.execute();
      _applyPreferences(user.preferences);
    } on AppError catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyPreferences(UserPreferences? prefs) {
    if (prefs == null) return;
    _pushNotifications    = prefs.pushNotifications;
    _profilePublic        = prefs.profilePublic;
    _language             = prefs.language;
  }

  // ─── Toggles ──────────────────────────────────────────────────────────────────

  void setPushNotifications(bool v)    { _pushNotifications = v;    notifyListeners(); }
  void setProfilePublic(bool v)        { _profilePublic = v;        notifyListeners(); }
  void setLanguage(String v)           { _language = v;             notifyListeners(); }

  // ─── Guardar ──────────────────────────────────────────────────────────────────

  /// Persiste las preferencias actuales en el backend y devuelve el [User]
  /// actualizado para que el caller pueda propagar el cambio al
  /// AuthViewModel global. Devuelve `null` si la llamada falló — el error
  /// queda registrado en [error].
  Future<User?> savePreferences() async {
    _isSaving = true;
    _error    = null;
    notifyListeners();

    try {
      // `language` no se envía al backend: el cambio de idioma se mantiene
      // en el VM local para el ciclo de vida de la app; la persistencia
      // entre sesiones queda fuera del alcance del proyecto.
      final dto = UpdatePreferencesRequestDto(
        pushNotifications: _pushNotifications,
        profilePublic:     _profilePublic,
      );
      final updated = await _updatePreferences.execute(dto);
      return updated;
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
