/// @file app_localizations_test.dart
/// @description Tests del esqueleto de internacionalización (AppLocalizations).
/// Verifica que las strings devueltas coinciden con la plantilla ARB en es y en.
/// @module Core
/// @layer Core
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plants_app/l10n/app_localizations.dart';
import 'package:plants_app/l10n/app_localizations_en.dart';
import 'package:plants_app/l10n/app_localizations_es.dart';

void main() {
  group('AppLocalizations - español (es)', () {
    final AppLocalizations l10n = AppLocalizationsEs();

    test('tabs traducidos al español', () {
      expect(l10n.tabPlants, 'Plantas');
      expect(l10n.tabCommunity, 'Comunidad');
      expect(l10n.tabMessages, 'Mensajes');
      expect(l10n.tabNotifications, 'Avisos');
      expect(l10n.tabCalendar, 'Calendario');
      expect(l10n.tabProfile, 'Perfil');
    });

    test('appTitle se mantiene como Plants App', () {
      expect(l10n.appTitle, 'Plants App');
    });

    test('acciones genéricas en español', () {
      expect(l10n.actionRetry, 'Reintentar');
      expect(l10n.actionCancel, 'Cancelar');
      expect(l10n.actionSave, 'Guardar');
      expect(l10n.actionDelete, 'Eliminar');
      expect(l10n.actionConfirm, 'Confirmar');
    });

    test('mensajes de error en español', () {
      expect(l10n.errorNetwork, contains('conexión'));
      expect(l10n.errorUnauthorized.toLowerCase(), contains('sesi'));
      expect(l10n.errorNotFound.toLowerCase(), contains('no existe'));
      expect(l10n.errorServer.toLowerCase(), contains('servidor'));
      expect(l10n.errorUnexpected.toLowerCase(), contains('error'));
    });
  });

  group('AppLocalizations - inglés (en)', () {
    final AppLocalizations l10n = AppLocalizationsEn();

    test('tabs traducidos al inglés', () {
      expect(l10n.tabPlants, 'Plants');
      expect(l10n.tabCommunity, 'Community');
      expect(l10n.tabMessages, 'Messages');
      expect(l10n.tabNotifications, 'Notifications');
      expect(l10n.tabCalendar, 'Calendar');
      expect(l10n.tabProfile, 'Profile');
    });

    test('appTitle no se traduce (marca de la app)', () {
      expect(l10n.appTitle, 'Plants App');
    });
  });

  group('AppLocalizations.delegate', () {
    test('soporta es y en, no soporta locales no listados', () {
      expect(AppLocalizations.delegate.isSupported(const Locale('es')), isTrue);
      expect(AppLocalizations.delegate.isSupported(const Locale('en')), isTrue);
      expect(AppLocalizations.delegate.isSupported(const Locale('fr')), isFalse);
    });
  });
}
