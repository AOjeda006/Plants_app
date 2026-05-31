/// @file splash_page.dart
/// @description Pantalla de splash. Verifica la sesión del usuario al arrancar.
/// Si hay token válido redirige al home; si no, redirige al login.
/// Se muestra mientras AuthViewModel.checkSession() está en curso.
///
/// Cold start: el backend está desplegado en Render Free Tier, que suspende
/// el contenedor tras 15 min sin tráfico. La primera petición del día puede
/// tardar ~40s. Para no dejar al usuario solo con un spinner, mostramos
/// mensajes contextuales a los 3s y 25s.
///
/// Watchdog de seguridad: si checkSession no termina en 90 s absolutos,
/// pasamos a una pantalla de error explícita ("No se pudo conectar con
/// el servidor") para que el usuario pueda decidir entre reintentar o
/// continuar con el token actual. Sin esta salvaguarda, un cold start de
/// Render más largo de lo previsto dejaba el spinner infinito.
/// @module Core
/// @layer Presentation
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_theme.dart';
import '../../core/di/container.dart';
import '../../core/storage/auth_local_data_source.dart';
import '../viewmodels/auth/auth_viewmodel.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SPLASH PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Pantalla inicial de la app. Inicia la verificación de sesión y redirige.
///
/// Ciclo de vida:
///  1. initState → llama a AuthViewModel.checkSession().
///  2. AuthViewModel notifica cambio → SplashPage navega.
///  3. Tres estados internos:
///     - [_SplashState.loading] → spinner + ColdStartIndicator (default).
///     - [_SplashState.error]   → pantalla de error con "Reintentar" y
///                                 "Continuar sin conexión".
///     - [_SplashState.ready]   → navegación inmediata, sin renderizar.
///  4. Watchdog absoluto a 90 s: si checkSession no termina, forzar
///     navegación con el token actual (Home si existe, Login si no).
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

/// Estados visuales internos de la pantalla. Distintos del [AuthStatus]
/// del ViewModel: aquí solo nos importa qué dibujar.
enum _SplashState { loading, error }

class _SplashPageState extends State<SplashPage> {
  /// Mensaje contextual mostrado durante el cold start. Null mientras la
  /// petición tarda < 3 s; cambia en dos peldaños (3 s y 25 s).
  String? _coldStartMessage;
  Timer?  _coldStartTimer;
  Timer?  _coldStartLongTimer;
  Timer?  _watchdogTimer;

  /// Estado visual de la página. Empieza en loading; pasa a error solo
  /// si el watchdog dispara o checkSession lanza un error no-auth
  /// persistente que merece pantalla explícita.
  _SplashState _state = _SplashState.loading;

  /// Marcamos para no navegar dos veces (watchdog vs checkSession
  /// terminando casi a la vez).
  bool _navigated = false;

