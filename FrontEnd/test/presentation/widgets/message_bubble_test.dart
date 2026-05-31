/// @file message_bubble_test.dart
/// @description Tests de widget para MessageBubble.
/// Verifica alineación (propio vs. ajeno), icono de estado de entrega
/// y renderizado del texto del mensaje.
/// @module Chat
/// @layer Presentation
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plants_app/domain/entities/message.dart';
import 'package:plants_app/presentation/widgets/message_bubble.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

final _now = DateTime.utc(2026, 3, 5, 10, 30);

Message _makeMessage({
  String id             = 'msg-001',
  String text           = 'Hola desde la monstera',
  MessageStatus status  = MessageStatus.delivered,
  String? tempId,
}) =>
    Message(
      id:             id,
      conversationId: 'conv-001',
      senderId:       'sender-001',
      senderName:     'Sender',
      text:           text,
      status:         status,
      tempId:         tempId,
      createdAt:      _now,
    );

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width:  400,
          height: 200,
          child:  child,
        ),
      ),
    );

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('MessageBubble', () {
    testWidgets('muestra el texto del mensaje', (tester) async {
      final msg = _makeMessage(text: 'Hola desde la monstera');
      await tester.pumpWidget(_wrap(
        MessageBubble(message: msg, isMine: true),
      ));

      expect(find.text('Hola desde la monstera'), findsOneWidget);
    });

    testWidgets('mensaje propio se alinea a la derecha (Alignment.centerRight)', (tester) async {
      final msg = _makeMessage();
      await tester.pumpWidget(_wrap(
        MessageBubble(message: msg, isMine: true),
      ));

      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerRight);
    });

    testWidgets('mensaje ajeno se alinea a la izquierda (Alignment.centerLeft)', (tester) async {
      final msg = _makeMessage();
      await tester.pumpWidget(_wrap(
        MessageBubble(message: msg, isMine: false),
      ));

      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerLeft);
    });

    testWidgets('mensaje pending muestra icono de reloj (Icons.schedule)', (tester) async {
      final msg = _makeMessage(status: MessageStatus.pending);
      await tester.pumpWidget(_wrap(
        MessageBubble(message: msg, isMine: true),
      ));

      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('mensaje sent muestra icono de check simple (Icons.done)', (tester) async {
      final msg = _makeMessage(status: MessageStatus.sent);
      await tester.pumpWidget(_wrap(
        MessageBubble(message: msg, isMine: true),
      ));

      expect(find.byIcon(Icons.done), findsOneWidget);
      // No debe mostrar doble check — solo el simple.
      expect(find.byIcon(Icons.done_all), findsNothing);
    });

    testWidgets('mensaje delivered muestra icono de doble check (Icons.done_all)', (tester) async {
      final msg = _makeMessage(status: MessageStatus.delivered);
      await tester.pumpWidget(_wrap(
        MessageBubble(message: msg, isMine: true),
      ));

      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });

    testWidgets('mensaje read muestra icono de doble check (Icons.done_all)', (tester) async {
      final msg = _makeMessage(status: MessageStatus.read);
      await tester.pumpWidget(_wrap(
        MessageBubble(message: msg, isMine: true),
      ));

      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });

    testWidgets('mensaje read usa color de acento (azul) distinto a delivered', (tester) async {
      final msg = _makeMessage(status: MessageStatus.read);
      await tester.pumpWidget(_wrap(
        MessageBubble(message: msg, isMine: true),
      ));

      // El icono done_all para read debe tener el color de acento, no blanco translúcido.
      final icon = tester.widget<Icon>(find.byIcon(Icons.done_all));
      // Verificar que NO usa blanco translúcido (que sería el color de delivered).
      expect(icon.color, isNot(equals(Colors.white.withAlpha(178))));
    });

    testWidgets('mensaje ajeno no muestra icono de estado', (tester) async {
      final msg = _makeMessage(status: MessageStatus.delivered);
      await tester.pumpWidget(_wrap(
        MessageBubble(message: msg, isMine: false),
      ));

      // Los iconos de estado solo se muestran en mensajes propios.
      expect(find.byIcon(Icons.done),     findsNothing);
      expect(find.byIcon(Icons.done_all), findsNothing);
      expect(find.byIcon(Icons.schedule), findsNothing);
    });

    testWidgets('muestra el timestamp en formato HH:mm', (tester) async {
      final msg = _makeMessage();
      await tester.pumpWidget(_wrap(
        MessageBubble(message: msg, isMine: true),
      ));

      // El timestamp formateado debe aparecer en el widget.
      // La hora 10:30 UTC formateada en local puede variar, pero el formato HH:mm debe estar presente.
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      final hasTimestamp = textWidgets.any((t) {
        final data = t.data ?? '';
        return RegExp(r'^\d{2}:\d{2}$').hasMatch(data);
      });
      expect(hasTimestamp, isTrue);
    });
  });
}
