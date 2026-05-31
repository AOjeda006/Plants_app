/// @file post_detail_page.dart
/// @description Pantalla de detalle de un post con lista de comentarios e input para comentar.
/// @module Community
/// @layer Presentation
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_theme.dart';
import '../../core/di/container.dart';
import '../../core/errors/app_error.dart';
import '../../core/network/socket_client.dart';
import '../../data/datasources/remote/admin_remote_data_source.dart';
import '../../data/datasources/remote/post_remote_data_source.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/post.dart';
import '../routes/app_router.dart';
import '../viewmodels/auth/auth_viewmodel.dart';
import '../viewmodels/community/post_viewmodel.dart';
import '../widgets/image_viewer.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// POST DETAIL PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Pantalla de detalle de un post: imagen, contenido, contadores y comentarios.
/// Si [reportTicket] no es null, muestra un badge "INC-XXX" visible solo para admin.
/// Si [reportedCommentId] no es null, la etiqueta se muestra junto al comentario reportado.
class PostDetailPage extends StatelessWidget {
  const PostDetailPage({
    super.key,
    required this.postId,
    this.reportTicket,
    this.reportedCommentId,
  });

  final String  postId;
  /// Ticket de reporte asociado (ej: "INC-003"). Solo se muestra si el usuario es admin.
  final String? reportTicket;
  /// Id del comentario reportado. Si no es null, la etiqueta INC-XXX se muestra
  /// junto al nombre del autor de este comentario en lugar de en el AppBar.
  final String? reportedCommentId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PostViewModel>(
      create: (_) => sl<PostViewModel>()..loadPost(postId),
      child:  _PostDetailContent(
        postId:             postId,
        reportTicket:       reportTicket,
        reportedCommentId:  reportedCommentId,
      ),
    );
  }
}

// ─── Contenido principal ──────────────────────────────────────────────────────

class _PostDetailContent extends StatelessWidget {
  const _PostDetailContent({
    required this.postId,
    this.reportTicket,
    this.reportedCommentId,
  });

  final String  postId;
  final String? reportTicket;
  final String? reportedCommentId;

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<PostViewModel, bool>((vm) => vm.isLoading);
    final error     = context.select<PostViewModel, AppError?>((vm) => vm.error);

    final currentUser = context.read<AuthViewModel>().currentUser;
    final isAdmin     = currentUser?.isAdmin ?? false;
    final postUserId  = context.select<PostViewModel, String?>((vm) => vm.post?.userId);
    final isOwner     = postUserId != null && postUserId == currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: reportTicket != null && isAdmin && reportedCommentId == null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Publicación'),
                  const SizedBox(width: 8),
                  _ReportTicketBadge(ticket: reportTicket!),
                ],
              )
            : const Text('Publicación'),
        actions: [
          _PostDetailMenu(postId: postId, isAdmin: isAdmin, isOwner: isOwner),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : error != null
              ? _ErrorState(error: error, postId: postId)
              : _PostDetailBody(
                  reportTicket:      reportTicket,
                  reportedCommentId: reportedCommentId,
                ),
    );
  }
}

// ─── Cuerpo del detalle ───────────────────────────────────────────────────────

class _PostDetailBody extends StatefulWidget {
  const _PostDetailBody({this.reportTicket, this.reportedCommentId});

  final String? reportTicket;
  final String? reportedCommentId;

  @override
  State<_PostDetailBody> createState() => _PostDetailBodyState();
}

class _PostDetailBodyState extends State<_PostDetailBody> {
  final TextEditingController _commentCtrl  = TextEditingController();
  final ScrollController      _scrollCtrl   = ScrollController();

  @override
  void initState() {
    super.initState();
    // Suscribirse a actualizaciones de contadores en tiempo real.
    sl<SocketClient>().on('post:updated', _onPostUpdated);
  }

  void _onPostUpdated(dynamic data) {
    if (data is! Map) return;
    final postId        = data['postId']        as String?;
    final likesCount    = data['likesCount']    as int?;
    final commentsCount = data['commentsCount'] as int?;
    if (postId == null || likesCount == null || commentsCount == null) return;
    if (!mounted) return;
    context.read<PostViewModel>().applyPostUpdate(postId, likesCount, commentsCount);
  }

