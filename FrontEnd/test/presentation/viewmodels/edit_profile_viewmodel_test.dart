/// @file edit_profile_viewmodel_test.dart
/// @description Tests unitarios para EditProfileViewModel.
/// Verifica que save() incluye photo y bannerPhoto en el DTO, que
/// selectLocation guarda lat/lon del catálogo, y que setLocation limpia
/// las coordenadas al escribir texto libre.
/// @module User
/// @layer Presentation
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:plants_app/core/config/app_config.dart';
import 'package:plants_app/core/errors/app_error.dart';
import 'package:plants_app/core/network/api_client.dart';
import 'package:plants_app/data/datasources/remote/location_remote_data_source.dart';
import 'package:plants_app/domain/dtos/user/update_profile_request_dto.dart';
import 'package:plants_app/domain/entities/location.dart';
import 'package:plants_app/domain/entities/user.dart';
import 'package:plants_app/domain/interfaces/usecases/user/i_update_user_profile_use_case.dart';
import 'package:plants_app/presentation/viewmodels/profile/edit_profile_viewmodel.dart';

// ─── Mocks manuales ───────────────────────────────────────────────────────────

class _MockUpdateProfile implements IUpdateUserProfileUseCase {
  UpdateProfileRequestDto? lastDto;
  User? returnValue;
  AppError? throwError;

  @override
  Future<User> execute(UpdateProfileRequestDto dto) async {
    lastDto = dto;
    if (throwError != null) throw throwError!;
    return returnValue!;
  }
}

/// Subclase que sobreescribe search() — nunca llama a la red.
/// Recibe un ApiClient ya construido (tras inicializar AppConfig en setUpAll).
class _MockLocationDs extends LocationRemoteDataSource {
  _MockLocationDs({required super.apiClient});

  @override
  Future<List<Location>> search(String query) async => [];
}

// ─── Infraestructura compartida ───────────────────────────────────────────────

late _MockLocationDs _locationDs;

// ─── Helpers ──────────────────────────────────────────────────────────────────

final _now = DateTime.utc(2026, 3, 17);

User _makeUser({
  String  name        = 'Ana',
  String? photo,
  String? bannerPhoto,
  String? location,
  double? locationLat,
  double? locationLon,
}) =>
    User(
      id:          'user-001',
      name:        name,
      email:       'ana@example.com',
      role:        'user',
      createdAt:   _now,
      photo:       photo,
      bannerPhoto: bannerPhoto,
      location:    location,
      locationLat: locationLat,
      locationLon: locationLon,
    );

