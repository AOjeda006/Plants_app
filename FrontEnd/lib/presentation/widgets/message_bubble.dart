/// @file message_bubble.dart
/// @description Widget de burbuja de mensaje de chat. Muestra alineación,
/// estado de entrega y timestamp distintos para mensajes propios y ajenos.
/// @module Chat
/// @layer Presentation
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_theme.dart';
import '../../domain/entities/message.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MESSAGE BUBBLE
// ═══════════════════════════════════════════════════════════════════════════════

/// Burbuja que muestra un mensaje de chat.
///
/// Los mensajes propios se alinean a la derecha con fondo [AppColors.primary].
/// Los mensajes ajenos se alinean a la izquierda con fondo [AppColors.surface].
/// El estado de entrega se muestra como icono (⏱ pending, ✓ delivered, ✓✓ read).
class MessageBubble extends StatelessWidget {
  /// Mensaje a mostrar.
  final Message message;

  /// true si este mensaje fue enviado por el usuario actual.
  final bool isMine;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        child: Container(
          margin: EdgeInsets.only(
            left:   isMine ? 48.0 : 12.0,
            right:  isMine ? 12.0 : 48.0,
            top:     4.0,
            bottom:  4.0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          decoration: BoxDecoration(
            color:        isMine ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft:     const Radius.circular(16.0),
              topRight:    const Radius.circular(16.0),
              bottomLeft:  Radius.circular(isMine ? 16.0 : 4.0),
              bottomRight: Radius.circular(isMine ? 4.0  : 16.0),
            ),
            boxShadow: [
              BoxShadow(
                color:      Colors.black.withAlpha(18),
                blurRadius: 4.0,
                offset:     const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Texto del mensaje ────────────────────────────────────────
              if (message.hasText)
                Text(
                  message.text!,
                  style: TextStyle(
                    color:    isMine ? Colors.white : AppColors.textPrimary,
                    fontSize: 15.0,
                    height:   1.4,
                  ),
                ),

              const SizedBox(height: 4.0),

              // ── Timestamp + estado ───────────────────────────────────────
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(message.createdAt.toLocal()),
                    style: TextStyle(
                      color:    isMine
                          ? Colors.white.withAlpha(178)
                          : AppColors.textSecondary,
                      fontSize: 11.0,
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4.0),
                    _StatusIcon(status: message.status),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status Icon ──────────────────────────────────────────────────────────────

/// Icono que indica el estado de entrega de un mensaje propio.
///
/// 4 estados visuales:
///  - [pending]   → relojito (⏱)  — creado localmente, sin subir.
///  - [sent]      → un tick (✓)   — recibido por el servidor.
///  - [delivered] → dos ticks (✓✓) — entregado al destinatario.
///  - [read]      → dos ticks azules (✓✓) — leído por el destinatario.
class _StatusIcon extends StatelessWidget {
  final MessageStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.pending:
        return Icon(
          Icons.schedule,
          size:  12.0,
          color: Colors.white.withAlpha(178),
        );
      case MessageStatus.sent:
        return Icon(
          Icons.done,
          size:  14.0,
          color: Colors.white.withAlpha(178),
        );
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size:  14.0,
          color: Colors.white.withAlpha(178),
        );
      case MessageStatus.read:
        return Icon(
          Icons.done_all,
          size:  14.0,
          color: AppColors.accent,
        );
    }
  }
}
