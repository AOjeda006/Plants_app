/// @file chat_viewmodel.dart
/// @description ViewModel del chat 1:1. Gestiona carga de mensajes, envío con
/// actualizaciones optimistas, reconciliación de tempId y eventos en tiempo real
/// via Socket.IO. Depende SOLO de interfaces de use cases.
/// @module Chat
/// @layer Presentation
library;

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/network/socket_client.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/interfaces/usecases/chat/i_get_messages_use_case.dart';
import '../../../domain/interfaces/usecases/chat/i_mark_messages_as_read_use_case.dart';
import '../../../domain/interfaces/usecases/chat/i_send_message_use_case.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CHAT VIEWMODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// ViewModel del chat 1:1 entre dos usuarios.
///
/// Estado gestionado:
///  - [messages]      — lista de mensajes en orden cronológico inverso (índice 0 = más reciente).
///  - [isLoading]     — true durante la carga inicial.
///  - [isSending]     — true mientras se envía un mensaje.
///  - [isTyping]      — true cuando el otro usuario está escribiendo.
///  - [hasMore]       — true si hay mensajes anteriores por cargar.
///  - [error]         — último error (null si no hay).
///
/// Flujo de envío optimista:
///  1. Se añade un [Message] local con tempId y estado [MessageStatus.pending].
///  2. Se envía via REST.
///  3. Al confirmar, se reconcilia: tempId → id real, estado → delivered.
///  4. En error de red: el mensaje permanece pending y se encola offline.
///
/// [implements] ChangeNotifier
/// [injectable] registerFactory en container.dart.
/// [dependencies] IGetMessagesUseCase, ISendMessageUseCase, IMarkMessagesAsReadUseCase, SocketClient.
class ChatViewModel extends ChangeNotifier {
  final IGetMessagesUseCase        _getMessages;
  final ISendMessageUseCase        _sendMessage;
  final IMarkMessagesAsReadUseCase _markRead;
  final SocketClient               _socket;
  final Uuid                       _uuid = const Uuid();

  ChatViewModel({
    required IGetMessagesUseCase        getMessagesUseCase,
    required ISendMessageUseCase        sendMessageUseCase,
    required IMarkMessagesAsReadUseCase markMessagesAsReadUseCase,
    required SocketClient               socketClient,
  })  : _getMessages = getMessagesUseCase,
        _sendMessage  = sendMessageUseCase,
        _markRead     = markMessagesAsReadUseCase,
        _socket       = socketClient;

  // ─── Estado ───────────────────────────────────────────────────────────────────

  String         _conversationId  = '';
  String         _currentUserId   = '';
  String         _participantName = '';
  List<Message>  _messages        = [];
  bool           _isLoading       = false;
  bool           _isSending       = false;
  bool           _isTyping        = false;
  bool           _hasMore         = true;
  bool           _isReadOnly      = false;
  bool           _disposed        = false;
  int            _page            = 1;
  AppError?      _error;

  String         get conversationId  => _conversationId;
  String         get participantName => _participantName;
  List<Message>  get messages        => _messages;
  bool           get isLoading       => _isLoading;
  bool           get isSending       => _isSending;
  bool           get isTyping        => _isTyping;
  bool           get hasMore         => _hasMore;
  /// true cuando el otro participante ha eliminado su cuenta: no se pueden enviar mensajes.
  bool           get isReadOnly      => _isReadOnly;
  AppError?      get error           => _error;

  /// true si [msg] fue enviado por el usuario actual.
  bool isMyMessage(Message msg) => msg.senderId == _currentUserId;

  // ─── Inicialización ───────────────────────────────────────────────────────────

  /// Inicializa el chat con el contexto de conversación y usuario actual.
  ///
  /// Llamar desde el initState de ChatPage antes de cargar datos.
  ///
  /// [param] conversationId — ID de la conversación.
  /// [param] currentUserId  — ID del usuario autenticado (para identificar mensajes propios).
  /// [param] participantName — nombre del otro participante (para la AppBar).
  void initChat({
    required String conversationId,
    required String currentUserId,
    required String participantName,
    bool isParticipantDeleted = false,
  }) {
    _conversationId  = conversationId;
    _currentUserId   = currentUserId;
    _participantName = participantName;
    _isReadOnly      = isParticipantDeleted;
    _subscribeToSocket();
    loadMessages();
    _markAsRead();
  }

  // ─── Carga de mensajes ────────────────────────────────────────────────────────

  /// Carga la primera página de mensajes.
  Future<void> loadMessages() async {
    _isLoading = true;
    _error     = null;
    _page      = 1;
    notifyListeners();

    try {
      final msgs = await _getMessages.execute(
        _conversationId,
        page:  1,
        limit: 30,
      );
      // Ordenar ascendente: índice 0 = más antiguo, último = más reciente (ListView normal).
      _messages = msgs.reversed.toList();
      _hasMore  = msgs.length >= 30;
      _page     = 2;
    } on AppError catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga la siguiente página de mensajes (scroll hacia arriba).
  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) return;