  @override
  void dispose() {
    sl<SocketClient>().off('post:updated', _onPostUpdated);
    _commentCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = context.select<PostViewModel, Post?>((vm) => vm.post);
    if (post == null) return const SizedBox.shrink();

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollCtrl,
            children: [
              // ── Cabecera del autor ──────────────────────────────────────────
              _AuthorHeader(post: post),
              // ── Imagen ─────────────────────────────────────────────────────
              if (post.hasImage) _PostFullImage(imageUrl: post.image!),
              // ── Contenido ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  post.content,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    // onSurface: contraste correcto en light y dark.
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              // ── Acciones (like + contadores) ─────────────────────────
              const _LikeRow(),
              const Divider(height: 1),
              // ── Comentarios ─────────────────────────────────────────────
              _CommentsList(
                postId:             post.id,
                reportTicket:       widget.reportTicket,
                reportedCommentId:  widget.reportedCommentId,
              ),
            ],
          ),
        ),
        // ── Input de comentario ─────────────────────────────────────────────
        _CommentInput(
          controller: _commentCtrl,
          onSubmit:   () => _submitComment(context),
        ),
      ],
    );
  }

  Future<void> _submitComment(BuildContext context) async {
    final content = _commentCtrl.text.trim();
    if (content.isEmpty) return;

    final vm      = context.read<PostViewModel>();
    final success = await vm.submitComment(content);
    if (success) {
      _commentCtrl.clear();
      // Desplazar al final para mostrar el nuevo comentario.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve:    Curves.easeOut,
        );
      }
    }
  }
}

// ─── Cabecera del autor ───────────────────────────────────────────────────────

class _AuthorHeader extends StatelessWidget {
  const _AuthorHeader({required this.post});

  final Post post;