  /// Ventana absoluta antes de forzar navegación con el token actual.
  /// 90 s = 60 s de timeout HTTP del ApiClient + 30 s de margen para
  /// cualquier overhead (interceptores, parseo, retry una sola vez).
  static const Duration _watchdog = Duration(seconds: 90);

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  /// Lanza checkSession + arma los timers (cold start + watchdog).
  /// Reutilizable desde el botón "Reintentar" de la pantalla de error.
  void _startSession() {
    setState(() => _state = _SplashState.loading);

    // Verificar sesión tras el primer frame para que el árbol esté construido.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSession());

    // Timers para mensajes de cold start. Se cancelan en dispose() o si la
    // petición termina antes de dispararlos. Primer mensaje a 3 s
    // (conservador para dar feedback temprano al usuario tras un cold start
    // largo).
    _coldStartTimer?.cancel();
    _coldStartLongTimer?.cancel();
    _watchdogTimer?.cancel();
    _coldStartMessage = null;

    _coldStartTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _coldStartMessage =
            '🌱 Despertando el servidor... Esto puede tardar hasta un minuto la primera vez del día.';
      });
    });
    _coldStartLongTimer = Timer(const Duration(seconds: 25), () {
      if (!mounted) return;
      setState(() {
        _coldStartMessage = 'Casi listo, gracias por la paciencia.';
      });
    });

    // Watchdog: si checkSession sigue corriendo a los 90 s, lo
    // adelantamos forzando la navegación. No cancela checkSession (no
    // es trivial cancelar un Future Dart sin Completer manual); deja
    // que termine en segundo plano y solo evita el spinner infinito.
    _watchdogTimer = Timer(_watchdog, _onWatchdogFire);
  }

  Future<void> _onWatchdogFire() async {
    if (!mounted || _navigated) return;
    debugPrint('[SplashPage] watchdog fired — switching to error screen');
    // En lugar de navegar silenciosamente, mostramos la pantalla de error
    // explícita para que el usuario sepa que hubo un problema y pueda
    // decidir "Reintentar" o "Continuar sin conexión". Cancelamos los
    // timers porque ya estamos en estado terminal hasta que el usuario
    // interactúe.
    _coldStartTimer?.cancel();
    _coldStartLongTimer?.cancel();
    setState(() => _state = _SplashState.error);
  }

  /// Navega a Home si hay token cacheado en SecureStorage; a Login si no.
  /// Usado por el watchdog y por el botón "Continuar sin conexión".
  Future<void> _forceNavigateWithCurrentToken() async {
    if (!mounted || _navigated) return;
    String? token;
    try {
      token = await sl<AuthLocalDataSource>().getAccessToken();
    } catch (_) {
      token = null;
    }
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacementNamed(
      (token != null && token.isNotEmpty) ? '/home' : '/login',
    );
  }

  @override
  void dispose() {
    _coldStartTimer?.cancel();
    _coldStartLongTimer?.cancel();
    _watchdogTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkSession() async {
    final vm = context.read<AuthViewModel>();
    try {
      await vm.checkSession();
    } catch (e) {
      debugPrint('[SplashPage] checkSession threw unexpectedly: $e');
    } finally {
      // Cancelar timers en cuanto checkSession termina, gane o pierda
      // la carrera con el watchdog.
      _coldStartTimer?.cancel();
      _coldStartLongTimer?.cancel();
      _watchdogTimer?.cancel();
    }

    if (!mounted || _navigated) return;
    _navigated = true;

    if (vm.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: switch (_state) {
          _SplashState.loading => _buildLoading(context),
          _SplashState.error   => _buildError(context),
        },
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo corporativo de la app (assets/images/logo.png).
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/images/logo.png',
              width:  100,
              height: 100,
              fit:    BoxFit.cover,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Plants App',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color:      AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 48),
          const CircularProgressIndicator(
            color:       AppColors.primary,
            strokeWidth: 2.5,
          ),
          // Reservamos espacio para el mensaje de cold start aunque no se
          // muestre, para evitar saltos en el layout cuando aparece.
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _coldStartMessage == null
                ? const SizedBox.shrink(key: ValueKey('cold_start_empty'))
                : Padding(
                    key:     const ValueKey('cold_start_msg'),
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _coldStartMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color:      AppColors.textSecondary,
                        fontSize:   13,
                        fontWeight: FontWeight.w500,
                        height:     1.35,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off,
              size:  72,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 24),
            Text(
              'No se pudo conectar con el servidor',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color:      AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'El servicio puede estar despertando o no tener conexión. '
              'Inténtalo de nuevo en unos segundos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:    AppColors.textSecondary,
                fontSize: 14,
                height:   1.4,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              key:    const ValueKey('splash_retry_button'),
              icon:   const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              onPressed: () {
                _navigated = false;
                _startSession();
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              key:       const ValueKey('splash_offline_button'),
              onPressed: _forceNavigateWithCurrentToken,
              child:     const Text('Continuar sin conexión'),
            ),
          ],
        ),
      ),
    );
  }
}
