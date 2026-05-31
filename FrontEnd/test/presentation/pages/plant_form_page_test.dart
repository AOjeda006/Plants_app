/// @file plant_form_page_test.dart
/// @description Tests de widget para PlantFormPage.
/// Verifica que los campos "Luz necesaria" y "Frecuencia de riego" son
/// visibles en modo editar pero están ocultos en modo crear.
/// @module Plants
/// @layer Presentation
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import 'package:plants_app/core/config/app_config.dart';
import 'package:plants_app/core/errors/app_error.dart';
import 'package:plants_app/core/network/api_client.dart';
import 'package:plants_app/data/datasources/remote/location_remote_data_source.dart';
import 'package:plants_app/domain/entities/location.dart';
import 'package:plants_app/domain/entities/plant.dart';
import 'package:plants_app/domain/entities/plant_species.dart';
import 'package:plants_app/domain/entities/user.dart';
import 'package:plants_app/domain/interfaces/usecases/auth/i_login_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/auth/i_logout_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/auth/i_refresh_token_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/auth/i_register_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/auth/i_validate_token_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/plants/i_create_plant_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/plants/i_search_species_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/plants/i_update_plant_use_case.dart';
import 'package:plants_app/domain/dtos/auth/login_request_dto.dart';
import 'package:plants_app/domain/dtos/auth/register_request_dto.dart';
import 'package:plants_app/domain/dtos/plants/create_plant_request_dto.dart';
import 'package:plants_app/domain/dtos/plants/update_plant_request_dto.dart';
import 'package:plants_app/presentation/pages/plant_form_page.dart';
import 'package:plants_app/presentation/viewmodels/auth/auth_viewmodel.dart';
import 'package:plants_app/presentation/viewmodels/plants/plant_form_viewmodel.dart';

// ─── Mocks manuales ───────────────────────────────────────────────────────────

class _MockCreatePlant implements ICreatePlantUseCase {
  @override
  Future<Plant> execute(CreatePlantRequestDto dto) async =>
      throw AppError.server('mock — no implementado en test');
}

class _MockUpdatePlant implements IUpdatePlantUseCase {
  @override
  Future<Plant> execute(String plantId, UpdatePlantRequestDto dto) async =>
      throw AppError.server('mock — no implementado en test');
}

class _MockSearchSpecies implements ISearchSpeciesUseCase {
  @override
  Future<List<PlantSpecies>> execute(String query, {int limit = 20}) async => [];
}

// ─── Stub de LocationRemoteDataSource (requerido por _CityAutocomplete) ────────

/// Devuelve siempre lista vacía; nunca llama a la red.
class _StubLocationDs extends LocationRemoteDataSource {
  _StubLocationDs(ApiClient apiClient) : super(apiClient: apiClient);

  @override
  Future<List<Location>> search(String query) async => [];
}

// ─── Stubs de auth (para satisfacer el Provider requerido por PlantFormPage) ──

class _StubLogin implements ILoginUseCase {
  @override
  Future<({User user, String token})> execute(LoginRequestDto dto) async =>
      throw UnimplementedError();
}

class _StubRegister implements IRegisterUseCase {
  @override
  Future<({User user, String token})> execute(RegisterRequestDto dto) async =>
      throw UnimplementedError();
}

class _StubValidateToken implements IValidateTokenUseCase {
  @override
  Future<User> execute() async => throw UnimplementedError();
}

class _StubLogout implements ILogoutUseCase {
  @override
  Future<void> execute() async {}
}

class _StubRefreshToken implements IRefreshTokenUseCase {
  @override
  Future<bool> execute({double refreshThresholdDays = 7.0}) async => false;
}

AuthViewModel _makeAuthViewModel() => AuthViewModel(
      loginUseCase:          _StubLogin(),
      registerUseCase:       _StubRegister(),
      validateTokenUseCase:  _StubValidateToken(),
      logoutUseCase:         _StubLogout(),
      refreshTokenUseCase:   _StubRefreshToken(),
    );

// ─── Helpers ──────────────────────────────────────────────────────────────────

final _sl = GetIt.instance;

/// Planta mínima para activar el modo edición.
Plant _makePlant() => Plant(
      id:                    'plant-001',
      userId:                'user-001',
      name:                  'Monstera',
      wateringFrequencyDays: 7,
      isActive:              true,
      createdAt:             DateTime.now().toUtc(),
      updatedAt:             DateTime.now().toUtc(),
    );

