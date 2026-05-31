/// @file user_profile_page.dart
/// @description Pantalla del perfil de un usuario ajeno. Muestra su avatar,
/// nombre y publicaciones separadas en dos pestañas:
/// "Con foto" (grid de imágenes) y "Sin foto" (lista de texto).
/// @module Community
/// @layer Presentation
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_theme.dart';
import '../../core/di/container.dart';
import '../../core/errors/app_error.dart';
import '../../data/datasources/remote/admin_remote_data_source.dart';
import '../../domain/entities/post.dart';
import '../../domain/interfaces/usecases/chat/i_create_conversation_use_case.dart';
import '../routes/app_router.dart';
import '../viewmodels/auth/auth_viewmodel.dart';
import '../viewmodels/community/user_profile_viewmodel.dart';
import '../widgets/text_post_card.dart';
import 'main_tabs_page.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// USER PROFILE PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Pantalla del perfil de un usuario ajeno con sus posts separados por pestañas.
class UserProfilePage extends StatelessWidget {
  const UserProfilePage({
    super.key,
    required this.userId,
    required this.authorName,
    this.authorPhoto,
  });

  final String  userId;
  final String  authorName;
  final String? authorPhoto;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserProfileViewModel>(
      create: (_) => sl<UserProfileViewModel>()..loadProfile(
        userId:      userId,
        authorName:  authorName,
        authorPhoto: authorPhoto,
      ),
      child: const _UserProfileContent(),
    );
  }
}

// ─── Contenido principal ──────────────────────────────────────────────────────

class _UserProfileContent extends StatelessWidget {
  const _UserProfileContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserProfileViewModel>();

    final isAdmin = context.select<AuthViewModel, bool>(
      (a) => a.currentUser?.isAdmin ?? false,
    );

