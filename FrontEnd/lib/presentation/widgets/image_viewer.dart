/// @file image_viewer.dart
/// @description Widget de visor de imágenes a pantalla completa.
/// Se abre como un dialog con fondo negro y permite zoom/pan con InteractiveViewer.
/// Reutilizable en PlantDetailPage, PostDetailPage y PostCard.
/// @module Core
/// @layer Presentation
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// FUNCIÓN DE APERTURA
// ═══════════════════════════════════════════════════════════════════════════════

/// Abre el visor de imagen a pantalla completa como un dialog.
///
/// [imageUrl] — URL de la imagen a mostrar.
void showFullScreenImage(BuildContext context, String imageUrl) {
  showDialog<void>(
    context:      context,
    barrierColor: Colors.black87,
    builder:      (_) => _FullScreenImageDialog(imageUrl: imageUrl),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// DIALOG INTERNO
// ═══════════════════════════════════════════════════════════════════════════════

class _FullScreenImageDialog extends StatelessWidget {
  const _FullScreenImageDialog({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor:  Colors.transparent,
        foregroundColor:  Colors.white,
        elevation:        0,
        leading: IconButton(
          icon:      const Icon(Icons.close_rounded),
          tooltip:   'Cerrar',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // Captura el tap fuera de la imagen para cerrar.
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            // Evita que el tap-pan del InteractiveViewer cierre el dialog.
            child: GestureDetector(
              onTap: () {}, // absorbe el tap para no propagar al padre
              child: CachedNetworkImage(
                imageUrl:    imageUrl,
                fit:         BoxFit.contain,
                placeholder: (_, _) => const CircularProgressIndicator(color: Colors.white),
                errorWidget: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size:  64,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
