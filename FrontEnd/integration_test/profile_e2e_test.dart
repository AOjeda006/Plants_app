/// @file profile_e2e_test.dart
/// @description Test de integración E2E para el flujo de perfil:
/// ver perfil → editar → guardar → cambiar contraseña → exportar datos → settings.
/// @module User
/// @layer Presentation
///
/// PREREQUISITOS:
///   1. Backend corriendo en http://localhost:3000
///   2. Usuario registrado (se crea si no existe)
///   3. Ejecutar con: flutter test integration_test/profile_e2e_test.dart
///
/// NOTA: El upload de foto de perfil se omite (requiere mock de ImagePicker).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:plants_app/main.dart' as app;

// ─── Constantes ──────────────────────────────────────────────────────────────
const _email    = 'e2e_profile_ui@example.com';
const _password = 'Test1234!';
const _name     = 'E2E Profile UI';

const _newName     = 'Nombre Actualizado E2E';
const _newBio      = 'Bio actualizada durante el test E2E de perfil.';
const _newLocation = 'Barcelona, España';
const _newPassword = 'NuevoPass456!';

const _netTimeout  = Duration(seconds: 15);
const _animTimeout = Duration(milliseconds: 600);

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E — flujo perfil', () {
    testWidgets(
      'ver perfil → editar → guardar → cambiar contraseña → exportar → settings',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));
        await _ensureLoggedIn(tester);

        // ── 1. NAVEGAR AL TAB DE PERFIL ───────────────────────────────────────
        final profileTab = find.byIcon(Icons.person_outline);
        if (profileTab.evaluate().isNotEmpty) {
          await tester.tap(profileTab.first);
          await tester.pumpAndSettle(_netTimeout);
        }

        // Verificar que MyProfilePage carga con datos del usuario
        expect(find.byType(Scaffold), findsWidgets);

        // ── 2. VER PERFIL ─────────────────────────────────────────────────────
        // Debe mostrar nombre, bio, contadores (plantas, posts, seguidores)
        // El nombre inicial puede ser _name o el actualizado de una ejecución anterior
        final profileName = find.textContaining('E2E');
        expect(profileName, findsWidgets, reason: 'El nombre del usuario debe aparecer en el perfil');

        // ── 3. NAVEGAR A EDITAR PERFIL ────────────────────────────────────────
        final editBtn = find.byIcon(Icons.edit_outlined);
        if (editBtn.evaluate().isNotEmpty) {
          await tester.tap(editBtn.first);
        } else {
          final editTextBtn = _findButton(tester, ['Editar perfil', 'Editar']);
          await tester.tap(editTextBtn);
        }
        await tester.pumpAndSettle(_animTimeout);

        // ── 4. EDITAR NOMBRE, BIO Y UBICACIÓN ────────────────────────────────
        // Limpiar y escribir nuevo nombre
        final nameField = find.widgetWithText(TextFormField, 'Nombre');
        if (nameField.evaluate().isNotEmpty) {
          await tester.tap(nameField.first);
          await tester.pump();
          // Seleccionar todo y reemplazar
          await tester.enterText(nameField.first, _newName);
          await tester.pumpAndSettle(_animTimeout);
        }

        await _fillField(tester, 'Bio', _newBio);
        await _fillField(tester, 'Ubicación', _newLocation);

        // NOTA: Upload de foto omitido (requiere ImagePicker mock)

        // ── 5. GUARDAR CAMBIOS ────────────────────────────────────────────────
        final saveBtn = _findButton(tester, ['Guardar', 'Actualizar', 'Guardar cambios']);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle(_netTimeout);

        // ── 6. VERIFICAR CAMBIOS EN EL PERFIL ────────────────────────────────
        // Después de guardar, debe volver a MyProfilePage con el nombre actualizado
        expect(
          find.textContaining(_newName),
          findsWidgets,
          reason: 'El nombre actualizado debe aparecer en el perfil',
        );

        // ── 7. NAVEGAR A SETTINGS ─────────────────────────────────────────────
        final settingsIcon = find.byIcon(Icons.settings_outlined);
        if (settingsIcon.evaluate().isEmpty) {
          // Puede ser un botón de texto
          final settingsBtn = _findButton(tester, ['Ajustes', 'Configuración', 'Settings']);
          await tester.tap(settingsBtn);
        } else {
          await tester.tap(settingsIcon.first);
        }
        await tester.pumpAndSettle(_animTimeout);

        // Verificar que SettingsPage carga correctamente
        expect(find.byType(Scaffold), findsWidgets);

        // Verificar que hay toggles de notificaciones
        expect(find.byType(Switch), findsWidgets, reason: 'Settings debe tener switches de preferencias');

        // ── 8. INTERACTUAR CON UN TOGGLE (notificaciones push) ────────────────
        final pushSwitch = find.byType(Switch).first;
        final currentValue = tester.widget<Switch>(pushSwitch).value;
        await tester.tap(pushSwitch);
        await tester.pumpAndSettle(_netTimeout);
        // El valor debe haber cambiado
        final newValue = tester.widget<Switch>(find.byType(Switch).first).value;
        expect(newValue, equals(!currentValue));

        // ── 9. NAVEGAR A GESTIÓN DE CUENTA (cambiar contraseña) ──────────────
        final accountBtn = _findButton(
          tester,
          ['Gestión de cuenta', 'Cuenta', 'Cambiar contraseña', 'Seguridad'],
        );
        await tester.tap(accountBtn);
        await tester.pumpAndSettle(_animTimeout);

        // ── 10. CAMBIAR CONTRASEÑA ────────────────────────────────────────────
        await _fillField(tester, 'Contraseña actual', _password);
        await _fillField(tester, 'Nueva contraseña', _newPassword);
        await _fillField(tester, 'Confirmar contraseña', _newPassword);

        final changePassBtn = _findButton(
          tester,
          ['Cambiar contraseña', 'Guardar', 'Actualizar contraseña'],
        );
        await tester.tap(changePassBtn);
        await tester.pumpAndSettle(_netTimeout);

        // Debe mostrar un mensaje de éxito (SnackBar o diálogo)
        // o simplemente completar sin error
        // TFG: verificar ausencia de SnackBar de error
        final errorSnackBar = find.textContaining('Error');
        expect(
          errorSnackBar.evaluate().isEmpty,
          isTrue,
          reason: 'No debe aparecer un SnackBar de error al cambiar contraseña',
        );

        // ── 11. EXPORTAR DATOS ────────────────────────────────────────────────
        final exportBtn = _findButton(
          tester,
          ['Exportar mis datos', 'Exportar datos', 'Exportar'],
        );
        if (exportBtn.evaluate().isNotEmpty) {
          await tester.tap(exportBtn);
          await tester.pumpAndSettle(_netTimeout);
          // Debe aparecer confirmación o descarga iniciada
          // TFG: el JSON se descarga via url_launcher o se muestra en diálogo
        }

        // ── 12. RESTAURAR CONTRASEÑA ORIGINAL (cleanup) ───────────────────────
        // Rellenar con la nueva contraseña como "actual" y restaurar la original
        await _fillField(tester, 'Contraseña actual', _newPassword);
        await _fillField(tester, 'Nueva contraseña', _password);
        await _fillField(tester, 'Confirmar contraseña', _password);

        final restorePassBtn = _findButton(
          tester,
          ['Cambiar contraseña', 'Guardar', 'Actualizar contraseña'],
        );
        if (restorePassBtn.evaluate().isNotEmpty) {
          await tester.tap(restorePassBtn);
          await tester.pumpAndSettle(_netTimeout);
        }
      },
    );

    testWidgets(
      'logout: cerrar sesión y redirigir a login',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));
        await _ensureLoggedIn(tester);

        // Navegar al perfil
        final profileTab = find.byIcon(Icons.person_outline);
        if (profileTab.evaluate().isNotEmpty) {
          await tester.tap(profileTab.first);
          await tester.pumpAndSettle(_netTimeout);
        }

        // Buscar botón de logout
        final logoutBtn = _findButton(tester, ['Cerrar sesión', 'Logout', 'Salir']);
        if (logoutBtn.evaluate().isNotEmpty) {
          await tester.tap(logoutBtn);
          await tester.pumpAndSettle(_animTimeout);

          // Confirmar en diálogo si aparece
          final confirmBtn = _findButton(tester, ['Confirmar', 'Sí', 'Cerrar sesión']);
          if (confirmBtn.evaluate().isNotEmpty) {
            await tester.tap(confirmBtn);
            await tester.pumpAndSettle(_netTimeout);
          }

          // Debe redirigir a LoginPage
          expect(
            find.widgetWithText(TextFormField, 'Email'),
            findsWidgets,
            reason: 'Tras logout debe aparecer la página de login',
          );
        }
      },
    );
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

