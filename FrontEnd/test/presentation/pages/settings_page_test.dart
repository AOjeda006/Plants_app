/// @file settings_page_test.dart
/// @description Widget tests de SettingsPage. Verifica que el toggle de
/// notificaciones push:
///  - Es visible en plataformas móviles (Android/iOS).
///  - Es invisible en web/desktop — el header de la sección
///    Notificaciones también se oculta si la sección queda vacía.
///  - Al pulsar dispara setPushNotifications + savePreferences.
/// @module Settings
/// @layer Presentation
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import 'package:plants_app/domain/entities/user.dart';
import 'package:plants_app/domain/dtos/user/update_preferences_request_dto.dart';
import 'package:plants_app/domain/interfaces/usecases/user/i_get_my_profile_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/user/i_update_user_preferences_use_case.dart';
import 'package:plants_app/presentation/pages/settings_page.dart';
import 'package:plants_app/presentation/viewmodels/auth/auth_viewmodel.dart';
import 'package:plants_app/presentation/viewmodels/profile/settings_viewmodel.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class _MockGetMyProfile implements IGetMyProfileUseCase {
  User? returnUser;
  @override
  Future<User> execute() async => returnUser!;
}

class _MockUpdatePrefs implements IUpdateUserPreferencesUseCase {
  UpdatePreferencesRequestDto? lastCall;
  User? returnUser;
  @override
  Future<User> execute(UpdatePreferencesRequestDto dto) async {
    lastCall = dto;
    return returnUser!;
  }
}

/// AuthViewModel stub mínimo para que el `context.watch<AuthViewModel>()`
/// en SettingsPage no explote. No exponemos admin.
class _StubAuthVm extends ChangeNotifier implements AuthViewModel {
  @override
  User? get currentUser => null;

  // El toggle propaga el User actualizado a través de
  // `updateCurrentUser`. Implementación mínima (no-op).
  @override
  void updateCurrentUser(User user) {}

  // Resto de la interfaz no se usa en este test.
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

User _makeUser({bool pushNotifications = true}) => User(
      id:          'user-001',
      name:        'Test',
      email:       't@t.com',
      role:        'user',
      createdAt:   DateTime.utc(2026, 1, 1),
      preferences: UserPreferences(
        pushNotifications: pushNotifications,
        profilePublic:     true,
        language:          'es',
      ),
    );

final _sl = GetIt.instance;

void _registerVmFactory(_MockGetMyProfile getProfile, _MockUpdatePrefs updatePrefs) {
  if (_sl.isRegistered<SettingsViewModel>()) {
    _sl.unregister<SettingsViewModel>();
  }
  _sl.registerFactory<SettingsViewModel>(() => SettingsViewModel(
        getMyProfileUseCase:           getProfile,
        updateUserPreferencesUseCase:  updatePrefs,
      ));
}

Widget _wrap() {
  return MaterialApp(
    home: ChangeNotifierProvider<AuthViewModel>(
      create: (_) => _StubAuthVm(),
      child: const SettingsPage(),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  tearDown(() {
    debugMobilePushPlatformOverride = null;
    if (_sl.isRegistered<SettingsViewModel>()) {
      _sl.unregister<SettingsViewModel>();
    }
  });

  group('SettingsPage — toggle push solo en móvil', () {
    testWidgets('en móvil → toggle visible con subtítulo aclaratorio', (tester) async {
      debugMobilePushPlatformOverride = true;
      final getProfile  = _MockGetMyProfile()..returnUser = _makeUser();
      final updatePrefs = _MockUpdatePrefs()..returnUser  = _makeUser();

      // SettingsPage llama loadPreferences en el create del Provider, pero
      // como instanciamos el VM fuera, llamamos loadPreferences manualmente
      // a través del Provider ya inyectado. La opción más simple: usar el
      // factory de SettingsPage que ya lo llama. Aquí instanciamos directo.
      _registerVmFactory(getProfile, updatePrefs);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Notificaciones push'), findsOneWidget);
      expect(
        find.text('Recibe avisos en la barra del sistema cuando la app está cerrada'),
        findsOneWidget,
      );
    });

    testWidgets('en web/desktop → toggle ausente Y header sección oculto', (tester) async {
      debugMobilePushPlatformOverride = false;
      final getProfile  = _MockGetMyProfile()..returnUser = _makeUser();
      final updatePrefs = _MockUpdatePrefs()..returnUser  = _makeUser();

      _registerVmFactory(getProfile, updatePrefs);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Notificaciones push'), findsNothing);
      // El header solo aparecía si había contenido en la sección; al
      // omitirse el toggle, ni siquiera se renderiza el título.
      expect(find.text('NOTIFICACIONES'), findsNothing);
    });

    testWidgets('tap en toggle dispara setPushNotifications + savePreferences', (tester) async {
      debugMobilePushPlatformOverride = true;
      final getProfile  = _MockGetMyProfile()..returnUser = _makeUser(pushNotifications: true);
      final updatePrefs = _MockUpdatePrefs()..returnUser  = _makeUser(pushNotifications: false);

      _registerVmFactory(getProfile, updatePrefs);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Pulsar el SwitchListTile del toggle push (hay otro para
      // "Perfil público" debajo). Localizar por su título visible.
      await tester.tap(find.widgetWithText(SwitchListTile, 'Notificaciones push'));
      await tester.pumpAndSettle();

      // Verificar que update se llamó con pushNotifications=false.
      expect(updatePrefs.lastCall, isNotNull);
      expect(updatePrefs.lastCall!.pushNotifications, isFalse);
    });
  });
}
