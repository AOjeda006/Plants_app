/// @file my_profile_page.dart
/// @description Pantalla de perfil propio del usuario.
/// Muestra foto, nombre, bio, botón de editar y publicaciones propias
/// separadas en dos pestañas: "Con foto" (grid) y "Sin foto" (lista de texto).
/// Logout y ajustes accesibles como iconos en la AppBar.
/// @module User
/// @layer Presentation
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app.dart' show appProviderGeneration;
import '../../core/config/app_theme.dart';
import '../../core/di/container.dart';
import '../../domain/entities/post.dart';
import '../routes/app_router.dart';
import '../widgets/text_post_card.dart';
import '../viewmodels/auth/auth_viewmodel.dart';
import '../viewmodels/profile/my_profile_viewmodel.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MY PROFILE PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Pantalla de perfil propio. Accesible desde el tab de navegación.
class MyProfilePage extends StatelessWidget {
  const MyProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MyProfileViewModel>(
      create: (_) => sl<MyProfileViewModel>()..loadProfile(),
      child: const _ProfileContent(),
    );
  }
}

// ─── Contenido principal ──────────────────────────────────────────────────────

class _ProfileContent extends StatelessWidget {
  const _ProfileContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyProfileViewModel>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text('Mi perfil'),
          actions: [
            // Botón de ajustes
            IconButton(
              icon:    const Icon(Icons.settings_outlined),
              tooltip: 'Ajustes',
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.settings),
            ),
            // Botón de cerrar sesión en el AppBar.
            IconButton(
              icon:    const Icon(Icons.logout_rounded),
              tooltip: 'Cerrar sesión',
              onPressed: () => _confirmLogout(context),
            ),
          ],
        ),
        body: _buildBody(context, vm),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MyProfileViewModel vm) {
    if (vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (vm.error != null) {
      return _ErrorState(vm: vm);
    }
    if (vm.user == null) return const SizedBox.shrink();

    return Column(
      children: [
        _MyProfileHeader(vm: vm),
        const TabBar(
          labelColor:           AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor:       AppColors.primary,
          tabs: [
            Tab(icon: Icon(Icons.grid_on_rounded)),
            Tab(icon: Icon(Icons.chat_bubble_outline_rounded)),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
            color:     AppColors.primary,
            onRefresh: vm.loadProfile,
            child: TabBarView(
              children: [
                _PhotoTab(posts: vm.postsWithImage),
                _TextTab(posts:  vm.postsWithoutImage),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child:     const Text('Cancelar'),
          ),
          TextButton(
            style:     TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child:     const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    // Logout profundo (DELETE fcm-token + clear socket + cache +
    // secure_storage). Tras eso, incrementar `appProviderGeneration`
    // reconstruye el árbol MultiProvider con ViewModels nuevos antes
    // de navegar.
    await context.read<AuthViewModel>().logout();
    appProviderGeneration.value++;
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true)
          .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    }
  }
}

// ─── Cabecera del perfil propio ───────────────────────────────────────────────

class _MyProfileHeader extends StatelessWidget {
  const _MyProfileHeader({required this.vm});

  final MyProfileViewModel vm;

  @override
  Widget build(BuildContext context) {
    final user = vm.user!;
    final tt   = Theme.of(context).textTheme;

    return Column(
      children: [
        // Banner con avatar solapado en la parte inferior.
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            _MyBannerStrip(bannerUrl: user.bannerPhoto),
            Positioned(
              bottom: -40,
              child: CircleAvatar(
                radius:          44,
                backgroundColor: AppColors.primary,
                backgroundImage: user.photo != null && user.photo!.isNotEmpty
                    ? CachedNetworkImageProvider(user.photo!)
                    : null,
                child: (user.photo == null || user.photo!.isEmpty)
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   32,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 48), // espacio para el avatar solapado

        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            children: [
              // Nombre
              Text(
                user.name,
                style: tt.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color:      AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // Email
              Text(
                user.email,
                style: tt.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),

              // Badge admin
              if (user.isAdmin) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color:        AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border:       Border.all(color: AppColors.accent),
                  ),
                  child: const Text(
                    'Administrador',
                    style: TextStyle(
                      color:      AppColors.textPrimary,
                      fontSize:   12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              // Bio
              if (user.bio?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(
                  user.bio!,
                  style:     tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],

              // Ubicación
              if (user.location?.isNotEmpty == true) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      user.location!,
                      style: tt.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 6),
              Text(
                '${vm.posts.length} publicaciones',
                style: tt.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // Botón editar perfil
              OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).pushNamed(
                    AppRoutes.profileEdit,
                    arguments: user,
                  );
                  if (context.mounted) {
                    context.read<MyProfileViewModel>().loadProfile();
                  }
                },
                icon:  const Icon(Icons.edit_outlined),
                label: const Text('Editar perfil'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side:            const BorderSide(color: AppColors.primary),
                ),
              ),

              // Panel admin (solo admins)
              if (user.isAdmin) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.admin),
                  icon:  const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Panel de administración'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side:            const BorderSide(color: AppColors.secondary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Franja de banner (perfil propio) ────────────────────────────────────────

/// Franja de color/imagen en la cabecera del perfil propio.
class _MyBannerStrip extends StatelessWidget {
  const _MyBannerStrip({this.bannerUrl});

  final String? bannerUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      width:  double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (bannerUrl != null && bannerUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl:    bannerUrl!,
              fit:         BoxFit.cover,
              placeholder: (_, _) => Container(color: AppColors.primary),
              errorWidget: (_, _, _) => Container(color: AppColors.primary),
            )
          else
            Container(color: AppColors.primary),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end:   Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.25)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab "Con foto": grid de imágenes ────────────────────────────────────────

class _PhotoTab extends StatelessWidget {
  const _PhotoTab({required this.posts});

  final List<Post> posts;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const _TabEmptyState(
        icon:    Icons.photo_library_outlined,
        message: 'Aún no tienes publicaciones con foto',
      );
    }

    return GridView.builder(
      padding:  const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   3,
        mainAxisSpacing:  2,
        crossAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (ctx, i) {
        final post = posts[i];
        return GestureDetector(
          onTap: () => Navigator.of(ctx).pushNamed(
            AppRoutes.postDetail,
            arguments: post.id,
          ),
          child: CachedNetworkImage(
            imageUrl:    post.image!,
            fit:         BoxFit.cover,
            placeholder: (_, _) => Container(color: AppColors.surface),
            errorWidget: (_, _, _) => Container(
              color: AppColors.surface,
              child: const Icon(
                Icons.broken_image_outlined,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Tab "Sin foto": lista de texto ──────────────────────────────────────────

class _TextTab extends StatelessWidget {
  const _TextTab({required this.posts});

  final List<Post> posts;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const _TabEmptyState(
        icon:    Icons.format_list_bulleted_rounded,
        message: 'Aún no tienes publicaciones de texto',
      );
    }

    return ListView.builder(
      padding:     const EdgeInsets.all(12),
      itemCount:   posts.length,
      itemBuilder: (ctx, i) {
        final post = posts[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextPostCard(
            post:  post,
            onTap: () => Navigator.of(ctx).pushNamed(
              AppRoutes.postDetail,
              arguments: post.id,
            ),
          ),
        );
      },
    );
  }
}

// ─── Estado vacío por pestaña ─────────────────────────────────────────────────

class _TabEmptyState extends StatelessWidget {
  const _TabEmptyState({required this.icon, required this.message});

  final IconData icon;
  final String   message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.secondary),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Estado de error ──────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.vm});

  final MyProfileViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: 12),
            const Text('No se pudo cargar el perfil.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => vm.loadProfile(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
