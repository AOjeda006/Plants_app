/// @file viewport_detector_widget.dart
/// @description Widget que envuelve un hijo y detecta cuando es visible en el viewport.
/// Cuando el post es visible más del umbral configurado, invoca el callback [onSeen].
/// Se usa en el feed para registrar las métricas de visualización de posts.
/// @module Community
/// @layer Presentation
library;

import 'package:flutter/widgets.dart';

import '../../core/utils/view_port_detector.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// VIEWPORT DETECTOR WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

/// Envuelve un widget y llama a [onSeen] una sola vez cuando el hijo
/// alcanza el [visibilityThreshold] de visibilidad.
///
/// Una vez marcado como visto, no vuelve a invocar [onSeen] para el
/// mismo elemento (evitar duplicados en el servidor).
class ViewportDetectorWidget extends StatefulWidget {
  const ViewportDetectorWidget({
    super.key,
    required this.itemKey,
    required this.onSeen,
    required this.child,
    this.visibilityThreshold = 0.5,
  });

  /// Clave única del elemento (p.ej. ID del post).
  final String itemKey;

  /// Callback invocado una sola vez cuando el widget se considera "visto".
  final VoidCallback onSeen;

  /// Fracción mínima visible [0.0, 1.0] para considerar el widget "visto".
  final double visibilityThreshold;

  /// Widget a observar.
  final Widget child;

  @override
  State<ViewportDetectorWidget> createState() => _ViewportDetectorWidgetState();
}

class _ViewportDetectorWidgetState extends State<ViewportDetectorWidget> {
  bool _alreadySeen = false;

  @override
  Widget build(BuildContext context) {
    return ViewportDetector(
      detectorKey:         ValueKey(widget.itemKey),
      visibilityThreshold: widget.visibilityThreshold,
      onVisibilityChanged: _onVisibilityChanged,
      child:               widget.child,
    );
  }

  void _onVisibilityChanged(double fraction) {
    if (_alreadySeen) return;
    if (fraction >= widget.visibilityThreshold) {
      _alreadySeen = true;
      widget.onSeen();
    }
  }
}
