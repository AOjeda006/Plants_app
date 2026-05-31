/// @file community_e2e_test.dart
/// @description Test de integración E2E para el flujo de comunidad:
/// login → feed → crear post → like → comentar → ver perfil ajeno.
/// @module Community
/// @layer Presentation
///
/// PREREQUISITOS:
///   1. Backend corriendo en http://localhost:3000
///   2. Dos usuarios registrados (se crean al arrancar si no existen)
///   3. Ejecutar con: flutter test integration_test/community_e2e_test.dart
///
/// NOTA: El upload de foto en posts se omite en el test automatizado
///   (requiere mock de ImagePicker — TFG FASE 5).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:plants_app/main.dart' as app;

// ─── Constantes ──────────────────────────────────────────────────────────────
const _email    = 'e2e_community_ui@example.com';
const _password = 'Test1234!';
const _name     = 'E2E Community UI';

const _postTitle   = 'Mi monstera fenestrada E2E';
const _postContent = 'Hoy mi monstera ha sacado su primera hoja fenestrada. '
    'La paciencia da sus frutos. ¡Muy emocionante verla crecer!';
const _commentText = 'Qué bonita! ¿Con qué frecuencia la riegas?';

const _netTimeout  = Duration(seconds: 15);
const _animTimeout = Duration(milliseconds: 600);

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E — flujo comunidad', () {
    testWidgets(
      'login → feed → crear post → like → comentar → ver perfil',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // ── 1. LOGIN ──────────────────────────────────────────────────────────
        await _ensureLoggedIn(tester);

        // ── 2. NAVEGAR A PESTAÑA COMUNIDAD ────────────────────────────────────
        final communityTab = find.byIcon(Icons.people_outline);
        if (communityTab.evaluate().isNotEmpty) {
          await tester.tap(communityTab.first);
          await tester.pumpAndSettle(_animTimeout);
        }

        // Verificar que estamos en CommunityFeedPage
        // (FAB de crear post debe estar visible)
        expect(find.byType(FloatingActionButton), findsWidgets);

        // ── 3. CREAR POST (sin foto) ──────────────────────────────────────────
        final createFab = find.byType(FloatingActionButton);
        await tester.tap(createFab.first);
        await tester.pumpAndSettle(_animTimeout);

        // Rellenar formulario de post
        await _fillField(tester, 'Título', _postTitle);
        await _fillField(tester, 'Escribe tu publicación...', _postContent);

        // Tags (opcional — buscar campo de tags)
        final tagsField = find.widgetWithText(TextField, 'Añadir etiqueta');
        if (tagsField.evaluate().isNotEmpty) {
          await tester.tap(tagsField);
          await tester.enterText(tagsField, 'monstera');
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pumpAndSettle(_animTimeout);
        }

        // Publicar
        final publishBtn = _findButton(tester, ['Publicar', 'Crear', 'Guardar']);
        await tester.tap(publishBtn);
        await tester.pumpAndSettle(_netTimeout);

        // ── 4. VERIFICAR POST EN FEED ─────────────────────────────────────────
        // El post debe aparecer en el feed (con título o fragmento del contenido)
        expect(
          find.textContaining(_postTitle),
          findsWidgets,
          reason: 'El post recién creado debe aparecer en el feed',
        );

        // ── 5. DAR LIKE AL POST ───────────────────────────────────────────────
        // Buscar el botón de like del primer post (icono corazón)
        final likeBtn = find.byIcon(Icons.favorite_border);
        if (likeBtn.evaluate().isNotEmpty) {
          await tester.tap(likeBtn.first);
          await tester.pumpAndSettle(_netTimeout);

          // El icono debe cambiar a corazón relleno
          expect(find.byIcon(Icons.favorite), findsWidgets);

          // Dar like de nuevo (toggle — quitar like)
          final filledHeart = find.byIcon(Icons.favorite);
          await tester.tap(filledHeart.first);
          await tester.pumpAndSettle(_netTimeout);
        }

        // ── 6. ABRIR DETALLE DEL POST ─────────────────────────────────────────
        await tester.tap(find.textContaining(_postTitle).first);
        await tester.pumpAndSettle(_netTimeout);

        // Verificar que estamos en PostDetailPage
        expect(find.textContaining(_postTitle), findsWidgets);
        expect(find.textContaining(_postContent.substring(0, 30)), findsWidgets);

        // ── 7. COMENTAR ───────────────────────────────────────────────────────
        // Buscar el campo de input de comentario
        final commentInput = find.widgetWithText(TextField, 'Escribe un comentario...');
        if (commentInput.evaluate().isEmpty) {
          // Puede tener otro hint text
          final altInput = find.byType(TextField);
          if (altInput.evaluate().isNotEmpty) {
            await tester.tap(altInput.last);
            await tester.enterText(altInput.last, _commentText);
          }
        } else {
          await tester.tap(commentInput);
          await tester.enterText(commentInput, _commentText);
        }
        await tester.pumpAndSettle(_animTimeout);

        // Enviar comentario (botón send o icono enviar)
        final sendIcon = find.byIcon(Icons.send);
        if (sendIcon.evaluate().isNotEmpty) {
          await tester.tap(sendIcon.first);
        } else {
          final sendBtn = _findButton(tester, ['Comentar', 'Enviar', 'Publicar']);
          await tester.tap(sendBtn);
        }
        await tester.pumpAndSettle(_netTimeout);

        // Verificar que el comentario aparece en la lista
        expect(
          find.textContaining(_commentText.substring(0, 20)),
          findsWidgets,
          reason: 'El comentario debe aparecer en la lista',
        );

        // ── 8. VER PERFIL DEL AUTOR (perfil propio, ya que somos el autor) ────
        // Tap en el avatar/nombre del autor del post
        final authorAvatar = find.byIcon(Icons.account_circle);
        if (authorAvatar.evaluate().isNotEmpty) {
          await tester.tap(authorAvatar.first);
          await tester.pumpAndSettle(_netTimeout);

          // Volver atrás
          await tester.pageBack();
          await tester.pumpAndSettle(_animTimeout);
        }

        // ── 9. VOLVER AL FEED ─────────────────────────────────────────────────
        await tester.pageBack();
        await tester.pumpAndSettle(_animTimeout);

        // Verificar que el feed sigue siendo accesible
        expect(find.byType(FloatingActionButton), findsWidgets);
      },
    );

    testWidgets(
      'navegación feed → detalle → volver',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));
        await _ensureLoggedIn(tester);

        // Navegar a comunidad
        final communityTab = find.byIcon(Icons.people_outline);
        if (communityTab.evaluate().isNotEmpty) {
          await tester.tap(communityTab.first);
          await tester.pumpAndSettle(_animTimeout);
        }

        // Si hay posts en el feed, abrir el primero
        final firstPost = find.byType(Card).first;
        if (firstPost.evaluate().isNotEmpty) {
          await tester.tap(firstPost);
          await tester.pumpAndSettle(_netTimeout);
          await tester.pageBack();
          await tester.pumpAndSettle(_animTimeout);
        }
      },
    );
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

