/// @file chat_page.dart
/// @description Página de chat 1:1. Muestra mensajes en scroll invertido,
/// indicador de escritura, input de texto y soporte de actualización optimista.
/// @module Chat
/// @layer Presentation
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_theme.dart';
import '../../core/di/container.dart';
import '../../domain/entities/message.dart';
import '../viewmodels/auth/auth_viewmodel.dart';
import '../viewmodels/chat/chat_viewmodel.dart';
import '../widgets/message_bubble.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CHAT PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Página de conversación 1:1 entre el usuario actual y otro participante.
///
/// Argumentos de navegación (`Map<String, dynamic>`):
///  - 'conversationId'  — ID de la conversación.
///  - 'participantName' — nombre del otro usuario (AppBar).
///  - 'participantPhoto'? — URL de foto del participante.
///  - 'currentUserId'   — ID del usuario actual (para distinguir mensajes propios).
class ChatPage extends StatelessWidget {
  final String  conversationId;
  final String  participantName;
  final String? participantPhoto;
  final String  currentUserId;
  /// true cuando el otro participante eliminó su cuenta — la conversación queda en solo lectura.
  final bool    isParticipantDeleted;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.participantName,
    this.participantPhoto,
    required this.currentUserId,
    this.isParticipantDeleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatViewModel>(
      create: (_) {
        final vm = sl<ChatViewModel>();
        vm.initChat(
          conversationId:       conversationId,
          currentUserId:        currentUserId,
          participantName:      participantName,
          isParticipantDeleted: isParticipantDeleted,
        );
        return vm;
      },
      child: _ChatView(
        participantName:  participantName,
        participantPhoto: participantPhoto,
      ),
    );
  }
}

// ─── Vista ────────────────────────────────────────────────────────────────────

class _ChatView extends StatelessWidget {
  final String  participantName;
  final String? participantPhoto;

  const _ChatView({required this.participantName, this.participantPhoto});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _ChatAppBar(
        participantName:  participantName,
        participantPhoto: participantPhoto,
      ),
      // SafeArea lateral imprescindible en landscape móvil: la system bar
      // de Android queda a un lado y, sin esto, los mensajes y el input
      // se cortan bajo los iconos de back/home/recents. top/bottom quedan
      // en false porque el AppBar y el edge-to-edge ya los gestionan.
      body: SafeArea(
        top:    false,
        bottom: false,
        child: Column(
          children: [
            Expanded(child: _MessageList()),
            _TypingIndicator(),
            _MessageInput(),
          ],
        ),
      ),
    );
  }
}

