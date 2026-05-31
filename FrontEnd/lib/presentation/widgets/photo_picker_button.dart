/// @file photo_picker_button.dart
/// @description Widget reutilizable para seleccionar una foto de galería o cámara.
/// Bifurca el comportamiento según la plataforma:
///  - Web: abre directamente el file picker del navegador (gallery).
///  - Móvil: muestra un BottomSheet con opciones "Galería" y "Cámara".
/// Devuelve los bytes y el nombre del archivo al callback [onFilePicked].
/// El caller es responsable de subir el archivo al backend.
/// @module Core
/// @layer Presentation
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PHOTO PICKER BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

/// Botón que encapsula la lógica de selección de imagen con bifurcación web/móvil.
///
/// Uso:
/// ```dart
/// PhotoPickerButton(
///   onFilePicked: (bytes, filename) async {
///     final url = await _uploadToBackend(bytes, filename);
///     vm.setPhoto(url);
///   },
///   child: const Icon(Icons.add_a_photo_outlined),
/// )
/// ```
///
/// [onFilePicked] se llama con los bytes y nombre del archivo seleccionado.
/// El widget no gestiona la subida ni el estado de carga.
class PhotoPickerButton extends StatelessWidget {
  const PhotoPickerButton({
    super.key,
    required this.onFilePicked,
    required this.child,
  });

  /// Callback invocado cuando el usuario selecciona una imagen.
  /// Recibe los bytes del archivo y su nombre (con extensión).
  final Future<void> Function(Uint8List bytes, String filename) onFilePicked;

  /// Widget visible que actúa como botón (icono, texto, contenedor, etc.).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: child,
    );
  }

  Future<void> _handleTap(BuildContext context) async {
    if (kIsWeb) {
      // En web el navegador gestiona el file picker — no necesita BottomSheet.
      await _pickImage(context, ImageSource.gallery);
    } else {
      // En móvil mostrar BottomSheet con opciones Galería / Cámara.
      if (!context.mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => _MobilePickerSheet(
          onGallery: () async {
            Navigator.of(ctx).pop();
            await _pickImage(context, ImageSource.gallery);
          },
          onCamera: () async {
            Navigator.of(ctx).pop();
            await _pickImage(context, ImageSource.camera);
          },
        ),
      );
    }
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source:       source,
      imageQuality: 80,
    );
    if (file == null) return;

    final bytes    = await file.readAsBytes();
    final filename = file.name.isNotEmpty ? file.name : 'photo.jpg';
    await onFilePicked(bytes, filename);
  }
}

// ─── BottomSheet móvil ────────────────────────────────────────────────────────

class _MobilePickerSheet extends StatelessWidget {
  const _MobilePickerSheet({
    required this.onGallery,
    required this.onCamera,
  });

  final VoidCallback onGallery;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:  const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title:    const Text('Galería'),
              onTap:    onGallery,
            ),
            ListTile(
              leading:  const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title:    const Text('Cámara'),
              onTap:    onCamera,
            ),
          ],
        ),
      ),
    );
  }
}
