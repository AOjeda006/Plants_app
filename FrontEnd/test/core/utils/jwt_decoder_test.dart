/// @file jwt_decoder_test.dart
/// @description Tests del helper JWT (decode payload + cálculo de días hasta exp).
/// @module Core
/// @layer Core
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plants_app/core/utils/jwt_decoder.dart';

/// Construye un JWT válido (header + payload + signature) sin firma real.
/// La firma no se verifica nunca en frontend.
String _makeJwt(Map<String, dynamic> payload) {
  String b64(String s) => base64Url.encode(utf8.encode(s)).replaceAll('=', '');
  final header = b64(jsonEncode({'alg': 'HS256', 'typ': 'JWT'}));
  final body   = b64(jsonEncode(payload));
  return '$header.$body.signature';
}

void main() {
  group('decodeJwtPayload()', () {
    test('decodifica correctamente un payload válido', () {
      final token = _makeJwt({'userId': 'abc', 'email': 'x@x.com', 'exp': 1234});
      final result = decodeJwtPayload(token);
      expect(result, isNotNull);
      expect(result!['userId'], 'abc');
      expect(result['email'],   'x@x.com');
      expect(result['exp'],     1234);
    });

    test('devuelve null si no tiene 3 segmentos', () {
      expect(decodeJwtPayload('only.two'),     isNull);
      expect(decodeJwtPayload('a.b.c.d'),      isNull);
      expect(decodeJwtPayload(''),             isNull);
    });

    test('devuelve null si el segmento del payload no es base64 válido', () {
      expect(decodeJwtPayload('header.NOT_BASE64!@#.sig'), isNull);
    });
  });

  group('jwtDaysUntilExpiry()', () {
    test('calcula días positivos cuando exp está en el futuro', () {
      final now = DateTime.utc(2026, 5, 1, 12);
      final exp = now.add(const Duration(days: 30)).millisecondsSinceEpoch ~/ 1000;
      final token = _makeJwt({'exp': exp});

      final days = jwtDaysUntilExpiry(token, now: now);

      expect(days, isNotNull);
      expect(days!, closeTo(30, 0.01));
    });

    test('devuelve días < 7 cuando token está cerca de expirar', () {
      final now = DateTime.utc(2026, 5, 1, 12);
      final exp = now.add(const Duration(days: 5)).millisecondsSinceEpoch ~/ 1000;
      final token = _makeJwt({'exp': exp});

      final days = jwtDaysUntilExpiry(token, now: now);

      expect(days, isNotNull);
      expect(days!, lessThan(7));
      expect(days,  closeTo(5, 0.01));
    });

    test('devuelve negativo si ya expiró', () {
      final now = DateTime.utc(2026, 5, 1, 12);
      final exp = now.subtract(const Duration(days: 2)).millisecondsSinceEpoch ~/ 1000;
      final token = _makeJwt({'exp': exp});

      final days = jwtDaysUntilExpiry(token, now: now);

      expect(days, isNotNull);
      expect(days!, lessThan(0));
    });

    test('devuelve null si el payload no contiene exp', () {
      final token = _makeJwt({'userId': 'abc'});
      expect(jwtDaysUntilExpiry(token), isNull);
    });

    test('devuelve null si el token es inválido', () {
      expect(jwtDaysUntilExpiry('garbage'),       isNull);
      expect(jwtDaysUntilExpiry('only.two'),      isNull);
    });
  });
}
