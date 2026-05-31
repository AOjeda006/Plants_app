/// @file post_card.dart
/// @description Tarjeta de post para el feed de la comunidad.
/// Muestra avatar del autor, imagen del post, contenido, y contadores de likes y comentarios.
/// Usa exclusivamente AppColors — nunca colores hardcodeados.
/// @module Community
/// @layer Presentation
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_theme.dart';
import '../../domain/entities/post.dart';
import 'image_viewer.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// POST CARD
// ═══════════════════════════════════════════════════════════════════════════════

/// Tarjeta de un post en el feed de la comunidad.
///
/// Recibe callbacks para manejar like, navegación al detalle y al perfil del autor.
/// No contiene estado propio — toda la lógica vive en el ViewModel.
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onAuthorTap,
    this.onLike,
    this.onReport,
    this.onDelete,
  });

  /// Post a mostrar.
  final Post post;

  /// Navegación al detalle del post.
  final VoidCallback onTap;

  /// Acción de toggle like/unlike. null = botón deshabilitado (request en vuelo).
  final VoidCallback? onLike;

  /// Navegación al perfil del autor.
  final VoidCallback onAuthorTap;

  /// Reportar el post (cualquier usuario). null = no mostrar opción.
  final VoidCallback? onReport;

  /// Eliminar el post (solo admin). null = no mostrar opción.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin:       const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation:    1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AuthorHeader(
              post:        post,
              onAuthorTap: onAuthorTap,
              onReport:    onReport,
              onDelete:    onDelete,
            ),
            if (post.hasImage)
              _PostImage(
                imageUrl:      post.image!,
                semanticLabel: 'Imagen del post de ${post.authorName}',
              ),
            _PostContent(content: post.content),
            _PostActions(post: post, onLike: onLike, onCommentTap: onTap),
          ],
        ),
      ),
    );
  }
}

// ─── Cabecera del autor ───────────────────────────────────────────────────────

class _AuthorHeader extends StatelessWidget {
  const _AuthorHeader({
    required this.post,
    required this.onAuthorTap,
    this.onReport,
    this.onDelete,
  });

  final Post          post;
  final VoidCallback  onAuthorTap;
  final VoidCallback? onReport;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAuthorTap,
            child: _AuthorAvatar(
              name:     post.authorName,
              photoUrl: post.authorPhoto,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onAuthorTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // onSurface: textPrimary en light, blanco×0.87 en dark.
                  Text(
                    post.authorName,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:      cs.onSurface,
                    ),
                    maxLines:  1,
                    overflow:  TextOverflow.ellipsis,
                  ),
                  // onSurfaceVariant: textSecondary en light, blanco×0.6 en dark.
                  Text(
                    _formatDate(post.createdAt),
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          if (onReport != null || onDelete != null)
            _PostMenu(onReport: onReport, onDelete: onDelete),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now  = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1)  return 'Ahora mismo';
    if (diff.inHours   < 1)  return 'Hace ${diff.inMinutes} min';
    if (diff.inDays    < 1)  return 'Hace ${diff.inHours} h';
    if (diff.inDays    < 7)  return 'Hace ${diff.inDays} d';
    return DateFormat('d MMM yyyy', 'es').format(date);
  }
}

// ─── Avatar del autor ─────────────────────────────────────────────────────────

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({required this.name, this.photoUrl});

  final String  name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius:           20,
        backgroundImage:  CachedNetworkImageProvider(photoUrl!),
        backgroundColor:  AppColors.surface,
      );
    }
    // Fallback: inicial del nombre sobre fondo primario.
    return CircleAvatar(
      radius:          20,
      backgroundColor: AppColors.primary,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color:      Colors.white,
          fontWeight: FontWeight.bold,
          fontSize:   16,
        ),
      ),
    );
  }
}

// ─── Menú contextual del post (⋮) ────────────────────────────────────────────

class _PostMenu extends StatelessWidget {
  const _PostMenu({this.onReport, this.onDelete});

  final VoidCallback? onReport;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon:        const Icon(Icons.more_vert, size: 20),
      iconColor:   Theme.of(context).colorScheme.onSurfaceVariant,
      onSelected:  (value) {
        if (value == 'report') onReport?.call();
        if (value == 'delete') onDelete?.call();
      },
      itemBuilder: (_) => [
        if (onDelete != null)
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
        if (onReport != null)
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

// ─── Imagen del post ──────────────────────────────────────────────────────────

class _PostImage extends StatelessWidget {
  const _PostImage({required this.imageUrl, this.semanticLabel});

  final String  imageUrl;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    // ConstrainedBox limita el ancho en web (>700px) y centra la imagen.
    // En móvil no tiene efecto porque la pantalla es más estrecha que maxWidth.
    return Semantics(
      label:  semanticLabel,
      image:  true,
      button: true,
      child: GestureDetector(
        onTap: () => showFullScreenImage(context, imageUrl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: CachedNetworkImage(
              imageUrl:    imageUrl,
              fit:         BoxFit.cover,
              width:       double.infinity,
              // Altura fija para mantener el aspecto del feed.
              height:      260,
              placeholder: (_, _) => Container(
                height: 260,
                color:  AppColors.surface,
                child:  const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              errorWidget: (_, _, _) => Container(
                height: 260,
                color:  AppColors.surface,
                child:  const Icon(Icons.broken_image_outlined, color: AppColors.textSecondary, size: 48),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Contenido textual ────────────────────────────────────────────────────────

class _PostContent extends StatelessWidget {
  const _PostContent({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Text(
        content,
        style:    Theme.of(context).textTheme.bodyMedium?.copyWith(
          // onSurface: contraste correcto en light y dark.
          color: Theme.of(context).colorScheme.onSurface,
        ),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ─── Barra de acciones (like, comentario) ─────────────────────────────────────

class _PostActions extends StatelessWidget {
  const _PostActions({
    required this.post,
    required this.onCommentTap,
    this.onLike,
  });

  final Post          post;
  final VoidCallback? onLike;   // null = botón deshabilitado (request en vuelo)
  final VoidCallback  onCommentTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: Row(
        children: [
          // Botón like — relleno si ya di like, contorno si no. Deshabilitado durante request.
          IconButton(
            icon: Icon(
              post.isLikedByMe
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
            ),
            color:     AppColors.error,
            onPressed: onLike,
            tooltip:   post.isLikedByMe ? 'Quitar like' : 'Me gusta',
          ),
          if (post.hasLikes)
            Text(
              '${post.likesCount}',
              style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          const SizedBox(width: 8),
          // Botón comentarios.
          IconButton(
            icon:     const Icon(Icons.chat_bubble_outline_rounded),
            color:    cs.onSurfaceVariant,
            onPressed: onCommentTap,
            tooltip:  'Comentarios',
          ),
          if (post.hasComments)
            Text(
              '${post.commentsCount}',
              style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          const Spacer(),
          // Fecha compacta en la esquina derecha.
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              _shortDate(post.createdAt),
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  String _shortDate(DateTime date) {
    final now  = DateTime.now();
    final diff = now.difference(date);
    if (diff.inHours < 1)  return '${diff.inMinutes}m';
    if (diff.inDays  < 1)  return '${diff.inHours}h';
    if (diff.inDays  < 7)  return '${diff.inDays}d';
    return DateFormat('d/MM').format(date);
  }
}
