/// @file plant_species_model_test.dart
/// @description Tests unitarios para PlantSpeciesModel.fromJson.
/// Verifica que los campos nullable (image, createdAt, updatedAt) no crashan
/// cuando la API omite la clave o envía null explícito.
/// @module Plants
/// @layer Data
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:plants_app/data/models/plant_species_model.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// JSON base con todos los campos obligatorios. image ausente por defecto.
Map<String, dynamic> _baseJson({String? image, bool includeImage = false}) => {
  '_id':                  'species-001',
  'name':                 'Monstera Deliciosa',
  'scientificName':       'Monstera deliciosa',
  'isPublic':             true,
  'createdBy':            'user-001',
  'createdAt':            '2026-01-01T00:00:00.000Z',
  'updatedAt':            '2026-01-01T00:00:00.000Z',
  'climateCompatibility': ['tropical', 'subtropical'],
  'tips':                 ['Regar cada 7 días', 'Luz indirecta'],
  'careRequirements': {
    'wateringDays': 7,
    'lightNeed':    'medium',
  },
  if (includeImage || image != null) 'image': image,
};

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('PlantSpeciesModel.fromJson — campo image nullable', () {
    test('image es null cuando la clave no está presente en el JSON', () {
      final model = PlantSpeciesModel.fromJson(_baseJson());
      expect(model.image, isNull);
    });

    test('image es null cuando el JSON incluye image: null explícito', () {
      final model = PlantSpeciesModel.fromJson(_baseJson(includeImage: true));
      expect(model.image, isNull);
    });

    test('image contiene la URL cuando el JSON incluye una cadena válida', () {
      const url = 'https://res.cloudinary.com/demo/image/upload/monstera.jpg';
      final model = PlantSpeciesModel.fromJson(_baseJson(image: url));
      expect(model.image, equals(url));
    });
  });

  group('PlantSpeciesModel.fromJson — createdAt / updatedAt nullable', () {
    test('createdAt y updatedAt son cadena vacía cuando el JSON envía null (bug F6-fix)', () {
      final json = {
        ..._baseJson(),
        'createdAt': null,
        'updatedAt': null,
      };
      final model = PlantSpeciesModel.fromJson(json);
      expect(model.createdAt, equals(''));
      expect(model.updatedAt, equals(''));
    });

    test('createdAt y updatedAt son cadena vacía cuando las claves están ausentes', () {
      final json = Map<String, dynamic>.from(_baseJson())
        ..remove('createdAt')
        ..remove('updatedAt');
      final model = PlantSpeciesModel.fromJson(json);
      expect(model.createdAt, equals(''));
      expect(model.updatedAt, equals(''));
    });

    test('createdAt y updatedAt conservan el valor ISO cuando está presente', () {
      final model = PlantSpeciesModel.fromJson(_baseJson());
      expect(model.createdAt, equals('2026-01-01T00:00:00.000Z'));
      expect(model.updatedAt, equals('2026-01-01T00:00:00.000Z'));
    });
  });

  group('PlantSpeciesModel.fromJson — campos obligatorios', () {
    test('parsea id, name y scientificName correctamente', () {
      final model = PlantSpeciesModel.fromJson(_baseJson());
      expect(model.id,             equals('species-001'));
      expect(model.name,           equals('Monstera Deliciosa'));
      expect(model.scientificName, equals('Monstera deliciosa'));
    });

    test('parsea careRequirements correctamente', () {
      final model = PlantSpeciesModel.fromJson(_baseJson());
      expect(model.careRequirements.wateringDays, equals(7));
      expect(model.careRequirements.lightNeed,    equals('medium'));
    });

    test('parsea climateCompatibility y tips como listas', () {
      final model = PlantSpeciesModel.fromJson(_baseJson());
      expect(model.climateCompatibility, containsAll(['tropical', 'subtropical']));
      expect(model.tips, hasLength(2));
    });

    test('acepta _id como identificador (formato MongoDB)', () {
      final model = PlantSpeciesModel.fromJson(_baseJson());
      expect(model.id, equals('species-001'));
    });

    test('climateCompatibility y tips son listas vacías si el JSON las omite', () {
      final json = {
        '_id': 's-002', 'name': 'Cactus', 'scientificName': 'Cactus sp.',
        'isPublic': false, 'createdBy': '', 'createdAt': '', 'updatedAt': '',
        'careRequirements': {'wateringDays': 30, 'lightNeed': 'high'},
      };
      final model = PlantSpeciesModel.fromJson(json);
      expect(model.climateCompatibility, isEmpty);
      expect(model.tips,                 isEmpty);
    });
  });

  group('PlantSpeciesModel.fromJson — produceFruit / harvestMonths nullable', () {
    test('produceFruit es null cuando el JSON no incluye la clave', () {
      final model = PlantSpeciesModel.fromJson(_baseJson());
      expect(model.produceFruit, isNull);
    });

    test('harvestMonths es null cuando el JSON no incluye la clave', () {
      final model = PlantSpeciesModel.fromJson(_baseJson());
      expect(model.harvestMonths, isNull);
    });

    test('produceFruit=true se parsea correctamente', () {
      final json = {..._baseJson(), 'produceFruit': true};
      final model = PlantSpeciesModel.fromJson(json);
      expect(model.produceFruit, isTrue);
    });

    test('harvestMonths=[6,7,8] se parsea como List<int> correctamente', () {
      final json  = {..._baseJson(), 'produceFruit': true, 'harvestMonths': [6, 7, 8]};
      final model = PlantSpeciesModel.fromJson(json);
      expect(model.harvestMonths, equals([6, 7, 8]));
    });

    test('harvestMonths lista vacía se parsea como lista vacía', () {
      final json  = {..._baseJson(), 'produceFruit': true, 'harvestMonths': <dynamic>[]};
      final model = PlantSpeciesModel.fromJson(json);
      expect(model.harvestMonths, isEmpty);
    });
  });

  group('PlantSpeciesModel.fromJson — pruningMonths array', () {
    test('pruningMonths es null cuando el JSON no incluye la clave', () {
      final model = PlantSpeciesModel.fromJson(_baseJson());
      expect(model.pruningMonths, isNull);
    });

    test('pruningMonths=[2] se parsea como List<int> correctamente', () {
      final json  = {..._baseJson(), 'requiresPruning': true, 'pruningMonths': [2]};
      final model = PlantSpeciesModel.fromJson(json);
      expect(model.pruningMonths, equals([2]));
    });

    test('pruningMonths con todos los meses [1..12] se parsea correctamente', () {
      final allMonths = List.generate(12, (i) => i + 1);
      final json  = {..._baseJson(), 'requiresPruning': true, 'pruningMonths': allMonths};
      final model = PlantSpeciesModel.fromJson(json);
      expect(model.pruningMonths, equals(allMonths));
      expect(model.pruningMonths, hasLength(12));
    });
  });

  group('PlantSpeciesModel.fromJson — minRainfallMm / waterLitersPerWatering', () {
    test('minRainfallMm es null cuando el JSON no incluye la clave', () {
      final model = PlantSpeciesModel.fromJson(_baseJson());
      expect(model.minRainfallMm, isNull);
    });

    test('waterLitersPerWatering es null cuando el JSON no incluye la clave', () {
      final model = PlantSpeciesModel.fromJson(_baseJson());
      expect(model.waterLitersPerWatering, isNull);
    });

    test('minRainfallMm=5.0 se parsea como double correctamente', () {
      final json  = {..._baseJson(), 'minRainfallMm': 5.0};
      final model = PlantSpeciesModel.fromJson(json);
      expect(model.minRainfallMm, equals(5.0));
    });

    test('waterLitersPerWatering=1.5 se parsea como double correctamente', () {
      final json  = {..._baseJson(), 'waterLitersPerWatering': 1.5};
      final model = PlantSpeciesModel.fromJson(json);
      expect(model.waterLitersPerWatering, equals(1.5));
    });

    test('minRainfallMm int (1) se parsea como double correctamente', () {
      final json  = {..._baseJson(), 'minRainfallMm': 1};
      final model = PlantSpeciesModel.fromJson(json);
      expect(model.minRainfallMm, equals(1.0));
    });
  });

  group('PlantSpeciesModel.fromJson — especie Test completa', () {
    test('parsea especie Test con todos los campos (wateringDays:1, 12 meses poda/cosecha)', () {
      final json = {
        '_id':                  'species-test',
        'name':                 'Test',
        'scientificName':       'Testus maximus',
        'image':                '',
        'isPublic':             true,
        'createdBy':            'admin',
        'createdAt':            '2026-04-16T00:00:00.000Z',
        'updatedAt':            '2026-04-16T00:00:00.000Z',
        'climateCompatibility': ['Todos'],
        'tips':                 ['Especie de pruebas para testing de funcionalidades.'],
        'careRequirements': {
          'wateringDays': 1,
          'lightNeed':    'Medium',
        },
        'requiresPruning':            true,
        'pruningMonths':              List.generate(12, (i) => i + 1),
        'produceFruit':               true,
        'harvestMonths':              List.generate(12, (i) => i + 1),
        'minRainfallMm':              1,
        'waterLitersPerWatering':     0.5,
      };

      final model = PlantSpeciesModel.fromJson(json);

      expect(model.name, equals('Test'));
      expect(model.scientificName, equals('Testus maximus'));
      expect(model.careRequirements.wateringDays, equals(1));
      expect(model.requiresPruning, isTrue);
      expect(model.pruningMonths, hasLength(12));
      expect(model.pruningMonths, equals(List.generate(12, (i) => i + 1)));
      expect(model.produceFruit, isTrue);
      expect(model.harvestMonths, hasLength(12));
      expect(model.harvestMonths, equals(List.generate(12, (i) => i + 1)));
      expect(model.minRainfallMm, equals(1.0));
      expect(model.waterLitersPerWatering, equals(0.5));
    });
  });
}
