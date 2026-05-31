/// @file main.dart
/// @description Punto de entrada de la aplicación Flutter.
/// Inicializa en orden: Hive, variables de entorno, contenedor DI, servicios async,
/// y luego arranca la UI con runApp(App()).
/// @module Core
/// @layer Core
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/config/app_theme.dart';
import 'core/config/env.dart';
import 'core/di/container.dart';
import 'core/services/firebase_messaging_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// BOOTSTRAP
// ═══════════════════════════════════════════════════════════════════════════════

Future<void> main() async {
  // Asegura que los bindings de Flutter estén inicializados antes de
  // llamar a cualquier plugin o plataforma nativa.
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge en Android para que el contenido se dibuje bajo la
  // system navigation bar (sin franja amarilla/negra residual en
  // landscape) y `SystemUiOverlayStyle` coherente con la paleta.
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: SystemUiOverlay.values,
  );
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor:           AppColors.surface,
    systemNavigationBarIconBrightness:  Brightness.dark,
    systemNavigationBarDividerColor:    AppColors.surface,
    statusBarColor:                     Colors.transparent,
    statusBarIconBrightness:            Brightness.dark,
  ));

  // 1. Inicializar Hive (almacenamiento local offline y caché).
  await Hive.initFlutter();

  // 2. Cargar variables de entorno desde .env e inicializar AppConfig.
  await Env.initialize();

  // 3. Registrar todas las dependencias en el contenedor get_it.
  await configureDependencies();

  // 4. Inicializar datos de localización para DateFormat (intl).
  await initializeDateFormatting('es_ES', null);

  // 5. Inicializar servicios que requieren async (Hive boxes, conectividad, cola).
  await initializeServices();

  // 6. Inicializar Firebase y notificaciones push.
  // TFG: requiere google-services.json (Android) y GoogleService-Info.plist (iOS),
  // ambos generados por `flutterfire configure`. En Android, `Firebase
  // .initializeApp()` lee automáticamente google-services.json desde
  // android/app/. Para iOS o web, `flutterfire configure` actualizará este
  // bloque añadiendo `import 'firebase_options.dart'` y pasando
  // `options: DefaultFirebaseOptions.currentPlatform` aquí.
  // Si los archivos no están presentes (entorno de desarrollo recién clonado),
  // la app arranca igualmente sin push gracias al try/catch.
  // El servicio se obtiene del container (registrado como singleton) para
  // que MainTabsPage.initState pueda recuperar la misma instancia.
  try {
    await Firebase.initializeApp();
    await sl<FirebaseMessagingService>().initialize();
  } catch (_) {
    // Firebase no configurado — continuar sin notificaciones push.
  }

  // 7. Arrancar la UI.
  runApp(const App());
}