    try {
      final msgs = await _getMessages.execute(
        _conversationId,
        page:  _page,
        limit: 30,
      );
      // Prepend: mensajes más antiguos van al inicio de la lista (oldest-first).
      _messages = [...msgs.reversed, ..._messages];
      _hasMore  = msgs.length >= 30;
      _page++;
      notifyListeners();
    } on AppError {
      // Silencioso: si falla la paginación, simplemente no carga más.
    }
  }

  // ─── Envío de mensaje ─────────────────────────────────────────────────────────

  /// Envía un mensaje de texto con actualización optimista.
  ///
  /// El mensaje se añade inmediatamente como [MessageStatus.pending] y se
  /// reconcilia con la respuesta del servidor cuando llega la confirmación.
  ///
  /// [param] text — contenido del mensaje.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final tempId = _uuid.v4();

    // 1. Insertar mensaje optimista al final (más reciente → bottom).
    final optimistic = Message(
      id:             tempId,
      conversationId: _conversationId,
      senderId:       _currentUserId,
      // Mensaje saliente del propio usuario: las burbujas propias van
      // alineadas a la derecha sin avatar ni etiqueta de nombre, por lo
      // que `senderName` no se renderiza en ningún sitio para mensajes
      // con `isMine=true`. Lo dejamos vacío en el optimistic; el
      // servidor lo enriquece al persistir y los siguientes fetches lo
      // traen poblado.
      senderName:     '',
      text:           trimmed,
      status:         MessageStatus.pending,
      tempId:         tempId,
      createdAt:      DateTime.now().toUtc(),
    );
    _messages  = [..._messages, optimistic];
    _isSending = true;
    notifyListeners();

    try {
      // 2. Enviar a la API.
      final confirmed = await _sendMessage.execute(
        _conversationId,
        trimmed,
        tempId: tempId,
      );
      // 3. Reconciliar: reemplazar el mensaje optimista con el real.
      _messages = _messages
          .map((m) => m.tempId == tempId ? confirmed : m)
          .toList();
    } on AppError catch (e) {
      // 4. En error: el mensaje permanece pending; offline queue lo reintentará.
      _error = e;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  // ─── Socket ───────────────────────────────────────────────────────────────────

  void _subscribeToSocket() {
    _socket.on('message:received',       _onMessageNew);
    _socket.on('message:ack',       _onMessageAck);
    _socket.on('message:delivered', _onMessageDelivered);
    _socket.on('message:read',      _onMessageRead);
    _socket.on('typing',            _onTyping);
  }

  /// Recibe un mensaje nuevo del otro usuario enviado por el servidor via push.
  void _onMessageNew(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    if (map['conversationId'] != _conversationId) return;

    final incoming = Message(
      id:             map['id']             as String? ?? '',
      conversationId: map['conversationId'] as String? ?? '',
      senderId:       map['senderId']       as String? ?? '',
      senderName:     map['senderName']     as String? ?? '',
      text:           map['text']           as String?,
      status:         MessageStatus.delivered,
      createdAt:      DateTime.parse(
        map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ).toUtc(),
    );

    _messages = [..._messages, incoming];
    notifyListeners();
    _markAsRead();
  }

  /// Recibe confirmación del servidor sobre un mensaje enviado (reconciliación tempId).
  /// El estado pasa a 'sent' (un tick): el servidor ha recibido y persistido el mensaje.
  void _onMessageAck(dynamic data) {
    if (data is! Map) return;
    final map    = Map<String, dynamic>.from(data);
    final tempId = map['tempId'] as String?;
    final realId = map['id']     as String?;
    if (tempId == null || realId == null) return;

    _messages = _messages.map((m) {
      if (m.tempId == tempId) {
        return m.copyWith(id: realId, status: MessageStatus.sent);
      }
      return m;
    }).toList();
    notifyListeners();
  }

  /// Recibe evento 'message:delivered': el destinatario ha recibido el mensaje vía Socket.
  /// El estado pasa a 'delivered' (dos ticks).
  void _onMessageDelivered(dynamic data) {
    if (data is! Map) return;
    final map       = Map<String, dynamic>.from(data);
    final messageId = map['messageId'] as String?;
    final convId    = map['conversationId'] as String?;
    if (convId != _conversationId) return;

    if (messageId != null) {
      // Actualizar un mensaje específico
      _messages = _messages.map((m) {
        if (m.id == messageId && m.status != MessageStatus.read) {
          return m.copyWith(status: MessageStatus.delivered);
        }
        return m;
      }).toList();
    }
    notifyListeners();
  }

  /// Recibe evento 'message:read': el destinatario ha leído los mensajes de la conversación.
  /// Todos los mensajes propios pasan a 'read' (dos ticks azules).
  void _onMessageRead(dynamic data) {
    if (data is! Map) return;
    final map    = Map<String, dynamic>.from(data);
    final convId = map['conversationId'] as String?;
    if (convId != _conversationId) return;

    _messages = _messages.map((m) {
      if (m.senderId == _currentUserId && m.status != MessageStatus.read) {
        return m.copyWith(status: MessageStatus.read);
      }
      return m;
    }).toList();
    notifyListeners();
  }

  /// Recibe el indicador de escritura del otro usuario.
  void _onTyping(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    if (map['conversationId'] != _conversationId) return;

    _isTyping = map['isTyping'] as bool? ?? false;
    notifyListeners();

    // Auto-reset tras 3 s por si el evento 'typing:stop' no llega.
    if (_isTyping) {
      Future.delayed(const Duration(seconds: 3), () {
        if (_isTyping && !_disposed) {
          _isTyping = false;
          notifyListeners();
        }
      });
    }
  }

  // ─── Mark as read ─────────────────────────────────────────────────────────────

  void _markAsRead() {
    if (_conversationId.isEmpty) return;
    _markRead.execute(_conversationId).ignore();
  }

  // ─── Dispose ──────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _disposed = true;
    _socket.off('message:received',       _onMessageNew);
    _socket.off('message:ack',       _onMessageAck);
    _socket.off('message:delivered', _onMessageDelivered);
    _socket.off('message:read',      _onMessageRead);
    _socket.off('typing',            _onTyping);
    super.dispose();
  }
}
