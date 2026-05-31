/// @file plant_detail_page_seasonal_helpers_test.dart
/// @description Tests unitarios de los helpers públicos
/// `currentSeasonalFactor` y `currentSeasonLabel` exportados desde
/// plant_detail_page.dart. Verifican que la fórmula del frontend
/// coincide con la del backend
/// (`ProcessPendingRemindersUseCase.getSeasonalFactor`).
/// @module Plants
/// @layer Presentation
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:plants_app/domain/entities/plant_species.dart';
import 'package:plants_app/presentation/pages/plant_detail_page.dart';

PlantSpecies _baseSpecies({SeasonalWateringAdjustment? adj}) => PlantSpecies(
      id:                'sp-1',
      name:              'Test',
      scientificName:    'Plantum testum',
      image:             null,
      careRequirements:  const SpeciesCareRequirements(
        wateringDays: 5,
        lightNeed:    'Medium',
      ),
      climateCompatibility:       const ['Mediterranean'],
      tips:                       const [],
      isPublic:                   true,
      createdBy:                  'user-1',
      createdAt:                  DateTime.utc(2026, 1, 1),
      updatedAt:                  DateTime.utc(2026, 1, 1),
      seasonalWateringAdjustment: adj,
    );

PlantSpecies _speciesWith({double? summer, double? winter}) =>
    _baseSpecies(adj: SeasonalWateringAdjustment(summer: summer, winter: winter));

PlantSpecies _speciesWithoutAdjustment() => _baseSpecies();

void main() {
  group('currentSeasonalFactor()', () {
    test('species null → null', () {
      expect(currentSeasonalFactor(null, now: DateTime(2026, 1, 15)), isNull);
    });

    test('species sin seasonalWateringAdjustment → null', () {
      expect(
        currentSeasonalFactor(_speciesWithoutAdjustment(), now: DateTime(2026, 1, 15)),
        isNull,
      );
    });

    test('invierno (enero) con winter=0.6 → 0.6', () {
      expect(
        currentSeasonalFactor(_speciesWith(winter: 0.6), now: DateTime(2026, 1, 15)),
        0.6,
      );
    });

    test('invierno (diciembre) con winter=1.4 → 1.4', () {
      expect(
        currentSeasonalFactor(_speciesWith(winter: 1.4), now: DateTime(2026, 12, 20)),
        1.4,
      );
    });

    test('verano (julio) con summer=0.7 → 0.7', () {
      expect(
        currentSeasonalFactor(_speciesWith(summer: 0.7), now: DateTime(2026, 7, 1)),
        0.7,
      );
    });

    test('primavera (mayo) → SIEMPRE 1.0 aunque la especie tenga summer/winter', () {
      expect(
        currentSeasonalFactor(
          _speciesWith(summer: 0.7, winter: 1.4),
          now: DateTime(2026, 5, 12),
        ),
        1.0,
      );
    });

    test('otoño (octubre) → SIEMPRE 1.0', () {
      expect(
        currentSeasonalFactor(
          _speciesWith(summer: 0.5, winter: 2.0),
          now: DateTime(2026, 10, 1),
        ),
        1.0,
      );
    });

    test('invierno con winter no definido en la especie → default 1.0', () {
      expect(
        currentSeasonalFactor(_speciesWith(summer: 0.5), now: DateTime(2026, 1, 15)),
        1.0,
      );
    });
  });

  group('currentSeasonLabel()', () {
    test('enero → invierno',  () => expect(currentSeasonLabel(now: DateTime(2026, 1,  15)), 'invierno'));
    test('febrero → invierno',() => expect(currentSeasonLabel(now: DateTime(2026, 2,  15)), 'invierno'));
    test('marzo → primavera', () => expect(currentSeasonLabel(now: DateTime(2026, 3,  15)), 'primavera'));
    test('mayo → primavera',  () => expect(currentSeasonLabel(now: DateTime(2026, 5,  15)), 'primavera'));
    test('junio → verano',    () => expect(currentSeasonLabel(now: DateTime(2026, 6,  15)), 'verano'));
    test('agosto → verano',   () => expect(currentSeasonLabel(now: DateTime(2026, 8,  15)), 'verano'));
    test('septiembre → otoño',() => expect(currentSeasonLabel(now: DateTime(2026, 9,  15)), 'otoño'));
    test('noviembre → otoño', () => expect(currentSeasonLabel(now: DateTime(2026, 11, 15)), 'otoño'));
    test('diciembre → invierno', () => expect(currentSeasonLabel(now: DateTime(2026, 12, 15)), 'invierno'));
  });
}
