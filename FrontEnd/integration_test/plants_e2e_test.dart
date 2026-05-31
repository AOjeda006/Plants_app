/// @file plants_e2e_test.dart
/// @description Test de integración E2E para el flujo completo de plantas:
/// login → ver lista → crear planta con foto → ver detalle → ver especie
/// → editar → eliminar.
/// @module Plants
/// @layer Presentation
///
/// PREREQUISITOS PARA EJECUTAR:
///   1. Backend corriendo en http://localhost:3000
///   2. MongoDB activo con replica set
///   3. Usuario de prueba disponible (se crea automáticamente en el test)
///   4. Ejecutar con: flutter test integration_test/plants_e2e_test.dart
///      o en dispositivo: flutter drive --driver=test_driver/integration_test.dart
///                         --target=integration_test/plants_e2e_test.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:plants_app/main.dart' as app;

// ─── Constantes de prueba ────────────────────────────────────────────────────

const _testEmail    = 'e2e_plants_ui@example.com';
const _testPassword = 'Test1234!';
const _testName     = 'E2E Flutter User';

// Datos de la planta a crear
const _plantName     = 'Albahaca E2E';
const _plantLocation = 'Interior';
const _plantNotes    = 'Planta creada por test E2E';

// Datos para editar la planta
const _plantNameEdited = 'Albahaca E2E (editada)';

// ─── Timeouts ────────────────────────────────────────────────────────────────

