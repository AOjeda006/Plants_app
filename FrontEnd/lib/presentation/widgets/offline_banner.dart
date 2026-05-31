/// @file offline_banner.dart
/// @description Banner de estado offline que se muestra automáticamente
/// cuando el dispositivo pierde la conexión a internet.
/// Escucha [ConnectivityService.onConnectivityChanged] y se oculta al reconectar.
///
/// El banner no refleja ninguna cola offline: el texto es fijo
/// "Sin conexión · Modo offline". Las acciones del usuario sin red
/// propagan `AppError` y la UI las muestra como Snackbar.
/// @module Core
/// @layer Presentation
library;

import 'package:flutter/material.dart';

import '../../core/config/app_theme.dart';
import '../../core/di/container.dart';
import '../../core/utils/connectivity/connectivity_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// OFFLINE BANNER
// ═══════════════════════════════════════════════════════════════════════════════

/// Banner reactivo que muestra el estado de conectividad.
///
/// Uso:
/// ```dart
/// Column(
///   children: [
///     const OfflineBanner(),
///     Expanded(child: _content),
///   ],
/// )
/// ```
///
/// Se contrae automáticamente cuando la conexión se restaura.
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  late final ConnectivityService _connectivity;

  @override
  void initState() {
    super.initState();
    _connectivity = sl<ConnectivityService>();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream:       _connectivity.onConnectivityChanged,
      initialData:  _connectivity.isOnline(),
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            child:      child,
          ),
          child: isOnline
              ? const SizedBox.shrink(key: ValueKey('online'))
              : const _OfflineBannerContent(key: ValueKey('offline')),
        );
      },
    );
  }
}

// ─── Contenido del banner ─────────────────────────────────────────────────────

class _OfflineBannerContent extends StatelessWidget {
  const _OfflineBannerContent({super.key});

  static const String _label = 'Sin conexión · Modo offline';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _label,
      child: Container(
        width:   double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color:   AppColors.warning.withAlpha(38),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.wifi_off_rounded, size: 15, color: AppColors.warning),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                _label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:      AppColors.textPrimary,
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RECONNECTED BANNER
// ═══════════════════════════════════════════════════════════════════════════════

/// Toast/banner temporal que aparece al recuperar la conexión.
///
/// Se muestra mediante [ReconnectedBanner.show] desde un listener de
/// connectivity (típicamente en `MainTabsPage`). El toast es solo
/// informativo "Conexión restaurada" sin métricas adicionales.
class ReconnectedBanner {
  /// Muestra un SnackBar de reconexión durante 3 segundos.
  static void show(BuildContext context) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          behavior:        SnackBarBehavior.floating,
          duration:        const Duration(seconds: 3),
          margin:          const EdgeInsets.all(12),
          shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: const [
              Icon(Icons.wifi_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Conexión restaurada',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
