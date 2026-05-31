/// @file utils_test.dart
/// @description Tests unitarios para RetryUtils y PlantDateUtils.
/// Verifica backoff exponencial, secuencia de delays, reintento automático
/// y cálculos de fechas de riego.
/// @module Core
/// @layer Core
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:plants_app/core/utils/retry_utils.dart';
import 'package:plants_app/core/utils/date_utils.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// RETRY UTILS
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('RetryUtils.computeDelay()', () {
    test('intento 0 con defaults devuelve al menos 1 s y como máximo 2 s (base + jitter)', () {
      final delay = RetryUtils.computeDelay(attempt: 0, maxJitter: Duration.zero);
      // Sin jitter: base = 1 s, factor^0 = 1, resultado = 1 s.
      expect(delay, equals(const Duration(seconds: 1)));
    });

    test('intento 1 con factor 2 devuelve 2 s (sin jitter)', () {
      final delay = RetryUtils.computeDelay(
        attempt:   1,
        maxJitter: Duration.zero,
      );
      expect(delay, equals(const Duration(seconds: 2)));
    });

    test('intento 2 con factor 2 devuelve 4 s (sin jitter)', () {
      final delay = RetryUtils.computeDelay(
        attempt:   2,
        maxJitter: Duration.zero,
      );
      expect(delay, equals(const Duration(seconds: 4)));
    });

    test('el delay no supera maxDelay', () {
      final delay = RetryUtils.computeDelay(
        attempt:   100,              // exponente enorme
        maxDelay:  const Duration(seconds: 30),
        maxJitter: Duration.zero,
      );
      expect(delay, equals(const Duration(seconds: 30)));
    });

    test('el jitter añade una cantidad no negativa', () {
      // Con jitter habilitado, el delay debe ser >= el valor determinista.
      final withoutJitter = RetryUtils.computeDelay(attempt: 0, maxJitter: Duration.zero);
      final withJitter    = RetryUtils.computeDelay(attempt: 0);
      expect(withJitter.inMilliseconds, greaterThanOrEqualTo(withoutJitter.inMilliseconds));
    });
  });

  // ── delaySequence ─────────────────────────────────────────────────────────────

  group('RetryUtils.delaySequence()', () {
    test('devuelve la secuencia 1s, 2s, 4s para 3 intentos con factor 2', () {
      final seq = RetryUtils.delaySequence(maxRetries: 3);
      expect(seq.length, 3);
      expect(seq[0], const Duration(seconds: 1));
      expect(seq[1], const Duration(seconds: 2));
      expect(seq[2], const Duration(seconds: 4));
    });

    test('todos los valores están acotados por maxDelay', () {
      final seq = RetryUtils.delaySequence(
        maxRetries: 10,
        maxDelay:   const Duration(seconds: 5),
      );
      for (final d in seq) {
        expect(d.inSeconds, lessThanOrEqualTo(5));
      }
    });
  });

  // ── withRetry ─────────────────────────────────────────────────────────────────

  group('RetryUtils.withRetry()', () {
    test('devuelve el resultado si la primera llamada tiene éxito', () async {
      int calls = 0;
      final result = await RetryUtils.withRetry<int>(
        () async { calls++; return 42; },
        maxRetries: 3,
        base:       Duration.zero,
      );
      expect(result, 42);
      expect(calls, 1);
    });

    test('reintenta hasta maxRetries veces y lanza la última excepción', () async {
      int calls = 0;
      await expectLater(
        RetryUtils.withRetry<void>(
          () async { calls++; throw Exception('fallo'); },
          maxRetries: 2,
          base: Duration.zero,
        ),
        throwsException,
      );
      // 1 llamada original + 2 reintentos = 3 llamadas en total.
      expect(calls, 3);
    });

    test('no reintenta si shouldRetry devuelve false', () async {
      int calls = 0;
      await expectLater(
        RetryUtils.withRetry<void>(
          () async { calls++; throw StateError('no retry'); },
          maxRetries:  5,
          base:        Duration.zero,
          shouldRetry: (e) => false,
        ),
        throwsStateError,
      );
      expect(calls, 1);
    });

    test('se detiene cuando shouldRetry devuelve false para ciertos errores', () async {
      int calls = 0;
      await expectLater(
        RetryUtils.withRetry<void>(
          () async {
            calls++;
            if (calls < 2) throw ArgumentError('retry');
            throw StateError('no retry');
          },
          maxRetries:  5,
          base:        Duration.zero,
          shouldRetry: (e) => e is ArgumentError,
        ),
        throwsStateError,
      );
      expect(calls, 2);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════════
  // PLANT DATE UTILS
  // ═══════════════════════════════════════════════════════════════════════════════

  group('PlantDateUtils.nextWateringDate()', () {
    test('suma la frecuencia en días a la fecha de último riego', () {
      final last = DateTime.utc(2026, 3, 1);
      final next = PlantDateUtils.nextWateringDate(
        lastWatered: last, frequencyDays: 7,
      );
      expect(next, DateTime.utc(2026, 3, 8));
    });

    test('funciona para frecuencias diarias (1 día)', () {
      final last = DateTime.utc(2026, 3, 5);
      final next = PlantDateUtils.nextWateringDate(
        lastWatered: last, frequencyDays: 1,
      );
      expect(next, DateTime.utc(2026, 3, 6));
    });
  });

  // ── needsWateringToday ────────────────────────────────────────────────────────

  group('PlantDateUtils.needsWateringToday()', () {
    test('devuelve false si el próximo riego es en el futuro', () {
      // lastWatered hoy + frecuencia 7 días → próximo riego en 7 días.
      final last    = DateTime.now().toUtc();
      final result  = PlantDateUtils.needsWateringToday(
        lastWatered: last, frequencyDays: 7,
      );
      expect(result, isFalse);
    });

    test('devuelve true si el próximo riego era hace días (atrasado)', () {
      // lastWatered hace 14 días + frecuencia 7 días → atrasado 7 días.
      final last   = DateTime.now().toUtc().subtract(const Duration(days: 14));
      final result = PlantDateUtils.needsWateringToday(
        lastWatered: last, frequencyDays: 7,
      );
      expect(result, isTrue);
    });
  });

  // ── formatDate ────────────────────────────────────────────────────────────────

  group('PlantDateUtils.formatDate()', () {
    test('formatea correctamente en formato dd/MM/yyyy', () {
      final date   = DateTime(2026, 1, 5, 10, 30);
      final result = PlantDateUtils.formatDate(date);
      expect(result, '05/01/2026');
    });

    test('rellena con cero los días y meses de un dígito', () {
      final date   = DateTime(2026, 3, 5);
      final result = PlantDateUtils.formatDate(date);
      expect(result, '05/03/2026');
    });
  });

  // ── formatDateTime ────────────────────────────────────────────────────────────

  group('PlantDateUtils.formatDateTime()', () {
    test('incluye fecha y hora', () {
      final date   = DateTime(2026, 6, 15, 9, 5);
      final result = PlantDateUtils.formatDateTime(date);
      expect(result, contains('15/06/2026'));
      expect(result, contains('09:05'));
    });
  });

  // ── relativeDay ───────────────────────────────────────────────────────────────

  group('PlantDateUtils.relativeDay()', () {
    test('devuelve "Hoy" para la fecha de hoy', () {
      final today  = DateTime.now().toUtc();
      final result = PlantDateUtils.relativeDay(today);
      expect(result, 'Hoy');
    });

    test('devuelve "Mañana" para la fecha de mañana', () {
      final tomorrow = DateTime.now().toUtc().add(const Duration(days: 1));
      final result   = PlantDateUtils.relativeDay(tomorrow);
      expect(result, 'Mañana');
    });

    test('devuelve "Ayer" para la fecha de ayer', () {
      final yesterday = DateTime.now().toUtc().subtract(const Duration(days: 1));
      final result    = PlantDateUtils.relativeDay(yesterday);
      expect(result, 'Ayer');
    });

    test('devuelve "En N días" para fechas futuras más de 1 día', () {
      final future = DateTime.now().toUtc().add(const Duration(days: 5));
      final result = PlantDateUtils.relativeDay(future);
      expect(result, 'En 5 días');
    });

    test('devuelve "Hace N días" para fechas pasadas más de 1 día', () {
      final past   = DateTime.now().toUtc().subtract(const Duration(days: 3));
      final result = PlantDateUtils.relativeDay(past);
      expect(result, 'Hace 3 días');
    });
  });

  // ── parseUtc ──────────────────────────────────────────────────────────────────

  group('PlantDateUtils.parseUtc()', () {
    test('parsea correctamente un string ISO 8601', () {
      final result = PlantDateUtils.parseUtc('2026-03-05T10:00:00.000Z');
      expect(result, isNotNull);
      expect(result!.year,  2026);
      expect(result.month,  3);
      expect(result.day,    5);
      expect(result.isUtc,  isTrue);
    });

    test('devuelve null para string nulo', () {
      expect(PlantDateUtils.parseUtc(null), isNull);
    });

    test('devuelve null para string vacío', () {
      expect(PlantDateUtils.parseUtc(''), isNull);
    });

    test('devuelve null para formato inválido', () {
      expect(PlantDateUtils.parseUtc('no-es-fecha'), isNull);
    });
  });

  // ── wateringUrgencyLabel ──────────────────────────────────────────────────────

  group('PlantDateUtils.wateringUrgencyLabel()', () {
    test('devuelve "Atrasado" si ya pasó la fecha de riego', () {
      final last   = DateTime.now().toUtc().subtract(const Duration(days: 14));
      final result = PlantDateUtils.wateringUrgencyLabel(
        lastWatered: last, frequencyDays: 7,
      );
      expect(result, 'Atrasado');
    });

    test('devuelve "Hoy" si el riego es hoy', () {
      // lastWatered hace exactamente 7 días con frecuencia 7 → hoy.
      final last   = DateTime.now().toUtc().subtract(const Duration(days: 7));
      final result = PlantDateUtils.wateringUrgencyLabel(
        lastWatered: last, frequencyDays: 7,
      );
      expect(result, 'Hoy');
    });

    test('devuelve "Mañana" si el riego es mañana', () {
      final last   = DateTime.now().toUtc().subtract(const Duration(days: 6));
      final result = PlantDateUtils.wateringUrgencyLabel(
        lastWatered: last, frequencyDays: 7,
      );
      expect(result, 'Mañana');
    });

    test('devuelve "En N días" para fechas futuras más de 1 día', () {
      final last   = DateTime.now().toUtc();
      final result = PlantDateUtils.wateringUrgencyLabel(
        lastWatered: last, frequencyDays: 14,
      );
      expect(result, startsWith('En'));
    });
  });

}
