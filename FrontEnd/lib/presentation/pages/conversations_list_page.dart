/// @file conversations_list_page.dart
/// @description Página de lista de conversaciones activas del usuario.
/// Muestra preview de último mensaje, badge de no leídos y navega al chat.
/// @module Chat
/// @layer Presentation
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_theme.dart';
import '../../core/di/container.dart';
import '../../domain/entities/conversation.dart';
import '../routes/app_router.dart';
import '../viewmodels/auth/auth_viewmodel.dart';
import '../viewmodels/chat/conversations_viewmodel.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CONVERSATIONS LIST PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Página principal del módulo de chat: lista de conversaciones activas.
///
/// Carga las conversaciones via [ConversationsViewModel] y navega al
/// [ChatPage] al pulsar una conversación.
class ConversationsListPage extends StatelessWidget {
  const ConversationsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // `ConversationsViewModel` está registrado como singleton — usamos
    // `.value` para reutilizar la instancia que MainTabsPage refresca al
    // recibir `message:received` por socket. Al montar, disparamos un
    // refresh sin loading para garantizar datos frescos al abrir la
    // pestaña.
    final vm = sl<ConversationsViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (vm.conversations.isEmpty && !vm.isLoading) {
        vm.loadConversations();
      } else {
        // Cargar en segundo plano (sin pisar la lista actual).
        vm.refresh();
      }
    });
    return ChangeNotifierProvider<ConversationsViewModel>.value(
      value: vm,
      child: const _ConversationsView(),
    );
  }
}

// ─── Vista ────────────────────────────────────────────────────────────────────

class _ConversationsView extends StatelessWidget {
  const _ConversationsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Mensajes'),
      ),
      body: _Body(),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ConversationsViewModel>();

    if (vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (vm.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48.0),
            const SizedBox(height: 12.0),
            Text(
              vm.error!.message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () => context.read<ConversationsViewModel>().loadConversations(),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (vm.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 72.0, color: AppColors.textSecondary),
            SizedBox(height: 16.0),
            Text(
              'Sin conversaciones todavía',
              style: TextStyle(
                color:    AppColors.textSecondary,
                fontSize: 16.0,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              'Visita el perfil de un usuario y envíale un mensaje.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.0),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color:     AppColors.primary,
      onRefresh: () => context.read<ConversationsViewModel>().refresh(),
      child: ListView.builder(
        padding:   const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        itemCount: vm.conversations.length,
        itemBuilder: (ctx, i) => _ConversationTile(
          conversation: vm.conversations[i],
        ),
      ),
    );
  }
}

// ─── Conversation Tile ────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;

  const _ConversationTile({required this.conversation});

  Future<void> _navigate(BuildContext context) async {
    // b) Usar AuthViewModel para el userId actual — más fiable que decodificar el JWT.
    final currentUserId =
        context.read<AuthViewModel>().currentUser?.id ?? '';

    await Navigator.pushNamed(
      context,
      AppRoutes.chat,
      arguments: {
        'conversationId':       conversation.id,
        'participantName':      conversation.participantName,
        'participantPhoto':     conversation.participantPhoto,
        'currentUserId':        currentUserId,
        'isParticipantDeleted': conversation.isParticipantDeleted,
      },
    );

    // Refrescar la lista tras volver del chat (unreadCount puede haber cambiado).
    if (context.mounted) {
      context.read<ConversationsViewModel>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: AppColors.textSecondary.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      onTap: () => _navigate(context),
      leading: _Avatar(
        name:  conversation.participantName,
        photo: conversation.participantPhoto,
      ),
      title: Text(
        conversation.participantName,
        style: TextStyle(
          fontWeight: conversation.hasUnread
              ? FontWeight.w700
              : FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: conversation.isParticipantDeleted && !conversation.hasLastMessage
          ? const Text(
              'Cuenta eliminada · Solo lectura',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.0),
            )
          : conversation.hasLastMessage
              ? Text(
                  conversation.lastMessageText!,
                  maxLines:  1,
                  overflow:  TextOverflow.ellipsis,
                  style:     TextStyle(
                    color:      conversation.hasUnread
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: conversation.hasUnread
                        ? FontWeight.w500
                        : FontWeight.normal,
                    fontSize: 13.0,
                  ),
                )
              : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (conversation.isParticipantDeleted)
            const Icon(Icons.lock_outline, size: 14.0, color: AppColors.textSecondary),
          if (conversation.lastMessageAt != null) ...[
            if (conversation.isParticipantDeleted) const SizedBox(height: 4.0),
            Text(
              _formatTime(conversation.lastMessageAt!),
              style: TextStyle(
                color:    conversation.hasUnread
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontSize: 11.0,
                fontWeight: conversation.hasUnread
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
          if (conversation.hasUnread) ...[
            const SizedBox(height: 4.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
              decoration: const BoxDecoration(
                color:        AppColors.primary,
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(
                  color:     Colors.white,
                  fontSize:  11.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now  = DateTime.now();
    final local = dt.toLocal();
    if (local.day == now.day &&
        local.month == now.month &&
        local.year == now.year) {
      return DateFormat('HH:mm').format(local);
    }
    return DateFormat('dd/MM').format(local);
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String  name;
  final String? photo;

  const _Avatar({required this.name, this.photo});

  @override
  Widget build(BuildContext context) {
    if (photo != null) {
      return CircleAvatar(
        radius:           24.0,
        backgroundImage:  NetworkImage(photo!),
        backgroundColor:  AppColors.surface,
      );
    }
    return CircleAvatar(
      radius:          24.0,
      backgroundColor: AppColors.primary,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color:      Colors.white,
          fontWeight: FontWeight.w600,
          fontSize:   18.0,
        ),
      ),
    );
  }
}
