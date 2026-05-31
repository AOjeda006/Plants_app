/// @file community_feed_page.dart
/// @description Pantalla del feed de la comunidad con scroll infinito y FAB para crear post.
/// Muestra las publicaciones de todos los usuarios en orden cronológico inverso.
/// @module Community
/// @layer Presentation
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_theme.dart';
import '../../core/di/container.dart';
import '../../core/errors/app_error.dart';
import '../../data/datasources/remote/admin_remote_data_source.dart';
import '../../data/datasources/remote/post_remote_data_source.dart';
import '../../data/datasources/remote/user_remote_data_source.dart';
import '../routes/app_router.dart';
import '../viewmodels/auth/auth_viewmodel.dart';
import '../viewmodels/community/feed_viewmodel.dart';
import '../widgets/post_card.dart';
import '../widgets/viewport_detector_widget.dart';
import 'main_tabs_page.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// COMMUNITY FEED PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Pantalla principal del módulo de comunidad.
///
/// Crea un [FeedViewModel] propio mediante [ChangeNotifierProvider]
/// y lo destruye al salir de la ruta.
class CommunityFeedPage extends StatelessWidget {
  const CommunityFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    // .value: el Provider escucha el singleton sin apropiarse de su ciclo de vida.
    // La carga inicial la dispara MainTabsPage.initState() en cada nuevo login.
    return ChangeNotifierProvider<FeedViewModel>.value(
      value: sl<FeedViewModel>(),
      child: const _FeedContent(),
    );
  }
}

// ─── Contenido principal ──────────────────────────────────────────────────────

class _FeedContent extends StatelessWidget {
  const _FeedContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Comunidad'),
        actions: [
          IconButton(
            icon:    const Icon(Icons.search_rounded),
            tooltip: 'Buscar usuario',
            onPressed: () => showSearch(
              context:  context,
              delegate: _UserSearchDelegate(MainTabsScope.maybeOf(context)),
            ),
          ),
        ],
      ),
      body:                const _FeedBody(),
      floatingActionButton: const _CreatePostFab(),
    );
  }
}

// ─── Cuerpo del feed ──────────────────────────────────────────────────────────

class _FeedBody extends StatelessWidget {
  const _FeedBody();

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<FeedViewModel, bool>((vm) => vm.isLoading);
    final error     = context.select<FeedViewModel, AppError?>((vm) => vm.error);
    final isEmpty   = context.select<FeedViewModel, bool>((vm) => vm.isEmpty);

    if (isLoading) return const _LoadingList();
    if (error != null) return _ErrorState(error: error);
    if (isEmpty) return const _EmptyState();
    return const _PostList();
  }
}

// ─── Lista de posts con scroll infinito ───────────────────────────────────────

class _PostList extends StatelessWidget {
  const _PostList();

  @override
  Widget build(BuildContext context) {
    final vm      = context.watch<FeedViewModel>();
    final posts   = vm.posts;
    final isAdmin = context.read<AuthViewModel>().currentUser?.isAdmin ?? false;

    return RefreshIndicator(
      color:     AppColors.primary,
      onRefresh: vm.refresh,
      child: ListView.builder(
        // +1 para el indicador de carga al final si hay más páginas.
        itemCount:   posts.length + (vm.hasMore ? 1 : 0),
        padding:     const EdgeInsets.only(top: 8, bottom: 80),
        itemBuilder: (ctx, i) {
          // Indicador de carga de página siguiente.
          if (i == posts.length) {
            // Trigger de carga al llegar al final.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<FeedViewModel>().loadMore();
            });
            return const Padding(
              padding: EdgeInsets.all(16),
              child:   Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          final post = posts[i];
          return ViewportDetectorWidget(
            itemKey: post.id,
            // TFG: el registro de seenBy se haría aquí con un use case futuro.
            onSeen:  () {},
            child:   PostCard(
              post:       post,
              onTap: () async {
                await Navigator.of(ctx).pushNamed(
                  AppRoutes.postDetail,
                  arguments: post.id,
                );
                // Refrescar feed al volver del detalle: actualiza likes,
                // comentarios y filtra posts de usuarios que se hayan
                // vuelto privados o eliminados durante la visita.
                if (ctx.mounted) {
                  ctx.read<FeedViewModel>().loadFeed();
                }
              },
              onLike: context.read<FeedViewModel>().isPendingLike(post.id)
                  ? null
                  : () => context.read<FeedViewModel>().toggleLike(post.id),
              onAuthorTap: () {
                // Bloquear navegación a perfiles de usuarios eliminados.
                if (post.authorName == 'Usuario eliminado') {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Este usuario ya no existe')),
                  );
                  return;
                }
                final currentUserId = context.read<AuthViewModel>().currentUser?.id;
                if (post.userId == currentUserId) {
                  Navigator.of(ctx).pushNamed(AppRoutes.profile);
                } else {
                  // Usar MainTabsScope para mostrar el perfil inline (BottomNav visible).
                  final scope = MainTabsScope.maybeOf(ctx);
                  final args = {
                    'userId':      post.userId,
                    'authorName':  post.authorName,
                    'authorPhoto': post.authorPhoto,
                  };
                  if (scope != null) {
                    scope.pushUserProfile(args);
                  } else {
                    Navigator.of(ctx).pushNamed(AppRoutes.userProfile, arguments: args);
                  }
                }
              },
              onReport: () => Navigator.of(ctx).pushNamed(
                AppRoutes.reportIncident,
                arguments: {'targetId': post.id, 'type': 'post'},
              ),
              onDelete: (isAdmin || post.userId == context.read<AuthViewModel>().currentUser?.id)
                  ? () async {
                try {
                  // Admin usa endpoint /admin/posts/:id; el autor usa /community/:id.
                  if (isAdmin) {
                    await sl<AdminRemoteDataSource>().deletePost(post.id);
                  } else {
                    await sl<PostRemoteDataSource>().deletePost(post.id);
                  }
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Publicación eliminada.')),
                    );
                    ctx.read<FeedViewModel>().loadFeed();
                  }
                } catch (_) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Error al eliminar la publicación.')),
                    );
                  }
                }
              } : null,
            ),
          );
        },
      ),
    );
  }
}

