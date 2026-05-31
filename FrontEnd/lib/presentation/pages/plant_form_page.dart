/// @file plant_form_page.dart
/// @description Pantalla de creación y edición de plantas.
/// Incluye buscador de especie, selector de foto y validación de campos.
/// @module Plants
/// @layer Presentation
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_theme.dart';
import '../../core/di/container.dart';
import '../../core/errors/app_error.dart';
import '../../core/network/api_client.dart';
import '../../data/datasources/remote/location_remote_data_source.dart';
import '../../domain/entities/location.dart';
import '../../domain/entities/plant.dart';
import '../../domain/entities/plant_species.dart';
import '../viewmodels/auth/auth_viewmodel.dart';
import '../viewmodels/plants/plant_form_viewmodel.dart';
import '../widgets/photo_picker_button.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PLANT FORM PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Pantalla de formulario de creación/edición de planta.
///
/// Si [plant] es null se crea una planta nueva.
/// Si [plant] tiene valor se edita la planta existente.
class PlantFormPage extends StatelessWidget {
  const PlantFormPage({super.key, this.plant});

  /// Planta a editar; null si se está creando una nueva.
  final Plant? plant;

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthViewModel>().currentUser;
    return ChangeNotifierProvider<PlantFormViewModel>(
      create: (_) {
        final vm = sl<PlantFormViewModel>();
        if (plant != null) {
          vm.initForEdit(plant!);
        } else {
          vm.initForCreate(
            userLocation:    user?.location,
            userLocationLat: user?.locationLat,
            userLocationLon: user?.locationLon,
          );
        }
        return vm;
      },
      child: _PlantFormContent(isEditing: plant != null),
    );
  }
}

// ─── Contenido del formulario ─────────────────────────────────────────────────

class _PlantFormContent extends StatefulWidget {
  const _PlantFormContent({required this.isEditing});

  final bool isEditing;

  @override
  State<_PlantFormContent> createState() => _PlantFormContentState();
}

