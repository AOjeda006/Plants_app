/// @file text_post_card.dart
/// @description Card de post de texto (sin foto) para el perfil de usuario.
/// Muestra caption, fecha relativa y contadores de likes/comentarios.
/// @module Community
/// @layer Presentation
library;

import 'package:flutter/material.dart';

import '../../core/config/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/post.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// TEXT POST CARD
// ═══════════════════════════════════════════════════════════════════════════════

/// Card de post de solo texto en el perfil de usuario.
///
/// Usa fondo [AppColors.surface] con padding generoso, texto de caption
/// prominente (16 sp), fecha relativa gris, y contadores de likes/comentarios
/// al pie para dar aspecto de "nota" o "thread".
class TextPostCard extends StatelessWidget {
  const TextPostCard({
    super.key,
    required this.post,
    this.onTap,
  });

  final Post          post;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Card(
      color:       AppColors.surface,
      elevation:   0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contenido del post.
              // Color explícito para garantizar legibilidad sobre AppColors.surface
              // independientemente del tema del contexto padre.
              Text(
                post.content,
                maxLines:  8,
                overflow:  TextOverflow.ellipsis,
                style: tt.bodyLarge?.copyWith(
                  fontSize:   16,
                  height:     1.5,
                  color:      AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Pie: fecha y contadores.
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    PlantDateUtils.relativeDay(post.createdAt),
                    style: tt.labelSmall?.copyWith(color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  _Counter(
                    icon:  Icons.favorite_rounded,
                    count: post.likesCount,
                    color: post.isLikedByMe ? AppColors.error : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  _Counter(
                    icon:  Icons.chat_bubble_outline_rounded,
                    count: post.commentsCount,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Contador pequeño de likes o comentarios ──────────────────────────────────

class _Counter extends StatelessWidget {
  const _Counter({
    required this.icon,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final int      count;
  final Color    color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          '$count',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