// ─── Estado de carga ──────────────────────────────────────────────────────────

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding:        const EdgeInsets.symmetric(vertical: 8),
      itemCount:      5,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder:    (_, _) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child:  Padding(
        padding: const EdgeInsets.all(12),
        child:   Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(
                  color:  AppColors.surface,
                  shape:  BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(height: 12, width: 120, color: AppColors.surface),
                const SizedBox(height: 6),
                Container(height: 10, width: 80,  color: AppColors.surface),
              ]),
            ]),
            const SizedBox(height: 12),
            Container(height: 160, width: double.infinity, color: AppColors.surface),
            const SizedBox(height: 10),
            Container(height: 12, width: double.infinity, color: AppColors.surface),
            const SizedBox(height: 6),
            Container(height: 12, width: 200, color: AppColors.surface),
          ],
        ),
      ),
    );
  }
}

// ─── Estado vacío ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child:   Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size:  72,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 20),
            Text(
              'El feed está vacío',
              style:     tt.titleMedium?.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sé el primero en compartir una publicación con la comunidad.',
              style:     tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Estado de error ──────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final AppError error;

  @override
  Widget build(BuildContext context) {
    final tt      = Theme.of(context).textTheme;
    final message = switch (error.code) {
      ErrorCode.network      => 'Sin conexión. Comprueba tu red.',
      ErrorCode.unauthorized => 'Sesión expirada. Vuelve a iniciar sesión.',
      _                      => 'Error al cargar el feed. Inténtalo de nuevo.',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child:   Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              error.code == ErrorCode.network
                  ? Icons.wifi_off_rounded
                  : Icons.error_outline_rounded,
              size:  64,
              color: AppColors.warning,
            ),
            const SizedBox(height: 16),
            Text(message, style: tt.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.read<FeedViewModel>().refresh(),
              icon:  const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Buscador de usuarios (público) ──────────────────────────────────────────

/// SearchDelegate que consulta GET /users/search?q=... (backend filtra
/// privados para no-admin y oculta al propio solicitante). Al seleccionar,
/// navega al perfil del usuario.
class _UserSearchDelegate extends SearchDelegate<void> {
  final MainTabsScope? _tabsScope;

  _UserSearchDelegate(this._tabsScope) : super(searchFieldLabel: 'Buscar usuario...');

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        tooltip:   'Borrar búsqueda',
        icon:      const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    tooltip:   'Volver',
    icon:      const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults(context);

  Widget _buildSearchResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(
        child: Text(
          'Escribe un nombre para buscar',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return FutureBuilder<List<dynamic>>(
      future: sl<UserRemoteDataSource>().searchUsers(query.trim()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error al buscar usuarios',
              style: TextStyle(color: AppColors.error),
            ),
          );
        }

        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return const Center(
            child: Text(
              'Sin resultados',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.separated(
          itemCount:        results.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            final user  = results[i] as Map<String, dynamic>;
            final name  = user['name'] as String? ?? '';
            final photo = user['photo'] as String?;
            final id    = user['id'] as String? ?? '';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                backgroundImage: photo != null && photo.isNotEmpty
                    ? NetworkImage(photo)
                    : null,
                child: photo == null || photo.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color:      AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              title: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color:      Colors.white,
                ),
              ),
              onTap: () {
                close(context, null);
                final args = {
                  'userId':      id,
                  'authorName':  name,
                  'authorPhoto': photo,
                };
                if (_tabsScope != null) {
                  _tabsScope.pushUserProfile(args);
                } else {
                  Navigator.of(context).pushNamed(AppRoutes.userProfile, arguments: args);
                }
              },
            );
          },
        );
      },
    );
  }
}

// ─── FAB crear post ───────────────────────────────────────────────────────────

class _CreatePostFab extends StatelessWidget {
  const _CreatePostFab();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'fab_community',
      onPressed: () async {
        final created = await Navigator.of(context).pushNamed(AppRoutes.createPost);
        // Refrescar el feed solo si se creó un post (la página devuelve true).
        if (context.mounted && created == true) {
          context.read<FeedViewModel>().refresh();
        }
      },
      tooltip: 'Crear publicación',
      child:   const Icon(Icons.add_rounded),
    );
  }
}