class _PlantFormContentState extends State<_PlantFormContent> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _notesCtrl    = TextEditingController();
  final _wateringCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-rellenar controladores con los valores del ViewModel (modo edición).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<PlantFormViewModel>();
      _nameCtrl.text     = vm.name;
      _notesCtrl.text    = vm.notes ?? '';
      _wateringCtrl.text = vm.wateringFrequencyDays.toString();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _wateringCtrl.dispose();
    super.dispose();
  }

  // ─── Acciones ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final vm = context.read<PlantFormViewModel>();

    // Especie obligatoria al crear una planta nueva.
    if (!vm.isEditing && vm.selectedSpecies == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una especie para tu planta.')),
      );
      return;
    }

    vm.setName(_nameCtrl.text.trim());
    vm.setNotes(_notesCtrl.text.trim().isEmpty
        ? null
        : _notesCtrl.text.trim());

    // En edición el usuario puede modificar los campos manualmente → leer controller.
    // En creación los valores provienen de selectSpecies() → no sobreescribir.
    if (widget.isEditing) {
      final wateringDays = int.tryParse(_wateringCtrl.text.trim()) ?? 7;
      vm.setWateringFrequencyDays(wateringDays);
    }

    final success = await vm.submit();
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(vm.result);
    } else {
      _showError(vm.error);
    }
  }

  void _showError(AppError? error) {
    if (error == null) return;
    // Sin cola offline: los errores de red se muestran y el usuario
    // reintenta manualmente.
    final message = switch (error.code) {
      ErrorCode.network      => 'Sin conexión. Inténtalo de nuevo cuando vuelva la red.',
      ErrorCode.validation   => error.message,
      ErrorCode.unauthorized => 'Sesión expirada. Vuelve a iniciar sesión.',
      _                      => 'Error al guardar la planta. Inténtalo de nuevo.',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Sube los bytes al backend y aplica la URL resultante al ViewModel.
  Future<void> _uploadAndSetPhoto(Uint8List bytes, String filename) async {
    try {
      final result = await sl<ApiClient>().uploadImage<Map<String, dynamic>>(
        '/upload/image',
        bytes,
        filename,
        fieldName: 'image',
      );
      if (!mounted) return;
      final url = result['url'] as String?;
      if (url != null) context.read<PlantFormViewModel>().setPhoto(url);
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir la foto: ${e.message}')),
      );
    }
  }

  // ─── UI ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isSubmitting =
        context.select<PlantFormViewModel, bool>((vm) => vm.isSubmitting);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar planta' : 'Nueva planta'),
        actions: [
          if (isSubmitting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child:   SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          else
            TextButton(
              onPressed: _submit,
              child:     Text(widget.isEditing ? 'Guardar cambios' : 'Crear planta'),
            ),
        ],
      ),
      // En móvil, el último campo (Notas) quedaba cortado por el área
      // de gesto inferior + el teclado virtual cuando estaba abierto.
      // Sumamos `viewInsets.bottom` (teclado) y `viewPadding.bottom`
      // (gesture indicator) al padding inferior.
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20
              + MediaQuery.of(context).viewInsets.bottom
              + MediaQuery.of(context).viewPadding.bottom
              + 24, // colchón extra para que las notas se vean cómodas
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Foto ───────────────────────────────────────────────────
              _PhotoSection(onFilePicked: _uploadAndSetPhoto),
              const SizedBox(height: 24),

              // ── Nombre ─────────────────────────────────────────────────
              TextFormField(
                controller:      _nameCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText:  'Nombre de la planta *',
                  prefixIcon: Icon(Icons.local_florist_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'El nombre es obligatorio.'
                    : null,
              ),
              const SizedBox(height: 16),

              // ── Especie ─────────────────────────────────────────────────
              const _SpeciesAutocomplete(),
              const SizedBox(height: 16),

              // ── Ubicación Interior/Exterior ─────────────────────────────
              _DropdownField<String>(
                label:     'Ubicación *',
                icon:      Icons.location_on_outlined,
                value:     context.select<PlantFormViewModel, String>((vm) => vm.location),
                items:     const ['Interior', 'Exterior'],
                itemLabel: (v) => v,
                onChanged: (v) => context.read<PlantFormViewModel>().setLocation(v),
              ),
              const SizedBox(height: 16),

              // ── Ciudad de la planta ─────────────────────────────────────
              const _CityAutocomplete(),
              const SizedBox(height: 16),

              // ── Necesidad de luz — solo en edición ──────────────────────
              // En creación se asigna automáticamente desde la especie seleccionada.
              if (widget.isEditing) ...[
                _DropdownField<String>(
                  label:     'Luz necesaria *',
                  icon:      Icons.wb_sunny_outlined,
                  value:     context.select<PlantFormViewModel, String>((vm) => vm.lightNeed),
                  items:     const ['Low', 'Medium', 'High'],
                  itemLabel: (v) => switch (v) {
                    'Low'    => 'Poca',
                    'Medium' => 'Media',
                    'High'   => 'Alta',
                    _        => v,
                  },
                  onChanged: (v) => context.read<PlantFormViewModel>().setLightNeed(v),
                ),
                const SizedBox(height: 16),

                // ── Frecuencia de riego — solo en edición ─────────────────
                TextFormField(
                  controller:      _wateringCtrl,
                  keyboardType:    TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText:  'Frecuencia de riego (días) *',
                    prefixIcon: Icon(Icons.water_drop_outlined),
                    suffixText: 'días',
                  ),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) {
                      return 'Introduce un número de días válido (mínimo 1).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // ── Notas ───────────────────────────────────────────────────
              TextFormField(
                controller: _notesCtrl,
                maxLines:   4,
                decoration: const InputDecoration(
                  labelText:          'Notas personalizadas (opcional)',
                  prefixIcon:         Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              // Botones unificados en el AppBar: los botones inferiores
              // duplicados se eliminaron — el botón "Guardar" superior
              // dispara `_submit` y el icono "Volver" del Navigator
              // funciona como cancelar.
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dropdown genérico ────────────────────────────────────────────────────────

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String       label;
  final IconData     icon;
  final T            value;
  final List<T>      items;
  final String Function(T) itemLabel;
  final void Function(T)   onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText:  label,
        prefixIcon: Icon(icon),
      ),
      items: items
          .map((v) => DropdownMenuItem<T>(value: v, child: Text(itemLabel(v))))
          .toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }
}

// ─── Sección de foto ──────────────────────────────────────────────────────────

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({required this.onFilePicked});

  final Future<void> Function(Uint8List bytes, String filename) onFilePicked;

  @override
  Widget build(BuildContext context) {
    final photo = context.select<PlantFormViewModel, String?>((vm) => vm.photo);

    final content = photo != null
        ? Image.network(photo, fit: BoxFit.cover)
        : const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 40, color: AppColors.primary),
              SizedBox(height: 8),
              Text(
                'Añadir foto',
                style: TextStyle(
                  color:      AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );

    // ConstrainedBox limita el ancho del picker de foto en web (>700px).
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: PhotoPickerButton(
          onFilePicked: onFilePicked,
          child: Container(
            height:      160,
            decoration:  BoxDecoration(
              color:        AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: content,
          ),
        ),
      ),
    );
  }
}

// ─── Autocomplete de especie ──────────────────────────────────────────────────

/// Widget de autocompletado de especie con [Autocomplete<PlantSpecies>].
///
/// Al enfocar (texto vacío): muestra todas las especies públicas del catálogo.
/// Al escribir: filtra progresivamente por nombre o nombre científico.
/// Al seleccionar: aplica especie y auto-rellena cuidados en el ViewModel.
class _SpeciesAutocomplete extends StatelessWidget {
  const _SpeciesAutocomplete();

