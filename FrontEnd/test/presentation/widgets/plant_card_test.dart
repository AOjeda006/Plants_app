/// @file plant_card_test.dart
/// @description Tests de widget para PlantCard.
/// Verifica que se muestra el nombre, el badge de riego y el placeholder
/// cuando la planta no tiene foto.
/// @module Plants
/// @layer Presentation
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plants_app/domain/entities/plant.dart';
import 'package:plants_app/presentation/widgets/plant_card.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

Plant _makePlant({
  String id            = 'plant-001',
  String name          = 'Monstera Deliciosa',
  String? photo,
  DateTime? nextWatering,
}) =>
    Plant(
      id:                    id,
      userId:                'user-001',
      name:                  name,
      wateringFrequencyDays: 7,
      isActive:              true,
      createdAt:             DateTime.now().toUtc(),
      updatedAt:             DateTime.now().toUtc(),
      photo:                 photo,
      nextWatering:          nextWatering,
    );

/// Envuelve el widget en MaterialApp para que pueda acceder al Theme.
Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width:  200,
          height: 260,
          child:  child,
        ),
      ),
    );

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('PlantCard', () {
    testWidgets('muestra el nombre de la planta', (tester) async {
      final plant = _makePlant(name: 'Monstera Deliciosa');
      await tester.pumpWidget(_wrap(PlantCard(plant: plant)));

      expect(find.text('Monstera Deliciosa'), findsOneWidget);
    });

    testWidgets('muestra el placeholder cuando la planta no tiene foto', (tester) async {
      final plant = _makePlant(photo: null);
      await tester.pumpWidget(_wrap(PlantCard(plant: plant)));

      // El placeholder contiene el icono de planta.
      expect(find.byIcon(Icons.local_florist_outlined), findsOneWidget);
    });

    testWidgets('muestra el badge de riego cuando la planta necesita riego hoy', (tester) async {
      // nextWatering = ayer → needsWatering = true.
      final yesterday = DateTime.now().toUtc().subtract(const Duration(days: 1));
      final plant     = _makePlant(nextWatering: yesterday);
      await tester.pumpWidget(_wrap(PlantCard(plant: plant)));

      // El badge contiene el icono de gota de agua.
      expect(find.byIcon(Icons.water_drop_outlined), findsWidgets);
    });

    testWidgets('no muestra badge de riego cuando la planta no necesita riego', (tester) async {
      // nextWatering = en 5 días desde hoy → needsWatering = false.
      final future = DateTime.now().toUtc().add(const Duration(days: 5));
      final plant  = _makePlant(nextWatering: future);
      await tester.pumpWidget(_wrap(PlantCard(plant: plant)));

      // El badge solo aparece dentro de un Stack cuando needsWatering es true.
      // El texto "¡Riego hoy!" no debería estar presente.
      expect(find.text('¡Riego hoy!'), findsNothing);
    });

    testWidgets('llama a onTap cuando se pulsa la tarjeta', (tester) async {
      final plant = _makePlant();
      bool tapped = false;
      await tester.pumpWidget(
        _wrap(PlantCard(plant: plant, onTap: () => tapped = true)),
      );

      await tester.tap(find.byType(GestureDetector).first);
      expect(tapped, isTrue);
    });

    testWidgets('muestra "Sin fecha de riego" cuando nextWatering es null', (tester) async {
      final plant = _makePlant(nextWatering: null);
      await tester.pumpWidget(_wrap(PlantCard(plant: plant)));

      expect(find.text('Sin fecha de riego'), findsOneWidget);
    });
  });
}
