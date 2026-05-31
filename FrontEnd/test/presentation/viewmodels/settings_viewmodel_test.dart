/// @file settings_viewmodel_test.dart
/// @description Tests unitarios para SettingsViewModel.
/// Verifica la carga de preferencias, el guardado con el DTO correcto y la gestión de errores.
/// @module Settings
/// @layer Presentation
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:plants_app/core/errors/app_error.dart';
import 'package:plants_app/domain/dtos/user/update_preferences_request_dto.dart';
import 'package:plants_app/domain/entities/user.dart';
import 'package:plants_app/domain/interfaces/usecases/user/i_get_my_profile_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/user/i_update_user_preferences_use_case.dart';
import 'package:plants_app/presentation/viewmodels/profile/settings_viewmodel.dart';

// ─── Mocks manuales ───────────────────────────────────────────────────────────

class _MockGetMyProfile implements IGetMyProfileUseCase {
  User? returnValue;
  AppError? throwError;

  @override
  Future<User> execute() async {
    if (throwError != null) throw throwError!;
    return returnValue!;
  }
}

class _MockUpdatePreferences implements IUpdateUserPreferencesUseCase {
  UpdatePreferencesRequestDto? lastDto;
  User? returnValue;
  AppError? throwError;

  @override
  Future<User> execute(UpdatePreferencesRequestDto dto) async {
    lastDto = dto;
    if (throwError != null) throw throwError!;
    return returnValue!;
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

final _now = DateTime.utc(2026, 3, 16);

User _makeUser({bool profilePublic = true}) =>
    User(
      id:          'user-001',
      name:        'Test',
      email:       'test@x.com',
      role:        'user',
      createdAt:   _now,
      preferences: UserPreferences(
        pushNotifications:    true,
        profilePublic:        profilePublic,
        language:             'es',
      ),
    );

User _makeUserWithoutPreferences() => User(
  id:        'u-no-prefs',
  name:      'Sin prefs',
  email:     'noprefs@x.com',
  role:      'user',
  createdAt: _now,
);

SettingsViewModel _makeViewModel({
  _MockGetMyProfile?      getProfile,
  _MockUpdatePreferences? update,
}) =>
    SettingsViewModel(
      getMyProfileUseCase:          getProfile ?? _MockGetMyProfile(),
      updateUserPreferencesUseCase: update     ?? _MockUpdatePreferences(),
    );

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  // ── loadPreferences ───────────────────────────────────────────────────────────

  group('loadPreferences()', () {
    test('debe cargar las preferencias del usuario y actualizar el estado', () async {
      final getProfile = _MockGetMyProfile()
        ..returnValue = _makeUser(profilePublic: false);
      final vm = _makeViewModel(getProfile: getProfile);

      await vm.loadPreferences();

      expect(vm.profilePublic, isFalse);
      expect(vm.isLoading,     isFalse);
      expect(vm.error,         isNull);
    });

    test('debe establecer el error si la carga falla', () async {
      final getProfile = _MockGetMyProfile()
        ..throwError = AppError.unauthorized();
      final vm = _makeViewModel(getProfile: getProfile);

      await vm.loadPreferences();

      expect(vm.error,     isNotNull);
      expect(vm.isLoading, isFalse);
    });

    test('no debe lanzar si el usuario no tiene preferencias (null)', () async {
      final getProfile = _MockGetMyProfile()
        ..returnValue = _makeUserWithoutPreferences();
      final vm = _makeViewModel(getProfile: getProfile);

      await vm.loadPreferences();

      // _applyPreferences no hace nada con null → valores por defecto del VM
      expect(vm.error, isNull);
    });
  });

  // ── savePreferences ───────────────────────────────────────────────────────────

  group('savePreferences()', () {
    test('debe enviar isPrivate=true en el JSON cuando profilePublic=false', () async {
      final update     = _MockUpdatePreferences()
        ..returnValue = _makeUser(profilePublic: false);
      final getProfile = _MockGetMyProfile()..returnValue = _makeUser();
      final vm         = _makeViewModel(getProfile: getProfile, update: update);

      await vm.loadPreferences();
      vm.setProfilePublic(false);
      await vm.savePreferences();

      // UpdatePreferencesRequestDto.toJson() convierte profilePublic=false → isPrivate=true
      final json = update.lastDto!.toJson();
      expect(json['isPrivate'], isTrue);
    });

    test('debe devolver null y guardar el error si el guardado falla', () async {
      // savePreferences ahora devuelve `User?` (no `bool`) para permitir
      // propagar el cambio al AuthViewModel.
      final update = _MockUpdatePreferences()
        ..throwError = AppError.server();
      final vm = _makeViewModel(update: update);

      final result = await vm.savePreferences();

      expect(result,      isNull);
      expect(vm.error,    isNotNull);
      expect(vm.isSaving, isFalse);
    });

    test('debe limpiar el error al llamar clearError()', () async {
      final update = _MockUpdatePreferences()..throwError = AppError.server();
      final vm     = _makeViewModel(update: update);

      await vm.savePreferences();
      expect(vm.error, isNotNull);

      vm.clearError();
      expect(vm.error, isNull);
    });
  });
}