  @override
  Widget build(BuildContext context) {
    final selectedSpecies = context.select<PlantFormViewModel, PlantSpecies?>(
      (vm) => vm.selectedSpecies,
    );

    // Si ya hay especie seleccionada, mostrar chip con botón de quitar.
    if (selectedSpecies != null) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText:  'Especie',
          prefixIcon: Icon(Icons.eco_outlined),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedSpecies.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon:    const Icon(Icons.close_rounded, size: 18),
              tooltip: 'Quitar especie',
              onPressed: () => context.read<PlantFormViewModel>().clearSpecies(),
            ),
          ],
        ),
      );
    }

    // Capturar vm fuera del optionsBuilder para evitar problemas de contexto.
    final vm = context.read<PlantFormViewModel>();

    return Autocomplete<PlantSpecies>(
      displayStringForOption: (s) => s.name,

      // Llama al backend con el texto actual; vacío = todas las especies.
      optionsBuilder: (TextEditingValue textEditingValue) =>
          vm.fetchSpeciesOptions(textEditingValue.text),

      // Vista personalizada de cada opción en el desplegable.
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation:    4,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.separated(
              shrinkWrap:       true,
              padding:          EdgeInsets.zero,
              itemCount:        options.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final s = options.elementAt(i);
                return ListTile(
                  dense:    true,
                  leading:  const Icon(Icons.eco_outlined, color: AppColors.primary),
                  title:    Text(s.name),
                  subtitle: Text(
                    s.scientificName,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize:  12,
                      color:     AppColors.textSecondary,
                    ),
                  ),
                  onTap: () => onSelected(s),
                );
              },
            ),
          ),
        ),
      ),

      // Campo de texto del autocompletado.
      fieldViewBuilder: (context, textCtrl, focusNode, onFieldSubmitted) =>
          TextFormField(
            controller:      textCtrl,
            focusNode:       focusNode,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              labelText:  'Buscar especie *',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),

      // Al seleccionar una especie: aplica en ViewModel y auto-rellena cuidados.
      onSelected: (PlantSpecies s) =>
          context.read<PlantFormViewModel>().selectSpecies(s),
    );
  }
}

// ─── Autocomplete de ciudad ───────────────────────────────────────────────────

/// Widget de autocompletado de ciudad usando el catálogo de capitales de provincia.
///
/// Si ya hay ciudad seleccionada (con coordenadas) muestra un chip con ×.
/// Al enfocar (texto vacío): muestra todas las 52 capitales.
/// Al seleccionar: guarda nombre + lat/lon en el ViewModel.
class _CityAutocomplete extends StatelessWidget {
  const _CityAutocomplete();

  @override
  Widget build(BuildContext context) {
    final cityName = context.select<PlantFormViewModel, String>(
      (vm) => vm.plantLocation,
    );
    final hasCoords = context.select<PlantFormViewModel, bool>(
      (vm) => vm.plantLocationLat != null,
    );

    // Si hay ciudad seleccionada del catálogo (con coords), mostrar chip.
    if (cityName.isNotEmpty && hasCoords) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText:  'Ciudad de la planta *',
          prefixIcon: Icon(Icons.location_city_outlined),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(cityName, overflow: TextOverflow.ellipsis),
            ),
            IconButton(
              icon:    const Icon(Icons.close_rounded, size: 18),
              tooltip: 'Cambiar ciudad',
              onPressed: () =>
                  context.read<PlantFormViewModel>().setPlantLocationText(''),
            ),
          ],
        ),
      );
    }

    final vm = context.read<PlantFormViewModel>();
    final locationDs = sl<LocationRemoteDataSource>();

    return Autocomplete<Location>(
      displayStringForOption: (loc) => loc.fullName,
      initialValue: TextEditingValue(text: cityName),

      optionsBuilder: (TextEditingValue textEditingValue) async {
        try {
          return await locationDs.search(textEditingValue.text.trim());
        } catch (_) {
          return const [];
        }
      },

      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation:    4,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.separated(
              shrinkWrap:       true,
              padding:          EdgeInsets.zero,
              itemCount:        options.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final loc = options.elementAt(i);
                return ListTile(
                  dense:   true,
                  leading: const Icon(Icons.location_city_outlined,
                      color: AppColors.primary),
                  title:   Text(loc.name),
                  subtitle: Text(
                    loc.fullName,
                    style: const TextStyle(
                      fontSize: 12,
                      color:    AppColors.textSecondary,
                    ),
                  ),
                  onTap: () => onSelected(loc),
                );
              },
            ),
          ),
        ),
      ),

      fieldViewBuilder: (context, textCtrl, focusNode, onFieldSubmitted) =>
          TextFormField(
            controller:      textCtrl,
            focusNode:       focusNode,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              labelText:  'Ciudad de la planta *',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
            onChanged: (v) => vm.setPlantLocationText(v),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'La ciudad es obligatoria.'
                : null,
          ),

      onSelected: (Location loc) =>
          context.read<PlantFormViewModel>().selectPlantLocation(loc),
    );
  }
}
