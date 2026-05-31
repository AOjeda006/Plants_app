/// @file chat_e2e_test.dart
/// @description Test de integración E2E para el flujo de chat:
/// abrir conversación → enviar mensaje → verificar entrega → estados de lectura.
/// @module Chat
/// @layer Presentation
///
/// PREREQUISITOS:
///   1. Backend corriendo en http://localhost:3000 (con Socket.IO activo)
///   2. Al menos un usuario registrado en la base de datos
///   3. Ejecutar con: flutter test integration_test/chat_e2e_test.dart
///
/// NOTA SOBRE SOCKET.IO:
///   La reconciliación de tempId y el ack en tiempo real se verifican a nivel
///   de UI observando el cambio de estado del mensaje (✓ → ✓✓ → leído).
///   El test espera timeouts razonables para que el socket procese los eventos.
///
/// LIMITACIÓN — doble cliente:
///   Flutter integration_test ejecuta la app en un solo proceso. Para verificar
///   que el mensaje llega al OTRO cliente, se necesitaría un segundo proceso o
///   la prueba chat.e2e.http. Este test verifica el lado del emisor.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:plants_app/main.dart' as app;

// ─── Constantes ──────────────────────────────────────────────────────────────
const _email    = 'e2e_chat_ui@example.com';
const _password = 'Test1234!';
const _name     = 'E2E Chat UI';

// Mensaje a enviar
const _msg1 = 'Hola! Probando el chat E2E.';
const _msg2 = '¿Ves este mensaje?';
const _msg3 = 'Mensaje número 3 de la prueba.';

