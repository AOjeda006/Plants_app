/// @file edit_profile_page.dart
/// @description Pantalla de edición del perfil del usuario.
/// Permite cambiar nombre, bio y ubicación.
/// @module User
/// @layer Presentation
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_theme.dart';
import '../../core/di/container.dart';
import '../../core/errors/app_error.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/location.dart';
import '../../domain/entities/user.dart';
import '../viewmodels/profile/edit_profile_viewmodel.dart';
import '../widgets/photo_picker_button.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// EDIT PROFILE PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Pantalla de edición de perfil. Argumento de ruta: [User] usuario actual.
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditProfileViewModel>(
      create: (_) => sl<EditProfileViewModel>()..initFromUser(user),
      child: const _EditProfileContent(),
    );
  }
}

// ─── Contenido principal ──────────────────────────────────────────────────────

class _EditProfileContent extends StatefulWidget {
  const _EditProfileContent();

  @override
  State<_EditProfileContent> createState() => _EditProfileContentState();
}

class _EditProfileContentState extends State<_EditProfileContent> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;

  @override
  void initState() {
    super.initState();
    final vm = context.read<EditProfileViewModel>();
    _nameCtrl = TextEditingController(text: vm.name);
    _bioCtrl  = TextEditingController(text: vm.bio);
  }

  /// Sube la foto de perfil y aplica la URL resultante al ViewModel.
  Future<void> _uploadAndSetPhoto(Uint8List bytes, String filename) async {
    final vm = context.read<EditProfileViewModel>();
    vm.setUploadingPhoto(true);
    try {
      final result = await sl<ApiClient>().uploadImage<Map<String, dynamic>>(
        '/upload/image',
        bytes,
        filename,
        fieldName: 'image',
      );
      if (!mounted) return;
      final url = result['url'] as String?;
      if (url != null) vm.setPhoto(url);
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) vm.setUploadingPhoto(false);
    }
  }

  /// Sube el banner y aplica la URL resultante al ViewModel.
  Future<void> _uploadAndSetBanner(Uint8List bytes, String filename) async {
    final vm = context.read<EditProfileViewModel>();
    vm.setUploadingBanner(true);
    try {
      final result = await sl<ApiClient>().uploadImage<Map<String, dynamic>>(
        '/upload/image',
        bytes,
        filename,
        fieldName: 'image',
      );
      if (!mounted) return;
      final url = result['url'] as String?;
      if (url != null) vm.setBannerPhoto(url);
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) vm.setUploadingBanner(false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.select<EditProfileViewModel, bool>((vm) => vm.isSaving);
    final error    = context.select<EditProfileViewModel, AppError?>((vm) => vm.error);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Editar perfil'),
        actions: [
          TextButton(
            onPressed: isSaving ? null : _save,
            child: isSaving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Banner editable (fondo de perfil).
          _BannerPicker(onFilePicked: _uploadAndSetBanner),
          // Avatar con botón de cámara, solapado sobre el banner.
          Transform.translate(
            offset: const Offset(0, -36),
            child: _PhotoAvatar(onFilePicked: _uploadAndSetPhoto),
          ),

          // Campos del formulario con padding horizontal.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Error banner
                if (error != null)
                  Container(
                    margin:  const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:        AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:       Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      error.message,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),

                // Nombre
                TextField(
                  controller:  _nameCtrl,
                  decoration: const InputDecoration(
                    labelText:  'Nombre *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  onChanged: (v) => context.read<EditProfileViewModel>().setName(v),
                ),
                const SizedBox(height: 16),

                // Bio
                TextField(
                  controller:  _bioCtrl,
                  maxLines:    3,
                  decoration: const InputDecoration(
                    labelText:  'Biografía',
                    prefixIcon: Icon(Icons.notes_outlined),
                    alignLabelWithHint: true,
                  ),
                  onChanged: (v) => context.read<EditProfileViewModel>().setBio(v),
                ),
                const SizedBox(height: 16),

                // Ubicación — selector autocomplete de capitales de provincia
                _LocationAutocomplete(
                  initialValue: context.read<EditProfileViewModel>().location,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final result = await context.read<EditProfileViewModel>().save();
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente.')),
      );
      Navigator.of(context).pop(result);
    }
  }
}

// ─── Banner editable ──────────────────────────────────────────────────────────

/// Franja de banner con overlay de cámara para cambiar la imagen de fondo.
class _BannerPicker extends StatelessWidget {
  const _BannerPicker({required this.onFilePicked});

  final Future<void> Function(Uint8List bytes, String filename) onFilePicked;

  @override
  Widget build(BuildContext context) {
    final vm          = context.watch<EditProfileViewModel>();
    final isUploading = vm.isUploadingBanner;
    final bannerUrl   = vm.bannerPhoto;

    return SizedBox(
      height: 130,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo: imagen o color primario
          if (bannerUrl != null && bannerUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl:    bannerUrl,
              fit:         BoxFit.cover,
              placeholder: (_, _) => Container(color: AppColors.primary),
              errorWidget: (_, _, _) => Container(color: AppColors.primary),
            )
          else
            Container(color: AppColors.primary),

          // Overlay de carga
          if (isUploading)
            Container(
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Botón de cámara centrado
          if (!isUploading)
            Center(
              child: PhotoPickerButton(
                onFilePicked: onFilePicked,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:  Colors.black38,
                    shape:  BoxShape.circle,
                    border: Border.all(color: Colors.white54),
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: Colors.white,
                    size:  24,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Avatar con overlay de cámara ────────────────────────────────────────────

class _PhotoAvatar extends StatelessWidget {
  const _PhotoAvatar({required this.onFilePicked});

  final Future<void> Function(Uint8List bytes, String filename) onFilePicked;

  @override
  Widget build(BuildContext context) {
    final vm              = context.watch<EditProfileViewModel>();
    final isUploading     = vm.isUploadingPhoto;
    final photoUrl        = vm.photo;
    final authorName      = vm.name;

    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius:          56,
            backgroundColor: AppColors.primary,
            backgroundImage: (!isUploading && photoUrl != null && photoUrl.isNotEmpty)
                ? CachedNetworkImageProvider(photoUrl)
                : null,
            child: isUploading
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : (photoUrl == null || photoUrl.isEmpty)
                    ? Text(
                        authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   40,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
          ),
          PhotoPickerButton(
            onFilePicked: onFilePicked,
            child: Container(
              decoration: BoxDecoration(
                color:  AppColors.primary,
                shape:  BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              padding: const EdgeInsets.all(6),
              child:   const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Autocomplete de ubicación ────────────────────────────────────────────────

/// Campo de autocompletado para seleccionar una capital de provincia española.
///
/// Al escribir se consulta a [EditProfileViewModel.searchLocations]; al
/// seleccionar una opción se llama a [EditProfileViewModel.selectLocation]
/// que persiste el nombre completo y las coordenadas.
class _LocationAutocomplete extends StatelessWidget {
  const _LocationAutocomplete({required this.initialValue});

  final String initialValue;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<EditProfileViewModel>();

    return Autocomplete<Location>(
      initialValue:          TextEditingValue(text: initialValue),
      displayStringForOption: (loc) => loc.fullName,
      optionsBuilder: (value) => vm.searchLocations(value.text),
      onSelected: (loc) => vm.selectLocation(loc),
      fieldViewBuilder: (ctx, ctrl, focusNode, onSubmit) => TextField(
        controller:  ctrl,
        focusNode:   focusNode,
        onEditingComplete: onSubmit,
        onChanged:   (v) => vm.setLocation(v),
        decoration: const InputDecoration(
          labelText:      'Ubicación',
          prefixIcon:     Icon(Icons.location_on_outlined),
          hintText:       'Ej: Sevilla',
          helperText:     'Se usa para mostrar el tiempo en tus plantas',
          helperMaxLines: 2,
        ),
      ),
      optionsViewBuilder: (ctx, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.builder(
              padding:     EdgeInsets.zero,
              shrinkWrap:  true,
              itemCount:   options.length,
              itemBuilder: (_, i) {
                final loc = options.elementAt(i);
                return ListTile(
                  dense:   true,
                  leading: const Icon(Icons.location_city_outlined, size: 18),
                  title:   Text(loc.fullName),
                  onTap:   () => onSelected(loc),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
