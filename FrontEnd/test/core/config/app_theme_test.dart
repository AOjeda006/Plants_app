/// @file app_theme_test.dart
/// @description Tests del tema de la app — verifica configuración de
/// NavigationBar (Material 3) usado en el BottomNav móvil.
/// Cubre la alineación vertical de iconos/labels y la consistencia de
/// colores entre destinos.
/// @module Core
/// @layer Core
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plants_app/core/config/app_theme.dart';

void main() {
  group('navigationBarTheme — alineación vertical de iconos', () {
    final theme = lightTheme();

    test('iconTheme.selected aporta size:26 (bounding box uniforme)', () {
      final iconData = theme.navigationBarTheme.iconTheme!
          .resolve({WidgetState.selected});
      expect(iconData, isNotNull);
      expect(iconData!.size, equals(26));
    });

    test('iconTheme.unselected aporta size:26 (bounding box uniforme)', () {
      final iconData = theme.navigationBarTheme.iconTheme!.resolve({});
      expect(iconData, isNotNull);
      expect(iconData!.size, equals(26));
    });

    test('iconTheme: selected y unselected tienen idéntico size (no salto vertical)', () {
      final selected   = theme.navigationBarTheme.iconTheme!
          .resolve({WidgetState.selected});
      final unselected = theme.navigationBarTheme.iconTheme!.resolve({});
      expect(selected!.size, equals(unselected!.size));
    });

    test('labelTextStyle: selected y unselected tienen idéntico fontSize', () {
      final selected   = theme.navigationBarTheme.labelTextStyle!
          .resolve({WidgetState.selected});
      final unselected = theme.navigationBarTheme.labelTextStyle!.resolve({});
      expect(selected!.fontSize, equals(unselected!.fontSize));
      expect(selected.fontSize, equals(12));
    });
  });

  group('navigationBarTheme — colores consistentes', () {
    final theme = lightTheme();

    test('iconTheme.selected usa AppColors.primary', () {
      final iconData = theme.navigationBarTheme.iconTheme!
          .resolve({WidgetState.selected});
      expect(iconData!.color, equals(AppColors.primary));
    });

    test('iconTheme.unselected usa AppColors.textSecondary', () {
      final iconData = theme.navigationBarTheme.iconTheme!.resolve({});
      expect(iconData!.color, equals(AppColors.textSecondary));
    });

    test('labelTextStyle.selected usa AppColors.primary y FontWeight.w600', () {
      final style = theme.navigationBarTheme.labelTextStyle!
          .resolve({WidgetState.selected});
      expect(style!.color,      equals(AppColors.primary));
      expect(style.fontWeight, equals(FontWeight.w600));
    });

    test('labelTextStyle.unselected usa AppColors.textSecondary', () {
      final style = theme.navigationBarTheme.labelTextStyle!.resolve({});
      expect(style!.color, equals(AppColors.textSecondary));
    });
  });
}
