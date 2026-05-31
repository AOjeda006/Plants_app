/// @file download_helper.dart
/// @description Helper para descargar archivos.
/// Usa conditional import: en web delega a dart:html, en otras plataformas es no-op.
/// @module Core
/// @layer Core
library;

export 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart';