    // Si el perfil se muestra inline dentro de MainTabsScope, añadir botón
    // de retroceso manual (no hay Navigator.pop automático en este caso).
    final tabsScope = MainTabsScope.maybeOf(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          leading: tabsScope != null
              ? IconButton(
                  tooltip:   'Volver',
                  icon:      const Icon(Icons.arrow_back),
                  onPressed: tabsScope.popUserProfile,
                )
              : null,
          title: Text(vm.authorName.isNotEmpty ? vm.authorName : 'Perfil'),
          actions: [
            if (isAdmin)
              _AdminUserMenu(userId: vm.userId, userName: vm.authorName),
          ],
        ),
        body: _buildBody(context, vm),
      ),
    );
  }

  Widget _buildBody(BuildContext context, UserProfileViewModel vm) {
    if (vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (vm.error != null) {
      return _ErrorState(vm: vm);
    }

    if (vm.isPrivate) {
      return Column(
        children: [
          _ProfileHeader(vm: vm),
          const Expanded(child: _PrivateProfileState()),
        ],
      );
    }

    // La cabecera de perfil se muestra siempre (aunque no haya posts).
    // Los estados vacíos por pestaña los gestionan _PhotoTab y _TextTab.
    // TabBar se ubica justo debajo de la cabecera, encima del contenido de posts.
    return Column(
      children: [
        _ProfileHeader(vm: vm),
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
            onRefresh: vm.refresh,
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
}

// ─── Cabecera de perfil ───────────────────────────────────────────────────────

class _ProfileHeader extends StatefulWidget {
  const _ProfileHeader({required this.vm});

  final UserProfileViewModel vm;

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  bool _openingChat = false;

  /// Crea o recupera la conversación con el usuario y navega al chat.
  Future<void> _openChat() async {
    if (_openingChat) return;
    setState(() => _openingChat = true);

    try {
      final currentUserId = context.read<AuthViewModel>().currentUser?.id ?? '';
      final conversation  = await sl<ICreateConversationUseCase>().execute(widget.vm.userId);

      if (!mounted) return;
      await Navigator.of(context).pushNamed(
        AppRoutes.chat,
        arguments: {
          'conversationId':   conversation.id,
          'participantName':  conversation.participantName,
          'participantPhoto': conversation.participantPhoto,
          'currentUserId':    currentUserId,
        },
      );
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        // Banner con avatar solapado en la parte inferior.
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            _BannerStrip(bannerUrl: vm.bannerPhoto),
            Positioned(
              bottom: -40,
              child: CircleAvatar(
                radius:          44,
                backgroundColor: AppColors.primary,
                backgroundImage: vm.authorPhoto != null && vm.authorPhoto!.isNotEmpty
                    ? CachedNetworkImageProvider(vm.authorPhoto!)
                    : null,
                child: (vm.authorPhoto == null || vm.authorPhoto!.isEmpty)
                    ? Text(
                        vm.authorName.isNotEmpty ? vm.authorName[0].toUpperCase() : '?',
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
              Text(
                vm.authorName,
                style:    tt.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color:      AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${vm.posts.length} publicaciones',
                style: tt.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              // Botón de enviar mensaje — oculto si el perfil es privado.
              if (!vm.isPrivate)
                OutlinedButton.icon(
                  onPressed: _openingChat ? null : _openChat,
                  icon: _openingChat
                      ? const SizedBox(
                          width:  16,
                          height: 16,
                          child:  CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      : const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Enviar mensaje'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Franja de banner de perfil ───────────────────────────────────────────────

/// Franja de color/imagen que aparece en la cabecera de perfil.
/// Si [bannerUrl] es null muestra AppColors.primary; si no, la imagen con overlay.
class _BannerStrip extends StatelessWidget {
  const _BannerStrip({this.bannerUrl});

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
          // Gradient overlay para asegurar legibilidad del avatar/texto
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
        message: 'Sin publicaciones con foto',
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
        message: 'Sin publicaciones de texto',
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

// ─── Estado de perfil privado ─────────────────────────────────────────────────

class _PrivateProfileState extends StatelessWidget {
  const _PrivateProfileState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size:  64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Este perfil es privado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'El usuario ha elegido no compartir\nsus publicaciones públicamente.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Menú admin en perfil ajeno ───────────────────────────────────────────

/// PopupMenu con opciones de administración: enviar aviso y banear.
class _AdminUserMenu extends StatelessWidget {
  const _AdminUserMenu({required this.userId, required this.userName});

  final String userId;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.settings_outlined),
      tooltip: 'Administración',
      onSelected: (value) {
        switch (value) {
          case 'warn':
            _showWarnDialog(context);
          case 'ban':
            _showBanDialog(context);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'warn', child: Text('Enviar aviso')),
        PopupMenuItem(value: 'ban',  child: Text('Banear temporalmente')),
      ],
    );
  }

  void _showWarnDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Enviar aviso a $userName'),
        content: TextField(
          controller:  controller,
          maxLines:    3,
          decoration:  const InputDecoration(
            hintText:  'Escribe el mensaje del aviso...',
            border:    OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:     const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final msg = controller.text.trim();
              if (msg.isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                await sl<AdminRemoteDataSource>().warnUser(userId, msg);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Aviso enviado correctamente.')),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al enviar el aviso.')),
                  );
                }
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _showBanDialog(BuildContext context) {
    final options = <int>[1, 3, 7, 30];
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Banear a $userName'),
        children: [
          for (final days in options)
            SimpleDialogOption(
              onPressed: () {
                Navigator.of(ctx).pop();
                _executeBan(context, days);
              },
              child: Text('$days día${days > 1 ? 's' : ''}'),
            ),
        ],
      ),
    );
  }

  Future<void> _executeBan(BuildContext context, int days) async {
    try {
      await sl<AdminRemoteDataSource>().banUser(userId, days);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$userName baneado por $days día${days > 1 ? 's' : ''}.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al banear al usuario.')),
        );
      }
    }
  }
}

// ─── Estado de error ──────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.vm});

  final UserProfileViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              vm.error!.code == ErrorCode.network
                  ? Icons.wifi_off_rounded
                  : Icons.error_outline_rounded,
              size:  64,
              color: AppColors.warning,
            ),
            const SizedBox(height: 16),
            Text(
              'No se pudieron cargar las publicaciones.',
              style:    Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: vm.refresh,
              icon:  const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