// ─── AppBar del chat ──────────────────────────────────────────────────────────

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String  participantName;
  final String? participantPhoto;

  const _ChatAppBar({
    required this.participantName,
    this.participantPhoto,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          _SmallAvatar(name: participantName, photo: participantPhoto),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              participantName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize:   16.0,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lista de mensajes ────────────────────────────────────────────────────────

class _MessageList extends StatefulWidget {
  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  final ScrollController _scrollCtrl = ScrollController();

  // Contador de mensajes para detectar nuevas llegadas y auto-scroll.
  int _lastMsgCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    // Cargar mensajes antiguos cuando el usuario llega al inicio de la lista.
    if (_scrollCtrl.position.pixels <= 200) {
      context.read<ChatViewModel>().loadMore();
    }
  }

  /// Programa un scroll al final de la lista en el siguiente frame.
  ///
  /// [instant] — true en la carga inicial (sin animación).
  /// [instant] — false en mensajes nuevos (solo si ya estamos cerca del final).
  void _scheduleScrollToBottom({bool instant = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollCtrl.hasClients) return;
      final pos = _scrollCtrl.position;
      if (instant) {
        _scrollCtrl.jumpTo(pos.maxScrollExtent);
      } else if (pos.maxScrollExtent - pos.pixels < 150) {
        _scrollCtrl.animateTo(
          pos.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve:    Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();

    // Auto-scroll al llegar mensajes nuevos o completarse la carga inicial.
    if (vm.messages.length > _lastMsgCount) {
      final firstLoad = _lastMsgCount == 0;
      _lastMsgCount   = vm.messages.length;
      _scheduleScrollToBottom(instant: firstLoad);
    }

    if (vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (vm.error != null && vm.messages.isEmpty) {
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
              onPressed: () => context.read<ChatViewModel>().loadMessages(),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (vm.messages.isEmpty) {
      return const Center(
        child: Text(
          'Empieza la conversación',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      controller:  _scrollCtrl,
      padding:     const EdgeInsets.symmetric(vertical: 12.0),
      // Orden natural: índice 0 = más antiguo (top), último = más reciente (bottom).
      reverse:     false,
      itemCount:   (vm.hasMore ? 1 : 0) + vm.messages.length,
      itemBuilder: (ctx, i) {
        // Indicador de carga para mensajes más antiguos (al inicio de la lista).
        if (vm.hasMore && i == 0) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child:   Center(
              child: SizedBox(
                width:  20.0,
                height: 20.0,
                child:  CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color:       AppColors.primary,
                ),
              ),
            ),
          );
        }

        final msgIndex = vm.hasMore ? i - 1 : i;
        final msg = vm.messages[msgIndex];
        return MessageBubble(
          message: msg,
          isMine:  _isMine(vm, msg),
        );
      },
    );
  }

  /// Determina si el mensaje pertenece al usuario actual.
  ///
  /// TFG: usa senderId si currentUserId está disponible;
  /// si no, usa el tempId como señal de que lo enviamos nosotros.
  bool _isMine(ChatViewModel vm, Message msg) {
    return vm.isMyMessage(msg);
  }
}

// ─── Indicador de escritura ───────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isTyping = context.select<ChatViewModel, bool>((vm) => vm.isTyping);
    if (!isTyping) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      alignment: Alignment.centerLeft,
      child: const Text(
        'Escribiendo…',
        style: TextStyle(
          color:     AppColors.textSecondary,
          fontSize:  13.0,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

// ─── Input de mensaje ─────────────────────────────────────────────────────────

class _MessageInput extends StatefulWidget {
  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  final TextEditingController _ctrl      = TextEditingController();
  final FocusNode             _focusNode = FocusNode();
  bool                         _hasText  = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final hasText = _ctrl.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  /// Enter → enviar mensaje; Ctrl+Enter → insertar salto de línea.
  void _handleKeyEvent(KeyEvent event, BuildContext context) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey != LogicalKeyboardKey.enter &&
        event.logicalKey != LogicalKeyboardKey.numpadEnter) {
      return;
    }

    final isCtrl = HardwareKeyboard.instance.isControlPressed;

    if (isCtrl) {
      // Ctrl+Enter: insertar salto de línea en la posición del cursor.
      final sel  = _ctrl.selection;
      final text = _ctrl.text;
      final newText = text.replaceRange(sel.start, sel.end, '\n');
      _ctrl.value = TextEditingValue(
        text:      newText,
        selection: TextSelection.collapsed(offset: sel.start + 1),
      );
    } else {
      // Enter sin Ctrl: enviar mensaje.
      _send(context);
    }
  }

  Future<void> _send(BuildContext context) async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    setState(() => _hasText = false);
    await context.read<ChatViewModel>().sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final isSending  = context.select<ChatViewModel, bool>((vm) => vm.isSending);
    final isReadOnly = context.select<ChatViewModel, bool>((vm) => vm.isReadOnly);

    // Conversación de solo lectura: el participante eliminó su cuenta.
    if (isReadOnly) {
      return _ReadOnlyBar(message: 'Esta conversación es de solo lectura');
    }

    // Usuario baneado: puede leer pero no escribir.
    final currentUser = context.read<AuthViewModel>().currentUser;
    if (currentUser != null && currentUser.isBanned) {
      final until = currentUser.bannedUntil!;
      final formatted = '${until.day.toString().padLeft(2, "0")}/'
          '${until.month.toString().padLeft(2, "0")}/${until.year}';
      return _ReadOnlyBar(
        message: 'Cuenta suspendida hasta $formatted',
        icon:    Icons.block_rounded,
      );
    }

    return SafeArea(
      child: Container(
        padding:   const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        color:     Colors.white,
        child: Row(
          children: [
            Expanded(
              // Enter → enviar mensaje; Ctrl+Enter → salto de línea.
              child: KeyboardListener(
                focusNode:   _focusNode,
                onKeyEvent:  (event) => _handleKeyEvent(event, context),
                child: TextField(
                  controller:    _ctrl,
                  textCapitalization: TextCapitalization.sentences,
                  // a) Color de texto explícito para evitar blanco sobre fondo claro.
                  style:   const TextStyle(color: AppColors.textPrimary),
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:    'Escribe un mensaje…',
                    hintStyle:   const TextStyle(color: AppColors.textSecondary),
                    filled:      true,
                    fillColor:   AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical:    10.0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.0),
                      borderSide:   BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSending
                  ? const SizedBox(
                      width:  40.0,
                      height: 40.0,
                      child:  CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color:       AppColors.primary,
                      ),
                    )
                  : IconButton(
                      tooltip:  'Enviar mensaje',
                      onPressed: _hasText ? () => _send(context) : null,
                      icon: const Icon(Icons.send_rounded),
                      color: _hasText ? AppColors.primary : AppColors.textSecondary,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            _hasText ? AppColors.primary.withAlpha(26) : null,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Barra de solo lectura (participante eliminado o usuario baneado) ─────────

class _ReadOnlyBar extends StatelessWidget {
  const _ReadOnlyBar({required this.message, this.icon = Icons.lock_outline});

  final String   message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        color:   AppColors.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16.0, color: AppColors.textSecondary),
            const SizedBox(width: 8.0),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.0),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Avatar pequeño ───────────────────────────────────────────────────────────

class _SmallAvatar extends StatelessWidget {
  final String  name;
  final String? photo;

  const _SmallAvatar({required this.name, this.photo});

  @override
  Widget build(BuildContext context) {
    if (photo != null) {
      return CircleAvatar(
        radius:          18.0,
        backgroundImage: NetworkImage(photo!),
        // e) Fondo consistente mientras carga la imagen.
        backgroundColor: AppColors.primary,
      );
    }
    // e) Fallback igual al avatar de la lista de conversaciones.
    return CircleAvatar(
      radius:          18.0,
      backgroundColor: AppColors.primary,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color:      Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