/// Envuelve el widget con AuthViewModel (requerido por PlantFormPage) y MaterialApp.
Widget _wrap(Widget child) => ChangeNotifierProvider<AuthViewModel>(
      create: (_) => _makeAuthViewModel(),
      child:  MaterialApp(home: child),
    );

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  setUp(() async {
    // AppConfig debe estar inicializado antes de construir ApiClient.
    AppConfig.initialize(const AppConfig(
      apiBaseUrl:               'http://localhost:3000',
      socketUrl:                'http://localhost:3000',
      weatherCacheTtlSeconds:   300,
      weatherWindowHours:       12,
      mockWeatherMode:          true,
      cloudinaryUploadPreset:   'test_preset',
      fcmEnabled:               false,
      isProduction:             false,
      defaultLocale:            'es_ES',
    ));

    // Reiniciar el contenedor DI y registrar solo lo necesario para el formulario.
    await _sl.reset();
    _sl.registerFactory<PlantFormViewModel>(
      () => PlantFormViewModel(
        createPlantUseCase:   _MockCreatePlant(),
        updatePlantUseCase:   _MockUpdatePlant(),
        searchSpeciesUseCase: _MockSearchSpecies(),
      ),
    );
    // _CityAutocomplete llama a sl<LocationRemoteDataSource>() en build.
    _sl.registerSingleton<LocationRemoteDataSource>(
      _StubLocationDs(ApiClient(tokenProvider: () async => null)),
    );
  });

  tearDownAll(() async => _sl.reset());

  // ── Título del AppBar ─────────────────────────────────────────────────────────

  group('AppBar — título según modo', () {
    testWidgets('muestra "Nueva planta" en modo crear', (tester) async {
      await tester.pumpWidget(_wrap(const PlantFormPage()));
      await tester.pumpAndSettle();

      expect(find.text('Nueva planta'), findsOneWidget);
    });

    testWidgets('muestra "Editar planta" en modo editar', (tester) async {
      await tester.pumpWidget(_wrap(PlantFormPage(plant: _makePlant())));
      await tester.pumpAndSettle();

      expect(find.text('Editar planta'), findsOneWidget);
    });
  });

  // ── Botón de acción ───────────────────────────────────────────────────────────

  group('Botón de guardar — texto según modo', () {
    testWidgets('muestra "Crear planta" en modo crear', (tester) async {
      await tester.pumpWidget(_wrap(const PlantFormPage()));
      await tester.pumpAndSettle();

      expect(find.text('Crear planta'), findsOneWidget);
    });

    testWidgets('muestra "Guardar cambios" en modo editar', (tester) async {
      await tester.pumpWidget(_wrap(PlantFormPage(plant: _makePlant())));
      await tester.pumpAndSettle();

      expect(find.text('Guardar cambios'), findsOneWidget);
    });

    // Botones unificados en AppBar: no deben quedar ElevatedButton ni
    // OutlinedButton residuales en el body del formulario.
    testWidgets('no muestra botones inferiores duplicados (modo crear)', (tester) async {
      await tester.pumpWidget(_wrap(const PlantFormPage()));
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('no muestra botones inferiores duplicados (modo editar)', (tester) async {
      await tester.pumpWidget(_wrap(PlantFormPage(plant: _makePlant())));
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });
  });

  // ── Campos condicionales (luz y riego) ────────────────────────────────────────

  group('Campos luz y riego — visibilidad según modo', () {
    testWidgets('en modo crear NO muestra el campo "Luz necesaria"', (tester) async {
      await tester.pumpWidget(_wrap(const PlantFormPage()));
      await tester.pumpAndSettle();

      // El campo está condicionado por widget.isEditing; en crear no está en el árbol.
      expect(find.text('Luz necesaria *'), findsNothing);
    });

    testWidgets('en modo crear NO muestra el campo "Frecuencia de riego"', (tester) async {
      await tester.pumpWidget(_wrap(const PlantFormPage()));
      await tester.pumpAndSettle();

      expect(find.text('Frecuencia de riego (días) *'), findsNothing);
    });

    testWidgets('en modo editar SÍ muestra el campo "Luz necesaria"', (tester) async {
      await tester.pumpWidget(_wrap(PlantFormPage(plant: _makePlant())));
      await tester.pumpAndSettle();

      expect(find.text('Luz necesaria *'), findsOneWidget);
    });

    testWidgets('en modo editar SÍ muestra el campo "Frecuencia de riego"', (tester) async {
      await tester.pumpWidget(_wrap(PlantFormPage(plant: _makePlant())));
      await tester.pumpAndSettle();

      expect(find.text('Frecuencia de riego (días) *'), findsOneWidget);
    });
  });

  // ── Campos siempre visibles ───────────────────────────────────────────────────

  group('Campos siempre visibles', () {
    testWidgets('en modo crear muestra el campo "Nombre de la planta"', (tester) async {
      await tester.pumpWidget(_wrap(const PlantFormPage()));
      await tester.pumpAndSettle();

      expect(find.text('Nombre de la planta *'), findsOneWidget);
    });

    testWidgets('en modo editar muestra el campo "Nombre de la planta"', (tester) async {
      await tester.pumpWidget(_wrap(PlantFormPage(plant: _makePlant())));
      await tester.pumpAndSettle();

      expect(find.text('Nombre de la planta *'), findsOneWidget);
    });
  });
}
