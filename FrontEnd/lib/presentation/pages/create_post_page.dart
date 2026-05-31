/// @file create_post_page.dart
/// @description Pantalla para crear un nuevo post en la comunidad.
/// Permite escribir texto y adjuntar una imagen (subida previamente a Cloudinary).
/// Devuelve `true` al hacer pop si el post se creó con éxito, para que el feed refresque.
/// @module Community
/// @layer Presentation
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/config/app_theme.dart';
import '../../core/di/container.dart';
import '../../core/errors/app_error.dart';
import '../../core/network/api_client.dart';
import '../../domain/dtos/community/create_post_request_dto.dart';
import '../../domain/interfaces/usecases/community/i_create_post_use_case.dart';
import '../widgets/photo_picker_button.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CREATE POST PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Pantalla de creación de un post en la comunidad.
///
/// Flujo de imagen:
///  1. Usuario selecciona imagen de galería/cámara.
///  2. Se sube a Cloudinary via POST /upload/image (ApiClient.uploadImage).
///  3. Se obtiene la URL y se adjunta al DTO final.
///  4. Se llama a ICreatePostUseCase con el DTO completo.
///  5. Devuelve `Navigator.pop(true)` para que el feed recargue.
class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _contentCtrl  = TextEditingController();
  final ICreatePostUseCase    _createPostUc = sl<ICreatePostUseCase>();
  final ApiClient             _api          = sl<ApiClient>();

  Uint8List? _selectedImageBytes;
  String?    _uploadedImageUrl;
  bool       _isUploadingImage = false;
  double     _uploadProgress   = 0;
  bool       _isCreating       = false;
  String?    _errorMessage;

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Nueva publicación'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: (_isCreating || _isUploadingImage) ? null : _submitPost,
              child: _isCreating
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2,
                      ),
                    )
                  : const Text('Publicar', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) _ErrorBanner(message: _errorMessage!),
            TextField(
              controller:      _contentCtrl,
              maxLines:        null,
              minLines:        5,
              maxLength:       1000,
              // Texto y cursor blancos: el campo usa fillColor oscuro (primary)
              // para que el contraste sea correcto en todos los dispositivos.
              style: const TextStyle(
                color:    Colors.white,
                fontSize: 16,
              ),
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                hintText:  '¿Qué quieres compartir con la comunidad?',
                hintStyle: TextStyle(color: Colors.white70),
                border:    InputBorder.none,
                filled:    true,
                fillColor: AppColors.primary,
              ),
            ),
            const Divider(),
            const SizedBox(height: 12),
            _ImageSection(
              selectedImage:    _selectedImageBytes,
              isUploadingImage: _isUploadingImage,
              uploadProgress:   _uploadProgress,
              onFilePicked:     _onFilePicked,
              onRemove:         _removeImage,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Seleccionar y subir imagen ───────────────────────────────────────────

  /// Callback de [PhotoPickerButton]: recibe bytes + nombre y sube a Cloudinary.
  Future<void> _onFilePicked(Uint8List bytes, String filename) async {
    setState(() {
      _selectedImageBytes = bytes;
      _uploadedImageUrl   = null;
      _isUploadingImage   = true;
      _uploadProgress     = 0;
      _errorMessage       = null;
    });

    try {
      final response = await _api.uploadImage<Map<String, dynamic>>(
        '/upload/image',
        bytes,
        filename,
        onProgress: (p) => setState(() => _uploadProgress = p),
      );
      setState(() {
        _uploadedImageUrl = response['url'] as String?;
        _isUploadingImage = false;
      });
    } on AppError {
      setState(() {
        _selectedImageBytes = null;
        _isUploadingImage   = false;
        _errorMessage       = 'Error al subir la imagen. Inténtalo de nuevo.';
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageBytes = null;
      _uploadedImageUrl   = null;
      _isUploadingImage = false;
      _uploadProgress   = 0;
    });
  }

  // ─── Publicar post ─────────────────────────────────────────────────────────

  Future<void> _submitPost() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty && _uploadedImageUrl == null) {
      setState(() => _errorMessage = 'Escribe algo o añade una imagen.');
      return;
    }
    if (_isUploadingImage) return;

    setState(() {
      _isCreating   = true;
      _errorMessage = null;
    });

    try {
      await _createPostUc.execute(
        CreatePostRequestDto(content: content, imageUrl: _uploadedImageUrl),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on AppError catch (e) {
      setState(() {
        _isCreating   = false;
        _errorMessage = e.message;
      });
    }
  }
}

// ─── Sección de imagen ────────────────────────────────────────────────────────

class _ImageSection extends StatelessWidget {
  const _ImageSection({
    required this.selectedImage,
    required this.isUploadingImage,
    required this.uploadProgress,
    required this.onFilePicked,
    required this.onRemove,
  });

  final Uint8List?   selectedImage;
  final bool         isUploadingImage;
  final double       uploadProgress;
  final Future<void> Function(Uint8List bytes, String filename) onFilePicked;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (selectedImage != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              selectedImage!,
              fit:    BoxFit.cover,
              width:  double.infinity,
              height: 220,
            ),
          ),
          if (isUploadingImage)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color:        Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: uploadProgress > 0 ? uploadProgress : null,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Subiendo… ${(uploadProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          if (!isUploadingImage)
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding:    const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
        ],
      );
    }

    // Sin imagen: botón único con bifurcación web/móvil via PhotoPickerButton.
    return PhotoPickerButton(
      onFilePicked: onFilePicked,
      child: Container(
        padding:    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border:       Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Añadir foto', style: TextStyle(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}

// ─── Banner de error ──────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