  /// Navega al perfil del autor: MyProfilePage si es el usuario actual,
  /// UserProfilePage si es otro usuario.
  /// Bloquea la navegación si el autor ha sido eliminado.
  void _navigateToAuthor(BuildContext context) {
    if (post.authorName == 'Usuario eliminado') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este usuario ya no existe')),
      );
      return;
    }
    final currentUserId = context.read<AuthViewModel>().currentUser?.id;
    if (post.userId == currentUserId) {
      Navigator.of(context).pushNamed(AppRoutes.profile);
    } else {
      Navigator.of(context).pushNamed(
        AppRoutes.userProfile,
        arguments: {
          'userId':      post.userId,
          'authorName':  post.authorName,
          'authorPhoto': post.authorPhoto,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    // onTap en ListTile: hace clicable foto, nombre y fecha del autor.
    return ListTile(
      onTap: () => _navigateToAuthor(context),
      leading: CircleAvatar(
        radius:           22,
        backgroundColor:  AppColors.primary,
        backgroundImage: post.hasAuthorPhoto
            ? CachedNetworkImageProvider(post.authorPhoto!)
            : null,
        child: !post.hasAuthorPhoto
            ? Text(
                post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Text(
        post.authorName,
        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        DateFormat('d MMM yyyy • HH:mm', 'es').format(post.createdAt.toLocal()),
        style: tt.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ─── Imagen completa ──────────────────────────────────────────────────────────

class _PostFullImage extends StatelessWidget {
  const _PostFullImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    // ConstrainedBox limita el ancho en web (>700px) y centra la imagen.
    return GestureDetector(
      onTap: () => showFullScreenImage(context, imageUrl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: CachedNetworkImage(
            imageUrl:    imageUrl,
            fit:         BoxFit.cover,
            width:       double.infinity,
            placeholder: (_, _) => Container(
              height: 300,
              color:  AppColors.surface,
              child:  const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            errorWidget: (_, _, _) => Container(
              height: 300,
              color:  AppColors.surface,
              child:  const Icon(
                Icons.broken_image_outlined,
                color: AppColors.textSecondary,
                size:  48,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Fila de like ─────────────────────────────────────────────────────────────

/// Lee isLikedByMe, likesCount y commentsCount directamente del ViewModel con
/// context.select de tipos primitivos para evitar el problema de Post.== (que
/// solo compara por id y no detectaría cambios de likesCount tras copyWith).
class _LikeRow extends StatelessWidget {
  const _LikeRow();

  @override
  Widget build(BuildContext context) {
    final isLiked       = context.select<PostViewModel, bool>((vm) => vm.post?.isLikedByMe ?? false);
    final likesCount    = context.select<PostViewModel, int>((vm)  => vm.post?.likesCount    ?? 0);
    final commentsCount = context.select<PostViewModel, int>((vm)  => vm.post?.commentsCount ?? 0);
    final isPending     = context.select<PostViewModel, bool>((vm) => vm.isPendingLike);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isLiked
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
            ),
            color:     AppColors.error,
            tooltip:   isLiked ? 'Quitar like' : 'Me gusta',
            onPressed: isPending ? null : () => context.read<PostViewModel>().toggleLike(),
          ),
          Text(
            '$likesCount',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            Icons.chat_bubble_outline_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            '$commentsCount',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lista de comentarios ─────────────────────────────────────────────────────

class _CommentsList extends StatelessWidget {
  const _CommentsList({
    required this.postId,
    this.reportTicket,
    this.reportedCommentId,
  });

  final String  postId;
  final String? reportTicket;
  final String? reportedCommentId;

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<PostViewModel, bool>((vm) => vm.isLoadingComments);
    final comments  = context.watch<PostViewModel>().comments;

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child:   Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Sé el primero en comentar.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      children: comments.map((c) => _CommentTile(
        comment: c,
        reportTicket: reportedCommentId != null && c.id == reportedCommentId
            ? reportTicket
            : null,
      )).toList(),
    );
  }
}

// ─── Tile de comentario ───────────────────────────────────────────────────────

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, this.reportTicket});

  final Comment comment;
  /// Si no es null, se muestra un badge "INC-XXX" junto al nombre del autor.
  final String? reportTicket;

  /// Navega al perfil del autor del comentario.
  /// Bloquea la navegación si el autor ha sido eliminado.
  void _navigateToAuthor(BuildContext context) {
    if (comment.authorName == 'Usuario eliminado') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este usuario ya no existe')),
      );
      return;
    }
    final currentUserId = context.read<AuthViewModel>().currentUser?.id;
    if (comment.userId == currentUserId) {
      Navigator.of(context).pushNamed(AppRoutes.profile);
    } else {
      Navigator.of(context).pushNamed(
        AppRoutes.userProfile,
        arguments: {
          'userId':      comment.userId,
          'authorName':  comment.authorName,
          'authorPhoto': comment.authorPhoto,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final currentUser = context.read<AuthViewModel>().currentUser;
    final isAdmin     = currentUser?.isAdmin ?? false;
    final isOwner     = comment.userId == currentUser?.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar clicable — navega al perfil del autor.
          GestureDetector(
            onTap: () => _navigateToAuthor(context),
            child: CircleAvatar(
              radius:          16,
              backgroundColor: AppColors.primary,
              backgroundImage: comment.hasAuthorPhoto
                  ? CachedNetworkImageProvider(comment.authorPhoto!)
                  : null,
              child: !comment.hasAuthorPhoto
                  ? Text(
                      comment.authorName.isNotEmpty
                          ? comment.authorName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Nombre clicable — navega al perfil del autor.
                    GestureDetector(
                      onTap: () => _navigateToAuthor(context),
                      child: Text(
                        comment.authorName,
                        style: tt.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    // Badge de incidencia junto al nombre del comentario reportado.
                    if (reportTicket != null) ...[
                      const SizedBox(width: 6),
                      _ReportTicketBadge(ticket: reportTicket!),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      _shortDate(comment.createdAt),
                      style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment.content,
                  style: tt.bodySmall?.copyWith(color: cs.onSurface),
                ),
              ],
            ),
          ),
          _CommentMenu(comment: comment, isAdmin: isAdmin, isOwner: isOwner),
        ],
      ),
    );
  }

  String _shortDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours   < 1) return '${diff.inMinutes}m';
    if (diff.inDays    < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

// ─── Input de comentario ──────────────────────────────────────────────────────

class _CommentInput extends StatelessWidget {
  const _CommentInput({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback          onSubmit;

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.select<PostViewModel, bool>((vm) => vm.isSubmitting);

    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Container(
        // surface en lugar de Colors.white: correcto en light y dark.
        color:   cs.surface,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller:  controller,
                maxLines:    null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSubmit(),
                // Texto escrito: onSurface evita blanco sobre fondo claro.
                style: TextStyle(color: cs.onSurface),
                decoration:  InputDecoration(
                  hintText:      'Añadir un comentario…',
                  hintStyle:     TextStyle(color: cs.onSurfaceVariant),
                  border:        OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:   BorderSide.none,
                  ),
                  filled:        true,
                  fillColor:     cs.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            isSubmitting
                ? const SizedBox(
                    width:  36,
                    height: 36,
                    child:  CircularProgressIndicator(
                      color:       AppColors.primary,
                      strokeWidth: 2,
                    ),
                  )
                : IconButton(
                    icon:     const Icon(Icons.send_rounded),
                    color:    AppColors.primary,
                    onPressed: onSubmit,
                    tooltip:  'Enviar comentario',
                  ),
          ],
        ),
      ),
    );
  }
}

// ─── Menú contextual del post (AppBar) ────────────────────────────────────────

class _PostDetailMenu extends StatelessWidget {
  const _PostDetailMenu({
    required this.postId,
    required this.isAdmin,
    required this.isOwner,
  });

  final String postId;
  final bool   isAdmin;
  final bool   isOwner;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'report') {
          Navigator.of(context).pushNamed(
            AppRoutes.reportIncident,
            arguments: {'targetId': postId, 'type': 'post'},
          );
        } else if (value == 'delete') {
          try {
            // Admin usa endpoint /admin/posts/:id; el autor usa /community/:id.
            if (isAdmin) {
              await sl<AdminRemoteDataSource>().deletePost(postId);
            } else {
              await sl<PostRemoteDataSource>().deletePost(postId);
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Publicación eliminada.')),
              );
              Navigator.of(context).pop();
            }
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error al eliminar la publicación.')),
              );
            }
          }
        }
      },
      itemBuilder: (_) => [
        if (isAdmin || isOwner)
          const PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                SizedBox(width: 10),
                Text('Eliminar', style: TextStyle(color: AppColors.error)),
              ],
            ),
          ),
        if (!isOwner)
          const PopupMenuItem<String>(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.flag_outlined, size: 18),
                SizedBox(width: 10),
                Text('Reportar'),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Menú contextual de comentario ────────────────────────────────────────────

class _CommentMenu extends StatelessWidget {
  const _CommentMenu({
    required this.comment,
    required this.isAdmin,
    required this.isOwner,
  });

  final Comment comment;
  final bool    isAdmin;
  final bool    isOwner;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon:      const Icon(Icons.more_vert, size: 16),
      iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
      padding:   EdgeInsets.zero,
      onSelected: (value) async {
        if (value == 'report') {
          Navigator.of(context).pushNamed(
            AppRoutes.reportIncident,
            arguments: {'targetId': comment.id, 'type': 'comment'},
          );
        } else if (value == 'delete') {
          try {
            // Admin usa endpoint /admin/comments/:id; el autor usa /community/:postId/comments/:id.
            if (isAdmin) {
              await sl<AdminRemoteDataSource>().deleteComment(comment.id);
            } else {
              await sl<PostRemoteDataSource>().deleteComment(comment.postId, comment.id);
            }
            if (context.mounted) {
              // Actualización local: eliminar el comentario de la lista y decrementar
              // el contador sin recargar el post completo. El socket 'post:updated'
              // llegará después con el valor definitivo del servidor, evitando
              // un doble decremento por race condition entre loadPost y el socket.
              context.read<PostViewModel>().removeCommentLocally(comment.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Comentario eliminado.')),
              );
            }
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error al eliminar el comentario.')),
              );
            }
          }
        }
      },
      itemBuilder: (_) => [
        if (isAdmin || isOwner)
          const PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                SizedBox(width: 10),
                Text('Eliminar', style: TextStyle(color: AppColors.error)),
              ],
            ),
          ),
        if (!isOwner)
          const PopupMenuItem<String>(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.flag_outlined, size: 18),
                SizedBox(width: 10),
                Text('Reportar'),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Estado de error ──────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.postId});

  final AppError error;
  final String   postId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
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
            Text(
              'No se pudo cargar el post.',
              style:     Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.read<PostViewModel>().loadPost(postId),
              icon:  const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Badge de ticket de reporte ──────────────────────────────────────────────

/// Badge que muestra el identificador de incidencia "INC-XXX" en el AppBar.
/// Solo visible cuando un admin navega desde ReportsPage.
class _ReportTicketBadge extends StatelessWidget {
  const _ReportTicketBadge({required this.ticket});
  final String ticket;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        AppColors.warning.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.assignment_outlined, size: 14, color: AppColors.warning),
          const SizedBox(width: 4),
          Text(
            ticket,
            style: const TextStyle(
              fontSize:      11,
              fontWeight:    FontWeight.w700,
              color:         AppColors.warning,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