Future<void> _ensureLoggedIn(WidgetTester tester) async {
  final loginField = find.widgetWithText(TextFormField, 'Email');
  if (loginField.evaluate().isEmpty) return;

  final registerLink = find.textContaining('¿No tienes cuenta?');
  if (registerLink.evaluate().isNotEmpty) {
    await tester.tap(registerLink);
    await tester.pumpAndSettle(_animTimeout);
    await _fillField(tester, 'Nombre', _name);
    await _fillField(tester, 'Email', _email);
    await _fillField(tester, 'Contraseña', _password);
    final btn = _findButton(tester, ['Registrarse', 'Crear cuenta']);
    await tester.tap(btn);
    await tester.pumpAndSettle(_netTimeout);
  }

  final emailField = find.widgetWithText(TextFormField, 'Email');
  if (emailField.evaluate().isNotEmpty) {
    await tester.enterText(emailField, _email);
    await _fillField(tester, 'Contraseña', _password);
    final btn = _findButton(tester, ['Iniciar sesión', 'Login']);
    await tester.tap(btn);
    await tester.pumpAndSettle(_netTimeout);
  }
}

Future<void> _fillField(WidgetTester tester, String label, String value) async {
  Finder field = find.widgetWithText(TextFormField, label);
  if (field.evaluate().isEmpty) field = find.widgetWithText(TextField, label);
  if (field.evaluate().isEmpty) return;
  await tester.tap(field.first);
  await tester.pumpAndSettle(const Duration(milliseconds: 200));
  await tester.enterText(field.first, value);
  await tester.pumpAndSettle(const Duration(milliseconds: 200));
}

Finder _findButton(WidgetTester tester, List<String> labels) {
  for (final label in labels) {
    for (final type in [ElevatedButton, TextButton, FilledButton, OutlinedButton]) {
      final btn = find.widgetWithText(type, label);
      if (btn.evaluate().isNotEmpty) return btn;
    }
  }
  return find.widgetWithText(ElevatedButton, labels.first);
}
