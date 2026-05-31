/// @file api_client_test.dart
/// @description Tests de ApiClient. Verifica la constante pública
/// [kShortReceiveTimeout] = 30s, exportada para call sites que quieran
/// timeout más corto que el default (60s) — caso típico: /auth/refresh.
/// @module Core
/// @layer Core
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:plants_app/core/config/app_config.dart';
import 'package:plants_app/core/network/api_client.dart';

void main() {
  setUpAll(() {
    // ApiClient lee AppConfig.instance.apiBaseUrl en su constructor.
    AppConfig.initialize(const AppConfig(
      apiBaseUrl:             'https://example.test',
      socketUrl:              'https://example.test',
      weatherCacheTtlSeconds: 300,
      weatherWindowHours:     48,
      mockWeatherMode:        true,
      cloudinaryUploadPreset: 'test',
      fcmEnabled:             false,
      isProduction:           false,
      defaultLocale:          'es',
    ));
  });

  group('ApiClient timeouts', () {
    test('kShortReceiveTimeout es 30 segundos (para /auth/refresh)', () {
      expect(kShortReceiveTimeout, const Duration(seconds: 30));
    });

    test('construye sin errores con tokenProvider', () {
      final client = ApiClient(tokenProvider: () async => null);
      expect(client, isNotNull);
    });
  });
}