EditProfileViewModel _makeViewModel({
  _MockUpdateProfile? update,
}) =>
    EditProfileViewModel(
      updateUserProfileUseCase: update ?? _MockUpdateProfile(),
      locationDataSource:       _locationDs,
    );

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  setUpAll(() {
    AppConfig.initialize(AppConfig(
      apiBaseUrl:             'http://localhost:3000',
      socketUrl:              'http://localhost:3000',
      weatherCacheTtlSeconds: 3600,
      weatherWindowHours:     48,
      mockWeatherMode:        true,
      cloudinaryUploadPreset: 'test',
      fcmEnabled:             false,
      isProduction:           false,
      defaultLocale:          'es',
    ));
    _locationDs = _MockLocationDs(
      apiClient: ApiClient(tokenProvider: () async => null),
    );
  });

  // ── initFromUser ─────────────────────────────────────────────────────────────

  group('initFromUser()', () {
    test('rellena todos los campos del formulario desde el usuario', () {
      final vm = _makeViewModel();
      vm.initFromUser(_makeUser(
        name:        'Ana García',
        photo:       'https://cdn.example.com/photo.jpg',
        bannerPhoto: 'https://cdn.example.com/banner.jpg',
        location:    'Sevilla, España',
        locationLat: 37.3891,
        locationLon: -5.9845,
      ));

      expect(vm.name,        'Ana García');
      expect(vm.photo,       'https://cdn.example.com/photo.jpg');
      expect(vm.bannerPhoto, 'https://cdn.example.com/banner.jpg');
      expect(vm.location,    'Sevilla, España');
      expect(vm.locationLat, 37.3891);
      expect(vm.locationLon, -5.9845);
    });
  });

  // ── save() — foto de perfil persiste ─────────────────────────────────────────

  group('save() — foto de perfil y banner', () {
    test('incluye photo en el DTO si se ha seteado con setPhoto()', () async {
      final update = _MockUpdateProfile()
        ..returnValue = _makeUser(name: 'Ana', photo: 'https://cdn.example.com/photo.jpg');
      final vm = _makeViewModel(update: update);
      vm.initFromUser(_makeUser(name: 'Ana'));
      vm.setPhoto('https://cdn.example.com/photo.jpg');

      await vm.save();

      expect(update.lastDto, isNotNull);
      expect(update.lastDto!.photo, 'https://cdn.example.com/photo.jpg');
    });

    test('incluye bannerPhoto en el DTO si se ha seteado con setBannerPhoto()', () async {
      final update = _MockUpdateProfile()
        ..returnValue = _makeUser(name: 'Ana', bannerPhoto: 'https://cdn.example.com/banner.jpg');
      final vm = _makeViewModel(update: update);
      vm.initFromUser(_makeUser(name: 'Ana'));
      vm.setBannerPhoto('https://cdn.example.com/banner.jpg');

      await vm.save();

      expect(update.lastDto!.bannerPhoto, 'https://cdn.example.com/banner.jpg');
    });

    test('photo y bannerPhoto se envían juntas si ambas están seteadas', () async {
      final update = _MockUpdateProfile()
        ..returnValue = _makeUser(
          name:        'Ana',
          photo:       'https://cdn.example.com/p.jpg',
          bannerPhoto: 'https://cdn.example.com/b.jpg',
        );
      final vm = _makeViewModel(update: update);
      vm.initFromUser(_makeUser(name: 'Ana'));
      vm.setPhoto('https://cdn.example.com/p.jpg');
      vm.setBannerPhoto('https://cdn.example.com/b.jpg');

      await vm.save();

      expect(update.lastDto!.photo,       'https://cdn.example.com/p.jpg');
      expect(update.lastDto!.bannerPhoto, 'https://cdn.example.com/b.jpg');
    });

    test('isSaving vuelve a false tras guardar', () async {
      final update = _MockUpdateProfile()..returnValue = _makeUser(name: 'Ana');
      final vm = _makeViewModel(update: update);
      vm.initFromUser(_makeUser(name: 'Ana'));

      await vm.save();

      expect(vm.isSaving, isFalse);
    });

    test('save() devuelve null y guarda error si el name está vacío', () async {
      final vm = _makeViewModel();
      vm.initFromUser(_makeUser(name: ''));

      final result = await vm.save();

      expect(result, isNull);
      expect(vm.error, isNotNull);
    });

    test('save() devuelve null y establece error si el use case lanza', () async {
      final update = _MockUpdateProfile()..throwError = AppError.server();
      final vm = _makeViewModel(update: update);
      vm.initFromUser(_makeUser(name: 'Ana'));

      final result = await vm.save();

      expect(result, isNull);
      expect(vm.error, isNotNull);
      expect(vm.isSaving, isFalse);
    });
  });

  // ── selectLocation() — catálogo de capitales ──────────────────────────────────

  group('selectLocation()', () {
    test('guarda fullName, lat y lon al seleccionar del catálogo', () {
      final vm = _makeViewModel();
      vm.initFromUser(_makeUser(name: 'Ana'));
      vm.selectLocation(const Location(
        name:     'Sevilla',
        fullName: 'Sevilla, España',
        lat:      37.3891,
        lon:      -5.9845,
      ));

      expect(vm.location,    'Sevilla, España');
      expect(vm.locationLat, 37.3891);
      expect(vm.locationLon, -5.9845);
    });

    test('save() incluye locationLat y locationLon en el DTO', () async {
      final update = _MockUpdateProfile()..returnValue = _makeUser(
        name:        'Ana',
        location:    'Sevilla, España',
        locationLat: 37.3891,
        locationLon: -5.9845,
      );
      final vm = _makeViewModel(update: update);
      vm.initFromUser(_makeUser(name: 'Ana'));
      vm.selectLocation(const Location(
        name:     'Sevilla',
        fullName: 'Sevilla, España',
        lat:      37.3891,
        lon:      -5.9845,
      ));

      await vm.save();

      expect(update.lastDto!.locationLat, 37.3891);
      expect(update.lastDto!.locationLon, -5.9845);
    });
  });

  // ── setLocation() — texto libre limpia coordenadas ────────────────────────────

  group('setLocation() — texto libre', () {
    test('limpiar locationLat y locationLon al escribir texto libre', () {
      final vm = _makeViewModel();
      vm.initFromUser(_makeUser(name: 'Ana'));
      // Primero seleccionar del catálogo
      vm.selectLocation(const Location(
        name:     'Sevilla',
        fullName: 'Sevilla, España',
        lat:      37.3891,
        lon:      -5.9845,
      ));
      expect(vm.locationLat, isNotNull);

      // Al escribir texto libre, las coords deben limpiarse
      vm.setLocation('Mi ciudad libre');

      expect(vm.location,    'Mi ciudad libre');
      expect(vm.locationLat, isNull);
      expect(vm.locationLon, isNull);
    });

    test('save() con texto libre envía locationLat=null', () async {
      final update = _MockUpdateProfile()
        ..returnValue = _makeUser(name: 'Ana', location: 'Texto libre');
      final vm = _makeViewModel(update: update);
      vm.initFromUser(_makeUser(name: 'Ana'));
      vm.setLocation('Texto libre');

      await vm.save();

      expect(update.lastDto!.locationLat, isNull);
      expect(update.lastDto!.locationLon, isNull);
    });
  });
}