Future<void> _ensureLoggedIn(WidgetTester tester) async {
  // Si ya hay sesión activa (splash redirige a home), no hacer nada.
  final loginField = find.widgetWithText(TextFormField, 'Email');
  if (loginField.evaluate().isEmpty) return;

  // Registrar si no existe
  final registerLink = find.textContaining('¿No tienes cuenta?');
  if (registerLink.evaluate().isNotEmpty) {
    await tester.tap(registerLink);
    await tester.pumpAndSettle(_animTimeout);
    await _fillField(tester, 'Nombre', _name);
    await _fillField(tester, 'Email', _email);
    await _fillField(tester, 'Contraseña', _password);
    final registerBtn = _findButton(tester, ['Registrarse', 'Crear cuenta']);
    await tester.tap(registerBtn);
    await tester.pumpAndSettle(_netTimeout);
  }

  // Login
  final emailField = find.widgetWithText(TextFormField, 'Email');
  if (emailField.evaluate().isNotEmpty) {
    await tester.enterText(emailField, _email);
    await _fillField(tester, 'Contraseña', _password);
    final loginBtn = _findButton(tester, ['Iniciar sesión', 'Login', 'Entrar']);
    await tester.tap(loginBtn);
    await tester.pumpAndSettle(_netTimeout);
  }
}

Future<void> _fillField(WidgetTester tester, String label, String value) async {
  // Busca por TextFormField con label, o TextField con hint
  Finder field = find.widgetWithText(TextFormField, label);
  if (field.evaluate().isEmpty) {
    field = find.widgetWithText(TextField, label);
  }
  if (field.evaluate().isEmpty) return;
  await tester.tap(field.first);
  await tester.pumpAndSettle(const Duration(milliseconds: 200));
  await tester.enterText(field.first, value);
  await tester.pumpAndSettle(const Duration(milliseconds: 200));
}

/// Busca un botón por una lista de posibles textos (el primero que encuentre).
Finder _findButton(WidgetTester tester, List<String> labels) {
  for (final label in labels) {
    final btn = find.widgetWithText(ElevatedButton, label);
    if (btn.evaluate().isNotEmpty) return btn;
    final textBtn = find.widgetWithText(TextButton, label);
    if (textBtn.evaluate().isNotEmpty) return textBtn;
    final filledBtn = find.widgetWithText(FilledButton, label);
    if (filledBtn.evaluate().isNotEmpty) return filledBtn;
  }
  return find.widgetWithText(ElevatedButton, labels.first);
}