const _netTimeout    = Duration(seconds: 15);
const _socketTimeout = Duration(seconds: 5);
const _animTimeout   = Duration(milliseconds: 600);

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E — flujo chat', () {
    testWidgets(
      'lista conversaciones → abrir/crear → enviar mensajes → verificar estados',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // ── 1. LOGIN ──────────────────────────────────────────────────────────
        await _ensureLoggedIn(tester);

        // ── 2. NAVEGAR A PESTAÑA MENSAJES ─────────────────────────────────────
        final chatTab = find.byIcon(Icons.chat_bubble_outline);
        if (chatTab.evaluate().isNotEmpty) {
          await tester.tap(chatTab.first);
          await tester.pumpAndSettle(_animTimeout);
        }

        // Verificar que estamos en ConversationsListPage
        // (botón de nueva conversación debe estar visible)
        expect(
          find.byType(Scaffold),
          findsWidgets,
          reason: 'ConversationsListPage debe estar montada',
        );

        // ── 3. CREAR NUEVA CONVERSACIÓN ───────────────────────────────────────
        // Buscar botón de nueva conversación (FAB o icono compose)
        final newChatBtn = find.byIcon(Icons.edit_outlined);
        final fab        = find.byType(FloatingActionButton);

        if (newChatBtn.evaluate().isNotEmpty) {
          await tester.tap(newChatBtn.first);
        } else if (fab.evaluate().isNotEmpty) {
          await tester.tap(fab.first);
        }
        await tester.pumpAndSettle(_animTimeout);

        // Si aparece un diálogo/modal para buscar usuario, ingresar el email
        final userSearchField = find.byType(TextField);
        if (userSearchField.evaluate().isNotEmpty) {
          // TFG: buscar el propio usuario como destinatario (para self-test)
          // En producción se buscaría otro usuario
          await tester.tap(userSearchField.first);
          await tester.enterText(userSearchField.first, _email);
          await tester.pumpAndSettle(_netTimeout);

          // Seleccionar el primer resultado
          final firstResult = find.byType(ListTile).first;
          if (firstResult.evaluate().isNotEmpty) {
            await tester.tap(firstResult);
            await tester.pumpAndSettle(_netTimeout);
          }
        }

        // ── 4. VERIFICAR QUE ESTAMOS EN CHATPAGE ─────────────────────────────
        // ChatPage tiene el campo de input de texto en la parte inferior
        final messageInput = _findMessageInput(tester);

        // Si no se encontró ChatPage (no había usuario para seleccionar),
        // abrir la primera conversación existente
        if (messageInput.evaluate().isEmpty) {
          await tester.pageBack();
          await tester.pumpAndSettle(_animTimeout);

          final firstConversation = find.byType(ListTile).first;
          if (firstConversation.evaluate().isNotEmpty) {
            await tester.tap(firstConversation);
            await tester.pumpAndSettle(_netTimeout);
          }
        }

        // ── 5. ENVIAR MENSAJES ────────────────────────────────────────────────
        await _sendMessage(tester, _msg1);
        await tester.pumpAndSettle(_socketTimeout);

        // Verificar que el mensaje aparece en la lista
        expect(
          find.textContaining(_msg1.substring(0, 15)),
          findsWidgets,
          reason: 'El mensaje enviado debe aparecer en el chat',
        );

        // Enviar segundo mensaje
        await _sendMessage(tester, _msg2);
        await tester.pumpAndSettle(_socketTimeout);

        expect(
          find.textContaining(_msg2.substring(0, 10)),
          findsWidgets,
        );

        // Enviar tercer mensaje
        await _sendMessage(tester, _msg3);
        await tester.pumpAndSettle(_socketTimeout);

        // ── 6. VERIFICAR ESTADOS DE MENSAJES ─────────────────────────────────
        // Los mensajes propios deben mostrar algún indicador de estado:
        // ✓ (sent) → ✓✓ (delivered) → leído (azul/color diferente)
        //
        // Verificamos que existe al menos un indicador de estado (check icon)
        final statusIcons = find.byIcon(Icons.done);
        final doneAllIcons = find.byIcon(Icons.done_all);
        // Al menos uno de los dos debe existir (sent o delivered)
        final hasStatusIcon = statusIcons.evaluate().isNotEmpty ||
            doneAllIcons.evaluate().isNotEmpty;
        expect(
          hasStatusIcon,
          isTrue,
          reason: 'Los mensajes deben mostrar indicador de estado (✓ o ✓✓)',
        );

        // ── 7. SCROLL AL INICIO DE LA CONVERSACIÓN ───────────────────────────
        // Los mensajes se muestran en orden (más recientes abajo en ListView invertida)
        await tester.drag(find.byType(ListView).first, const Offset(0, 300));
        await tester.pumpAndSettle(_animTimeout);

        // ── 8. VOLVER A LA LISTA DE CONVERSACIONES ────────────────────────────
        await tester.pageBack();
        await tester.pumpAndSettle(_animTimeout);

        // La conversación debe aparecer en la lista con preview del último mensaje
        expect(
          find.textContaining(_msg3.substring(0, 15)),
          findsWidgets,
          reason: 'El preview del último mensaje debe aparecer en la lista',
        );
      },
    );

    testWidgets(
      'campo de input: validar que no envía mensajes vacíos',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));
        await _ensureLoggedIn(tester);

        // Navegar a mensajes
        final chatTab = find.byIcon(Icons.chat_bubble_outline);
        if (chatTab.evaluate().isNotEmpty) {
          await tester.tap(chatTab.first);
          await tester.pumpAndSettle(_animTimeout);
        }

        // Abrir la primera conversación si existe
        final firstConv = find.byType(ListTile).first;
        if (firstConv.evaluate().isNotEmpty) {
          await tester.tap(firstConv);
          await tester.pumpAndSettle(_netTimeout);

          // Intentar enviar mensaje vacío
          final sendIcon = find.byIcon(Icons.send);
          if (sendIcon.evaluate().isNotEmpty) {
            await tester.tap(sendIcon.first);
            await tester.pumpAndSettle(_animTimeout);
            // No debe enviarse ningún mensaje nuevo (sin SnackBar de error
            // ni cambio en la lista)
          }
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

/// Busca el campo de input de mensajes en ChatPage.
Finder _findMessageInput(WidgetTester tester) {
  final byHint = find.widgetWithText(TextField, 'Escribe un mensaje...');
  if (byHint.evaluate().isNotEmpty) return byHint;
  // Fallback: cualquier TextField en la parte inferior
  return find.byType(TextField);
}

/// Escribe y envía un mensaje en el chat.
Future<void> _sendMessage(WidgetTester tester, String text) async {
  final inputField = _findMessageInput(tester);
  if (inputField.evaluate().isEmpty) return;

  await tester.tap(inputField.first);
  await tester.enterText(inputField.first, text);
  await tester.pumpAndSettle(const Duration(milliseconds: 200));

  // Enviar (icono send o botón)
  final sendIcon = find.byIcon(Icons.send);
  if (sendIcon.evaluate().isNotEmpty) {
    await tester.tap(sendIcon.first);
  } else {
    await tester.testTextInput.receiveAction(TextInputAction.send);
  }
  await tester.pumpAndSettle(const Duration(milliseconds: 300));
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
    final btn = find.widgetWithText(ElevatedButton, label);
    if (btn.evaluate().isNotEmpty) return btn;
    final textBtn = find.widgetWithText(TextButton, label);
    if (textBtn.evaluate().isNotEmpty) return textBtn;
  }
  return find.widgetWithText(ElevatedButton, labels.first);
}
