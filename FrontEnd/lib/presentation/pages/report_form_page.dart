/// @file report_form_page.dart
/// @description Formulario para que cualquier usuario autenticado envíe un
/// reporte de incidencia al equipo de administración.
/// @module Admin
/// @layer Presentation
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/config/app_theme.dart';
import '../../core/di/container.dart';
import '../../core/network/api_client.dart';
import '../../data/datasources/remote/admin_remote_data_source.dart';
import '../widgets/photo_picker_button.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// REPORT FORM PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Pantalla de envío de reporte de incidencia.
///
/// [targetId] — ID del post o comentario reportado (opcional).
/// [type]     — Tipo de reporte: 'general' | 'post' | 'comment' (default: 'general').
class ReportFormPage extends StatefulWidget {
  const ReportFormPage({super.key, this.targetId, this.type});

  final String? targetId;
  final String? type;

  @override
  State<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends State<ReportFormPage> {
  final _formKey       = GlobalKey<FormState>();
  final _textCtrl      = TextEditingController();
  final _dataSource    = sl<AdminRemoteDataSource>();
  final _api           = sl<ApiClient>();

  Uint8List? _imageBytes;
  String?    _uploadedImageUrl;
  bool       _isUploadingImage = false;
  bool       _isSubmitting     = false;
  String?    _errorMessage;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  // ─── Imagen ───────────────────────────────────────────────────────────────

  Future<void> _onImagePicked(Uint8List bytes, String filename) async {
    setState(() {
      _imageBytes          = bytes;
      _isUploadingImage    = true;
      _uploadedImageUrl    = null;
    });

    try {
      final url = await _api.uploadImage<Map<String, dynamic>>(
        '/upload/image',
        bytes,
        filename,
      );
      setState(() => _uploadedImageUrl = url['url'] as String?);
    } catch (_) {
      setState(() {
        _imageBytes       = null;
        _uploadedImageUrl = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo subir la imagen')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _removeImage() {
    setState(() {
      _imageBytes       = null;
      _uploadedImageUrl = null;
    });
  }

  // ─── Envío ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isUploadingImage) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _dataSource.createReport(
        text:     _textCtrl.text.trim(),
        type:     widget.type ?? 'general',
        targetId: widget.targetId,
        imageUrl: _uploadedImageUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte enviado. Gracias por tu ayuda.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Reportar incidencia'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Descripción
              const Text(
                'Describe el problema que has encontrado',
                style: TextStyle(
                  color:      AppColors.textPrimary,
                  fontSize:   14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller:   _textCtrl,
                maxLines:     5,
                maxLength:    1000,
                keyboardType: TextInputType.multiline,
                decoration:   const InputDecoration(
                  hintText:    'Ej. Al abrir la sección de plantas la app se cierra...',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'La descripción es obligatoria' : null,
              ),
              const SizedBox(height: 20),

              // Imagen opcional
              const Text(
                'Imagen adjunta (opcional)',
                style: TextStyle(
                  color:      AppColors.textPrimary,
                  fontSize:   14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              _ImagePicker(
                imageBytes:      _imageBytes,
                isUploading:     _isUploadingImage,
                uploadedUrl:     _uploadedImageUrl,
                onPicked:        _onImagePicked,
                onRemove:        _removeImage,
              ),
              const SizedBox(height: 24),

              // Error
              if (_errorMessage != null) ...[
                Container(
                  padding:    const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:        AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Botón enviar
              FilledButton(
                onPressed: (_isSubmitting || _isUploadingImage) ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:         const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Enviar reporte', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Selector de imagen ───────────────────────────────────────────────────────

class _ImagePicker extends StatelessWidget {
  const _ImagePicker({
    required this.imageBytes,
    required this.isUploading,
    required this.uploadedUrl,
    required this.onPicked,
    required this.onRemove,
  });

  final Uint8List?                               imageBytes;
  final bool                                     isUploading;
  final String?                                  uploadedUrl;
  final Future<void> Function(Uint8List, String) onPicked;
  final VoidCallback                             onRemove;

  @override
  Widget build(BuildContext context) {
    if (imageBytes != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              imageBytes!,
              height: 160,
              width:  double.infinity,
              fit:    BoxFit.cover,
            ),
          ),
          if (isUploading)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black38,
                child: Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
            ),
          if (!isUploading)
            Positioned(
              top:   6,
              right: 6,
              child: GestureDetector(
                onTap: onRemove,
                child: const CircleAvatar(
                  radius:          14,
                  backgroundColor: Colors.black54,
                  child:           Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
        ],
      );
    }

    return PhotoPickerButton(
      onFilePicked: onPicked,
      child: Container(
        height:     100,
        decoration: BoxDecoration(
          color:        AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 32),
              SizedBox(height: 6),
              Text(
                'Añadir imagen',
                style: TextStyle(color: AppColors.primary, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
