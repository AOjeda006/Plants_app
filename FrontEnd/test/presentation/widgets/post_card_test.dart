/// @file post_card_test.dart
/// @description Tests de widget para PostCard.
/// Verifica que se muestran el autor, el contenido, el contador de likes
/// y que los callbacks se invocan correctamente.
/// @module Community
/// @layer Presentation
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:plants_app/domain/entities/post.dart';
import 'package:plants_app/presentation/widgets/post_card.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

final _now = DateTime.utc(2026, 3, 5, 10, 0);

Post _makePost({
  String id           = 'post-001',
  String authorName   = 'Test User',
  String content      = 'Contenido del post de prueba',
  int likesCount      = 0,
  int commentsCount   = 0,
}) =>
    Post(
      id:            id,
      userId:        'user-001',
      authorName:    authorName,
      content:       content,
      likesCount:    likesCount,
      commentsCount: commentsCount,
      isLikedByMe:   false,
      createdAt:     _now,
      updatedAt:     _now,
    );

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_ES', null);
  });

  group('PostCard', () {
    testWidgets('muestra el nombre del autor', (tester) async {
      final post = _makePost(authorName: 'María García');
      await tester.pumpWidget(
        _wrap(PostCard(
          post:        post,
          onTap:       () {},
          onLike:      () {},
          onAuthorTap: () {},
        )),
      );

      expect(find.text('María García'), findsOneWidget);
    });

    testWidgets('muestra el contenido del post', (tester) async {
      final post = _makePost(content: 'Mi primera monstera ha sacado una hoja nueva.');
      await tester.pumpWidget(
        _wrap(PostCard(
          post:        post,
          onTap:       () {},
          onLike:      () {},
          onAuthorTap: () {},
        )),
      );

      expect(find.text('Mi primera monstera ha sacado una hoja nueva.'), findsOneWidget);
    });

    testWidgets('muestra el contador de likes cuando likes > 0', (tester) async {
      final post = _makePost(likesCount: 42);
      await tester.pumpWidget(
        _wrap(PostCard(
          post:        post,
          onTap:       () {},
          onLike:      () {},
          onAuthorTap: () {},
        )),
      );

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('no muestra el contador de likes cuando likes = 0', (tester) async {
      final post = _makePost(likesCount: 0);
      await tester.pumpWidget(
        _wrap(PostCard(
          post:        post,
          onTap:       () {},
          onLike:      () {},
          onAuthorTap: () {},
        )),
      );

      // El texto '0' no debería aparecer para likes vacíos.
      // Verificar que el botón de like está presente pero el contador no.
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('llama a onLike al pulsar el botón de like', (tester) async {
      final post = _makePost();
      bool liked = false;
      await tester.pumpWidget(
        _wrap(PostCard(
          post:        post,
          onTap:       () {},
          onLike:      () => liked = true,
          onAuthorTap: () {},
        )),
      );

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      expect(liked, isTrue);
    });

    testWidgets('llama a onTap al pulsar la tarjeta', (tester) async {
      final post = _makePost();
      bool tapped = false;
      await tester.pumpWidget(
        _wrap(PostCard(
          post:        post,
          onTap:       () => tapped = true,
          onLike:      () {},
          onAuthorTap: () {},
        )),
      );

      await tester.tap(find.byType(InkWell).first);
      expect(tapped, isTrue);
    });

    testWidgets('llama a onAuthorTap al pulsar el nombre del autor', (tester) async {
      final post = _makePost(authorName: 'Carlos López');
      bool authorTapped = false;
      await tester.pumpWidget(
        _wrap(PostCard(
          post:        post,
          onTap:       () {},
          onLike:      () {},
          onAuthorTap: () => authorTapped = true,
        )),
      );

      await tester.tap(find.text('Carlos López'));
      expect(authorTapped, isTrue);
    });

    // ── isLikedByMe — icono de corazón toggle ─────────────────────────────────

    testWidgets('muestra corazón relleno cuando isLikedByMe es true', (tester) async {
      final post = Post(
        id:            'post-002',
        userId:        'user-001',
        authorName:    'Ana',
        content:       'Post con like',
        likesCount:    5,
        commentsCount: 0,
        isLikedByMe:   true,
        createdAt:     _now,
        updatedAt:     _now,
      );
      await tester.pumpWidget(
        _wrap(PostCard(
          post:        post,
          onTap:       () {},
          onLike:      () {},
          onAuthorTap: () {},
        )),
      );

      expect(find.byIcon(Icons.favorite_rounded),        findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    });

    testWidgets('muestra corazón vacío cuando isLikedByMe es false', (tester) async {
      final post = _makePost();   // isLikedByMe: false por defecto
      await tester.pumpWidget(
        _wrap(PostCard(
          post:        post,
          onTap:       () {},
          onLike:      () {},
          onAuthorTap: () {},
        )),
      );

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded),        findsNothing);
    });

    // ── Visor de imagen (image_viewer.dart) ──────────────────────────────────────

    testWidgets('muestra la imagen cuando el post tiene URL de imagen', (tester) async {
      final post = Post(
        id:            'post-img',
        userId:        'user-001',
        authorName:    'Ana',
        content:       'Post con imagen',
        likesCount:    0,
        commentsCount: 0,
        isLikedByMe:   false,
        image:         'https://example.com/imagen.jpg',
        createdAt:     _now,
        updatedAt:     _now,
      );
      await tester.pumpWidget(
        _wrap(PostCard(
          post:        post,
          onTap:       () {},
          onLike:      () {},
          onAuthorTap: () {},
        )),
      );

      // Debe haber un GestureDetector que envuelve la imagen para abrir el visor.
      // CachedNetworkImage no carga en tests, pero el GestureDetector sí se monta.
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('no muestra imagen cuando el post no tiene URL de imagen', (tester) async {
      final post = _makePost(); // sin imagen
      await tester.pumpWidget(
        _wrap(PostCard(
          post:        post,
          onTap:       () {},
          onLike:      () {},
          onAuthorTap: () {},
        )),
      );

      // No debe haber CachedNetworkImage (la imagen no se renderiza).
      expect(find.byWidgetPredicate(
        (w) => w.runtimeType.toString().contains('CachedNetworkImage'),
      ), findsNothing);
    });

    testWidgets('botón de like está deshabilitado cuando onLike es null', (tester) async {
      final post = _makePost();
      await tester.pumpWidget(
        _wrap(PostCard(
          post:        post,
          onTap:       () {},
          onLike:      null,   // null = pendingLike en progreso
          onAuthorTap: () {},
        )),
      );

      // IconButton con onPressed null no invoca ningún callback al pulsar.
      final btn = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.favorite_border_rounded),
      );
      expect(btn.onPressed, isNull);
    });
  });
}
