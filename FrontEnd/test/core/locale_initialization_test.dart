/// @file locale_initialization_test.dart
/// @description Verifica que initializeDateFormatting('es_ES') funciona
/// correctamente. Sin esta inicialización, `DateFormat` lanza
/// `LocaleDataException` en runtime.
/// @module Core
/// @layer Core
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  group('initializeDateFormatting — locale es_ES', () {
    setUpAll(() async {
      await initializeDateFormatting('es_ES', null);
    });

    test('no lanza excepción al inicializar es_ES', () async {
      // Si ya está inicializado, llamarlo de nuevo tampoco debe lanzar.
      await expectLater(
        initializeDateFormatting('es_ES', null),
        completes,
      );
    });

    test('DateFormat formatea día y mes en español', () {
      final date      = DateTime(2026, 3, 13);
      final formatted = DateFormat('d \'de\' MMMM', 'es_ES').format(date);
      expect(formatted, equals('13 de marzo'));
    });

    test('DateFormat formatea año completo en español', () {
      final date      = DateTime(2026, 3, 13);
      final formatted = DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES').format(date);
      expect(formatted, equals('13 de marzo de 2026'));
    });

    test('DateFormat formatea hora en español', () {
      final date      = DateTime(2026, 3, 13, 14, 30);
      final formatted = DateFormat('HH:mm', 'es_ES').format(date);
      expect(formatted, equals('14:30'));
    });
  });
}
