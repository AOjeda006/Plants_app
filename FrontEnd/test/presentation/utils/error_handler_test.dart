/// @file error_handler_test.dart
/// @description Tests de los tres patrones del ErrorHandler unificado:
/// showTransient, inlineBanner y showCritical.
/// @module Core
/// @layer Presentation
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plants_app/presentation/utils/error_handler.dart';

void main() {
  // ─── showTransient ──────────────────────────────────────────────────────────

  group('ErrorHandler.showTransient', () {
    testWidgets('renderiza un SnackBar con el mensaje recibido', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                capturedContext = ctx;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      ErrorHandler.showTransient(capturedContext, 'Mensaje transitorio');
      await tester.pump(); // mostrar SnackBar

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Mensaje transitorio'), findsOneWidget);
    });

    testWidgets('limpia SnackBars previos al mostrar uno nuevo', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                capturedContext = ctx;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      ErrorHandler.showTransient(capturedContext, 'Primero');
      await tester.pump();
      ErrorHandler.showTransient(capturedContext, 'Segundo');
      await tester.pump();

      // Solo el segundo SnackBar debe estar visible
      expect(find.text('Primero'), findsNothing);
      expect(find.text('Segundo'), findsOneWidget);
    });
  });

  // ─── inlineBanner ───────────────────────────────────────────────────────────

  group('ErrorHandler.inlineBanner', () {
    testWidgets('muestra mensaje y botón Reintentar cuando onRetry != null',
        (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorHandler.inlineBanner(
              message: 'No se pudo cargar la lista.',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('No se pudo cargar la lista.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(retried, isTrue);
    });

    testWidgets('omite el botón Reintentar si onRetry es null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorHandler.inlineBanner(message: 'Sin acción'),
          ),
        ),
      );

      expect(find.text('Sin acción'), findsOneWidget);
      expect(find.text('Reintentar'), findsNothing);
    });

    testWidgets('respeta el icono custom pasado por parámetro', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorHandler.inlineBanner(
              message: 'Aviso',
              icon: Icons.warning_amber_rounded,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });
  });

  // ─── showCritical ───────────────────────────────────────────────────────────

  group('ErrorHandler.showCritical', () {
    testWidgets('muestra AlertDialog con título, mensaje y botón confirm',
        (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                capturedContext = ctx;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      final future = ErrorHandler.showCritical(
        capturedContext,
        title: 'Error crítico',
        message: 'Algo se rompió.',
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Error crítico'), findsOneWidget);
      expect(find.text('Algo se rompió.'), findsOneWidget);
      // Etiqueta por defecto
      expect(find.text('Entendido'), findsOneWidget);

      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();

      expect(await future, isTrue);
    });

    testWidgets('cancelLabel se muestra y devuelve false al pulsarlo',
        (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                capturedContext = ctx;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      final future = ErrorHandler.showCritical(
        capturedContext,
        title: 'Confirmar',
        message: 'Acción irreversible',
        confirmLabel: 'Borrar',
        cancelLabel: 'Cancelar',
      );
      await tester.pumpAndSettle();

      expect(find.text('Borrar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(await future, isFalse);
    });
  });
}
