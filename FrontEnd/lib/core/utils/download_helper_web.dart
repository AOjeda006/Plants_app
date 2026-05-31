/// @file download_helper_web.dart
/// @description Implementación web del helper de descarga usando package:web + dart:js_interop.
/// Crea un Blob con el contenido y dispara la descarga mediante un AnchorElement.
/// @module Core
/// @layer Core
library;

import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Descarga [content] como un archivo [filename] en el navegador.
void downloadTextFile(String content, String filename) {
  // Crear Blob con el contenido JSON
  final blob = web.Blob(
    [content.toJS].toJS,
    web.BlobPropertyBag(type: 'application/json'),
  );

  final url    = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href     = url
    ..download = filename;

  // Añadir al DOM, disparar clic y limpiar
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