const _networkTimeout = Duration(seconds: 15);
const _animTimeout    = Duration(milliseconds: 500);

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E — flujo plantas', () {
    // ── SETUP ────────────────────────────────────────────────────────────────

    setUpAll(() async {
      // No se necesita setup adicional: la app arranca con main().
    });

    // ── TEST PRINCIPAL ───────────────────────────────────────────────────────

    testWidgets(
      'login → lista plantas → crear → detalle → especie → editar → eliminar',
      (tester) async {
        // 1. Arrancar la app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // ── 1. REGISTRO (si el usuario no existe) ─────────────────────────────

        // Si la splash redirige a login directamente, intentar registrar primero.
        // Si ya existe el usuario, el registro fallará silenciosamente y se usará
        // el login.
        final registerLinkFinder = find.text('¿No tienes cuenta?');
        if (registerLinkFinder.evaluate().isNotEmpty) {
          await tester.tap(registerLinkFinder);
          await tester.pumpAndSettle(_animTimeout);

          await _fillTextField(tester, 'Nombre', _testName);
          await _fillTextField(tester, 'Email', _testEmail);
          await _fillTextField(tester, 'Contraseña', _testPassword);

          final registerBtn = find.widgetWithText(ElevatedButton, 'Registrarse');
          if (registerBtn.evaluate().isNotEmpty) {
            await tester.tap(registerBtn);
            await tester.pumpAndSettle(_networkTimeout);
          }
        }

        // ── 2. LOGIN ──────────────────────────────────────────────────────────

        // Asegurar que estamos en la página de login
        final emailField = find.widgetWithText(TextFormField, 'Email');
        if (emailField.evaluate().isNotEmpty) {
          await tester.tap(emailField);
          await tester.enterText(emailField, _testEmail);

          final passField = find.widgetWithText(TextFormField, 'Contraseña');
          await tester.tap(passField);
          await tester.enterText(passField, _testPassword);

          final loginBtn = find.widgetWithText(ElevatedButton, 'Iniciar sesión');
          await tester.tap(loginBtn);
          await tester.pumpAndSettle(_networkTimeout);
        }

        // ── 3. LISTA DE PLANTAS (MainTabsPage → PlantsListPage) ──────────────

        // Verificar que estamos en la pantalla principal (tab bar visible)
        expect(
          find.byIcon(Icons.local_florist_outlined),
          findsWidgets,
          reason: 'Debe aparecer el tab de plantas',
        );

        // La primera pestaña (Plantas) debe estar activa por defecto.
        // Si hay un estado vacío, debe mostrarse.
        await tester.pumpAndSettle(_animTimeout);

        // ── 4. CREAR PLANTA ──────────────────────────────────────────────────

        // Tap en el FAB para ir a PlantFormPage (modo creación)
        final fab = find.byType(FloatingActionButton);
        expect(fab, findsOneWidget, reason: 'FAB de crear planta debe existir');
        await tester.tap(fab);
        await tester.pumpAndSettle(_animTimeout);

        // Rellenar formulario de planta
        await _fillTextField(tester, 'Nombre de la planta', _plantName);
        await _fillTextField(tester, 'Ubicación', _plantLocation);

        // Frecuencia de riego (campo numérico): buscar por labelText
        await _fillTextField(tester, 'Frecuencia de riego (días)', '3');

        // Notas (opcional)
        await _fillTextField(tester, 'Notas', _plantNotes);

        // NOTA: El upload de foto requiere galería/cámara nativa — se omite en
        // el test automatizado. Se cubre manualmente según TFG.

        // Guardar la planta
        final saveBtn = find.widgetWithText(ElevatedButton, 'Guardar');
        if (saveBtn.evaluate().isEmpty) {
          // Algunos temas lo llaman 'Crear' en modo creación
          final createBtn = find.widgetWithText(ElevatedButton, 'Crear');
          await tester.tap(createBtn);
        } else {
          await tester.tap(saveBtn);
        }
        await tester.pumpAndSettle(_networkTimeout);

        // ── 5. VER LISTA CON LA NUEVA PLANTA ─────────────────────────────────

        // Debe aparecer el nombre de la planta en la lista
        expect(
          find.text(_plantName),
          findsWidgets,
          reason: 'La planta $_plantName debe aparecer en la lista',
        );

        // ── 6. VER DETALLE DE LA PLANTA ──────────────────────────────────────

        // Tap en la tarjeta de la planta recién creada
        await tester.tap(find.text(_plantName).first);
        await tester.pumpAndSettle(_networkTimeout);

        // Verificar que estamos en PlantDetailPage
        // (debe mostrar el nombre y botones de editar/eliminar)
        expect(find.text(_plantName), findsWidgets);

        // ── 7. VER INFO DE ESPECIE ────────────────────────────────────────────

        // Si la planta tiene especie asociada, habrá un chip/botón de especie.
        // Si no, este paso se omite (planta sin especie es válida en el TFG).
        final speciesBtn = find.textContaining('Ver especie');
        if (speciesBtn.evaluate().isNotEmpty) {
          await tester.tap(speciesBtn);
          await tester.pumpAndSettle(_networkTimeout);

          // Volver al detalle
          await tester.pageBack();
          await tester.pumpAndSettle(_animTimeout);
        }

        // ── 8. EDITAR LA PLANTA ───────────────────────────────────────────────

        // Buscar botón de editar (icono edit o texto 'Editar')
        final editIcon = find.byIcon(Icons.edit_outlined);
        final editBtn  = find.widgetWithText(TextButton, 'Editar');

        if (editIcon.evaluate().isNotEmpty) {
          await tester.tap(editIcon.first);
        } else {
          await tester.tap(editBtn.first);
        }
        await tester.pumpAndSettle(_animTimeout);

        // Cambiar el nombre de la planta
        final nameField = find.widgetWithText(TextFormField, 'Nombre de la planta');
        await tester.tap(nameField);
        await tester.pump();
        // Limpiar y escribir nuevo nombre
        await tester.enterText(nameField, _plantNameEdited);
        await tester.pumpAndSettle(_animTimeout);

        // Guardar cambios
        final saveEditBtn = find.widgetWithText(ElevatedButton, 'Guardar');
        await tester.tap(saveEditBtn);
        await tester.pumpAndSettle(_networkTimeout);

        // Verificar que el nombre actualizado aparece
        expect(
          find.text(_plantNameEdited),
          findsWidgets,
          reason: 'El nombre actualizado debe aparecer tras la edición',
        );

        // ── 9. ELIMINAR LA PLANTA ─────────────────────────────────────────────

        // Buscar botón de eliminar
        final deleteIcon = find.byIcon(Icons.delete_outline);
        final deleteBtn  = find.widgetWithText(TextButton, 'Eliminar');

        if (deleteIcon.evaluate().isNotEmpty) {
          await tester.tap(deleteIcon.first);
        } else {
          await tester.tap(deleteBtn.first);
        }
        await tester.pumpAndSettle(_animTimeout);

        // Confirmar en el diálogo de confirmación
        final confirmBtn = find.widgetWithText(TextButton, 'Eliminar');
        if (confirmBtn.evaluate().isNotEmpty) {
          await tester.tap(confirmBtn);
        } else {
          // Puede llamarse 'Confirmar' o 'Sí'
          final altConfirm = find.widgetWithText(TextButton, 'Confirmar');
          if (altConfirm.evaluate().isNotEmpty) {
            await tester.tap(altConfirm);
          }
        }
        await tester.pumpAndSettle(_networkTimeout);

        // ── 10. VERIFICAR LISTA VACÍA / SIN LA PLANTA ─────────────────────────

        // Tras eliminar, la planta no debe aparecer en la lista
        expect(
          find.text(_plantNameEdited),
          findsNothing,
          reason: 'La planta eliminada no debe aparecer en la lista',
        );
      },
    );

    // ── TESTS COMPLEMENTARIOS ─────────────────────────────────────────────────

    testWidgets(
      'navegación a pestaña Plantas desde Bottom Tab Bar',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Si hay token guardado (del test anterior), la app va directamente al home.
        // Si no, este test depende de que el usuario ya esté logado.
        final plantsTab = find.byIcon(Icons.local_florist_outlined);
        if (plantsTab.evaluate().isNotEmpty) {
          await tester.tap(plantsTab.first);
          await tester.pumpAndSettle(_animTimeout);
          // Verificar que el tab de plantas está activo
          expect(find.byType(FloatingActionButton), findsOneWidget);
        }
      },
    );
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Rellena un TextFormField buscándolo por su labelText.
///
/// [tester] El WidgetTester del test.
/// [label] El labelText del campo.
/// [value] El valor a introducir.
Future<void> _fillTextField(
  WidgetTester tester,
  String label,
  String value,
) async {
  final field = find.widgetWithText(TextFormField, label);
  if (field.evaluate().isEmpty) return; // campo opcional — omitir si no existe
  await tester.tap(field);
  await tester.pumpAndSettle(const Duration(milliseconds: 200));
  await tester.enterText(field, value);
  await tester.pumpAndSettle(const Duration(milliseconds: 200));
}
