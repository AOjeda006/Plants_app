/// @file view_port_detector.dart
/// @description Utilidad para detectar si un widget es visible en el viewport.
/// Proporciona un callback cuando un elemento entra o sale del área visible.
/// Se usa para registrar métricas de visualización de posts (seenBy).
/// @module Community
/// @layer Core
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// VISIBILITY CALLBACK TYPE
// ═══════════════════════════════════════════════════════════════════════════════

/// Callback que recibe el porcentaje de visibilidad del widget [0.0, 1.0].
typedef VisibilityCallback = void Function(double visibilityFraction);

// ═══════════════════════════════════════════════════════════════════════════════
// VIEWPORT DETECTOR
// ═══════════════════════════════════════════════════════════════════════════════

/// Detecta cuándo un widget entra o sale del viewport del scroll.
///
/// Usa [VisibilityDetectorKey] para identificar el widget y llama a
/// [onVisibilityChanged] con la fracción visible [0.0, 1.0].
///
/// Uso típico: envolver un [PostCard] para registrar que el usuario lo vio.
class ViewportDetector extends StatefulWidget {
  const ViewportDetector({
    super.key,
    required this.detectorKey,
    required this.onVisibilityChanged,
    required this.child,
    this.visibilityThreshold = 0.5,
  });

  /// Clave única que identifica este detector (normalmente el ID del post).
  final Key detectorKey;

  /// Callback invocado cuando la visibilidad cambia respecto al umbral.
  final VisibilityCallback onVisibilityChanged;

  /// Fracción mínima visible [0.0, 1.0] para considerar el widget "visto".
  /// Por defecto 0.5 (50% visible).
  final double visibilityThreshold;

  /// Widget hijo a observar.
  final Widget child;

  @override
  State<ViewportDetector> createState() => _ViewportDetectorState();
}

class _ViewportDetectorState extends State<ViewportDetector> {
  bool _wasVisible = false;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (_) {
        _checkVisibility();
        return false; // No absorber la notificación.
      },
      child: _VisibilityWidget(
        detectorKey:         widget.detectorKey,
        onVisibilityChanged: widget.onVisibilityChanged,
        visibilityThreshold: widget.visibilityThreshold,
        wasVisible:          _wasVisible,
        onWasVisibleChanged: (v) => _wasVisible = v,
        child:               widget.child,
      ),
    );
  }

  void _checkVisibility() {
    final renderObject = context.findRenderObject();
    if (renderObject == null || !renderObject.attached) return;

    final viewport = RenderAbstractViewport.of(renderObject);
    final offset   = renderObject.getTransformTo(null).getTranslation();
    final size     = renderObject.paintBounds.size;

    // Calcular fracción visible dentro del viewport.
    final vpSize   = viewport.paintBounds.size;
    final topInVp  = offset.y;
    final botInVp  = offset.y + size.height;
    final visible  = (botInVp.clamp(0, vpSize.height) - topInVp.clamp(0, vpSize.height))
        .clamp(0, size.height);
    final fraction = size.height > 0 ? visible / size.height : 0.0;

    widget.onVisibilityChanged(fraction);
  }
}

// ─── Widget interno de visibilidad ────────────────────────────────────────────

class _VisibilityWidget extends StatelessWidget {
  const _VisibilityWidget({
    required this.detectorKey,
    required this.onVisibilityChanged,
    required this.visibilityThreshold,
    required this.wasVisible,
    required this.onWasVisibleChanged,
    required this.child,
  });

  final Key                       detectorKey;
  final VisibilityCallback        onVisibilityChanged;
  final double                    visibilityThreshold;
  final bool                      wasVisible;
  final ValueChanged<bool>        onWasVisibleChanged;
  final Widget                    child;

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: detectorKey,
    child: child,
  );
}
