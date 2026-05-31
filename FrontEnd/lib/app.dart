/// @file app.dart
/// @description Widget raíz de la aplicación.
/// Configura MaterialApp con los temas corporativos (lightTheme/darkTheme),
/// MultiProvider para los ViewModels globales y AppRouter para la navegación.
///
/// El `MultiProvider` se monta en una capa indexada por
/// [_providerGeneration] (un `ValueNotifier<int>`). El logout invoca
/// [appProviderGeneration].value++ — esto fuerza la reconstrucción del
/// MultiProvider con instancias frescas de los ViewModels (en particular
/// `AuthViewModel`), evitando que datos de la cuenta anterior queden
/// visibles en pestañas tras un cambio de sesión.
/// @module Core
/// @layer Core
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/config/app_theme.dart';
import 'core/di/container.dart';
import 'l10n/app_localizations.dart';
import 'presentation/routes/app_router.dart';
import 'presentation/viewmodels/auth/auth_viewmodel.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// NAVIGATOR KEY GLOBAL
// ═══════════════════════════════════════════════════════════════════════════════

/// Clave global del Navigator de la app.
/// Permite navegar desde fuera del árbol de widgets (ej. notificaciones push).
/// Pasada a [MaterialApp.navigatorKey] y usada por [FirebaseMessagingService].
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDER GENERATION — usado por LogoutFlow para reconstruir el árbol Provider
// ═══════════════════════════════════════════════════════════════════════════════

/// Contador de "generación" del árbol de Providers. Incrementarlo fuerza al
/// `MultiProvider` a recrearse con instancias nuevas de los ViewModels.
///
/// Uso típico tras un logout:
/// ```dart
/// await sl<ILogoutUseCase>().execute();
/// appProviderGeneration.value++;   // descarta AuthViewModel anterior
/// Navigator.of(context, rootNavigator: true)
///   .pushNamedAndRemoveUntil('/login', (route) => false);
/// ```
final ValueNotifier<int> appProviderGeneration = ValueNotifier<int>(0);

// ═══════════════════════════════════════════════════════════════════════════════
// APP
// ═══════════════════════════════════════════════════════════════════════════════

/// Widget raíz de la app de gestión de plantas.
///
/// Responsabilidades:
///  - Aplica los temas corporativos (light/dark) definidos en [AppColors].
///  - Envuelve el árbol con [MultiProvider] para los ViewModels globales.
///  - Configura [AppRouter] como fuente de rutas nombradas.
///  - Expone [appNavigatorKey] para deep linking desde notificaciones push.
///  - Escucha [appProviderGeneration] para reconstruir el árbol de Providers
///    tras logout para descartar el árbol heredado.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: appProviderGeneration,
      builder: (context, generation, _) {
        return MultiProvider(
          // La clave cambia cada vez que se incrementa la generación —
          // descarta el árbol anterior y crea ViewModels nuevos.
          key: ValueKey('providers_$generation'),
          providers: [
            // AuthViewModel disponible en todo el árbol de widgets.
            ChangeNotifierProvider<AuthViewModel>(
              create: (_) => sl<AuthViewModel>(),
            ),
          ],
          child: MaterialApp(
            title:                     'Plants App',
            onGenerateTitle:           (ctx) => AppLocalizations.of(ctx).appTitle,
            debugShowCheckedModeBanner: false,
            navigatorKey:              appNavigatorKey,
            theme:                     lightTheme(),
            darkTheme:                 darkTheme(),
            themeMode:                 ThemeMode.system,
            locale:                    const Locale('es'),
            supportedLocales: const [
              Locale('es'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute:              AppRouter.initialRoute,
            routes:                    AppRouter.routes,
            onGenerateRoute:           AppRouter.onGenerateRoute,
            onUnknownRoute:            AppRouter.onUnknownRoute,
          ),
        );
      },
    );
  }
}
