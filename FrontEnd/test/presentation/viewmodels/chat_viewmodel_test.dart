/// @file chat_viewmodel_test.dart
/// @description Tests unitarios para ChatViewModel.
/// Verifica carga de mensajes, envío optimista, reconciliación de tempId
/// y gestión de eventos de socket.
/// @module Chat
/// @layer Presentation
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:plants_app/core/errors/app_error.dart';
import 'package:plants_app/core/network/socket_client.dart';
import 'package:plants_app/domain/entities/message.dart';
import 'package:plants_app/domain/interfaces/usecases/chat/i_get_messages_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/chat/i_send_message_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/chat/i_mark_messages_as_read_use_case.dart';
import 'package:plants_app/presentation/viewmodels/chat/chat_viewmodel.dart';

// ─── Mocks manuales ───────────────────────────────────────────────────────────

class _MockGetMessages implements IGetMessagesUseCase {
  List<Message> returnValue = [];
  AppError? throwError;

  @override
  Future<List<Message>> execute(
    String conversationId, {
    int page  = 1,
    int limit = 30,
  }) async {
    if (throwError != null) throw throwError!;
    return returnValue;
  }
}

class _MockSendMessage implements ISendMessageUseCase {
  Message? returnValue;
  AppError? throwError;

  @override
  Future<Message> execute(
    String conversationId,
    String content, {
    String? tempId,
  }) async {
    if (throwError != null) throw throwError!;
    return returnValue!;
  }
}

class _MockMarkRead implements IMarkMessagesAsReadUseCase {
  @override
  Future<void> execute(String conversationId) async {}
}

/// Mock de SocketClient: captura los handlers registrados para simular eventos.
/// Extiende la clase concreta sobreescribiendo solo los métodos necesarios.
class _MockSocketClient extends SocketClient {
  final Map<String, void Function(dynamic)> _handlers = {};

  _MockSocketClient() : super(tokenProvider: () async => 'test-token');

  @override
  void on(String event, void Function(dynamic data) handler) {
    _handlers[event] = handler;
  }

  @override
  void off(String event, [void Function(dynamic data)? handler]) {
    _handlers.remove(event);
  }

  @override
  void emit(String event, [dynamic data]) {
    // no-op en tests — el envío real al socket se omite.
  }

  /// Simula la recepción de un evento del servidor.
  void simulateEvent(String event, dynamic data) {
    _handlers[event]?.call(data);
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

const _convId     = 'conv-001';
const _senderId   = 'sender-001';
final _now        = DateTime.utc(2026, 3, 5, 10, 0);

Message _makeMessage({
  String id             = 'msg-001',
  String? tempId,
  MessageStatus status  = MessageStatus.delivered,
  String text           = 'Hola',
}) =>
    Message(
      id:             id,
      conversationId: _convId,
      senderId:       _senderId,
      senderName:     'Sender',
      text:           text,
      status:         status,
      tempId:         tempId,
      createdAt:      _now,
    );

ChatViewModel _makeViewModel({
  _MockGetMessages?  get,
  _MockSendMessage?  send,
  _MockMarkRead?     mark,
  _MockSocketClient? socket,
}) {
  return ChatViewModel(
    getMessagesUseCase:        get    ?? _MockGetMessages(),
    sendMessageUseCase:        send   ?? _MockSendMessage(),
    markMessagesAsReadUseCase: mark   ?? _MockMarkRead(),
    socketClient:              socket ?? _MockSocketClient(),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  // ── initChat / loadMessages ───────────────────────────────────────────────────

  group('loadMessages()', () {
    test('debe cargar mensajes en orden inverso (más reciente primero)', () async {
      final msgs = [
        _makeMessage(id: 'msg-1', text: 'Primero'),
        _makeMessage(id: 'msg-2', text: 'Segundo'),
        _makeMessage(id: 'msg-3', text: 'Tercero'),
      ];
      final get = _MockGetMessages()..returnValue = msgs;
      final vm  = _makeViewModel(get: get);

      vm.initChat(
        conversationId:  _convId,
        currentUserId:   _senderId,
        participantName: 'Alice',
      );
      // Esperar a que loadMessages complete.
      await Future<void>.delayed(Duration.zero);

      expect(vm.messages.length, 3);
      // El más reciente (último en la lista original) debe estar en índice 0.
      expect(vm.messages.first.id, 'msg-3');
      expect(vm.isLoading, isFalse);
    });

    test('debe guardar el error si la carga falla', () async {
      final get = _MockGetMessages()..throwError = AppError.network();
      final vm  = _makeViewModel(get: get);

      await vm.loadMessages();

      expect(vm.messages, isEmpty);
      expect(vm.error, isNotNull);
    });
  });

  // ── sendMessage ───────────────────────────────────────────────────────────────

  group('sendMessage()', () {
    test('debe insertar mensaje optimista con estado pending antes de confirmar', () async {
      final confirmed = _makeMessage(id: 'real-001', tempId: 'temp-001');
      final send = _MockSendMessage()..returnValue = confirmed;
      final vm   = _makeViewModel(send: send);

      vm.initChat(
        conversationId: _convId, currentUserId: _senderId, participantName: 'Alice',
      );
      await Future<void>.delayed(Duration.zero);

      // Verificar que el mensaje se reconcilió con el ID real.
      final sendFuture = vm.sendMessage('Hola');
      // Mientras el Future no termina, debería haber un mensaje pending al inicio.
      expect(vm.messages.first.isPending, isTrue);

      await sendFuture;

      expect(vm.isSending, isFalse);
      // El mensaje final debe tener el ID real.
      expect(vm.messages.first.id, 'real-001');
      expect(vm.messages.first.isDelivered, isTrue);
    });

    test('debe ignorar texto vacío o solo espacios', () async {
      final vm = _makeViewModel();
      final initialCount = vm.messages.length;

      await vm.sendMessage('   ');
      expect(vm.messages.length, initialCount);
    });

    test('debe mantener el mensaje como pending si la API falla', () async {
      final send = _MockSendMessage()..throwError = AppError.network();
      final vm   = _makeViewModel(send: send);

      vm.initChat(
        conversationId: _convId, currentUserId: _senderId, participantName: 'Alice',
      );
      await Future<void>.delayed(Duration.zero);

      await vm.sendMessage('Mensaje que falla');

      expect(vm.messages.isNotEmpty, isTrue);
      // El mensaje optimista debe quedar con estado pending.
      expect(vm.messages.first.isPending, isTrue);
      expect(vm.error, isNotNull);
    });
  });

  // ── isMyMessage ───────────────────────────────────────────────────────────────

  group('isMyMessage()', () {
    test('debe devolver true si el senderId coincide con el usuario actual', () async {
      final vm = _makeViewModel();
      vm.initChat(
        conversationId: _convId, currentUserId: _senderId, participantName: 'Alice',
      );
      await Future<void>.delayed(Duration.zero);

      final msg = _makeMessage(id: 'msg-1');
      expect(vm.isMyMessage(msg), isTrue);
    });

    test('debe devolver false si el senderId no coincide', () async {
      final vm = _makeViewModel();
      vm.initChat(
        conversationId: _convId, currentUserId: 'otro-user', participantName: 'Alice',
      );
      await Future<void>.delayed(Duration.zero);

      final msg = _makeMessage(id: 'msg-1');
      expect(vm.isMyMessage(msg), isFalse);
    });
  });

  // ── socket: message:new ───────────────────────────────────────────────────────

  group('socket message:new', () {
    test('debe añadir el mensaje entrante al inicio de la lista', () async {
      final socket = _MockSocketClient();
      final vm     = _makeViewModel(socket: socket);

      vm.initChat(
        conversationId: _convId, currentUserId: _senderId, participantName: 'Alice',
      );
      await Future<void>.delayed(Duration.zero);

      socket.simulateEvent('message:received', {
        'id':             'incoming-001',
        'conversationId': _convId,
        'senderId':       'other-user',
        'senderName':     'Alice',
        'text':           'Hola de vuelta',
        'createdAt':      _now.toIso8601String(),
      });

      expect(vm.messages.isNotEmpty, isTrue);
      expect(vm.messages.first.id, 'incoming-001');
    });

    test('debe ignorar mensajes de otras conversaciones', () async {
      final socket = _MockSocketClient();
      final vm     = _makeViewModel(socket: socket);

      vm.initChat(
        conversationId: _convId, currentUserId: _senderId, participantName: 'Alice',
      );
      await Future<void>.delayed(Duration.zero);

      socket.simulateEvent('message:received', {
        'id':             'other-conv-msg',
        'conversationId': 'otra-conv-999',
        'senderId':       'other-user',
        'senderName':     'Bob',
        'text':           'No debería aparecer',
        'createdAt':      _now.toIso8601String(),
      });

      expect(vm.messages, isEmpty);
    });
  });

  // ── socket: message:read ────────────────────────────────────────────────────

  group('socket message:read', () {
    test('debe marcar todos los mensajes propios como read', () async {
      final get    = _MockGetMessages()..returnValue = [
        _makeMessage(id: 'msg-1', status: MessageStatus.delivered),
        _makeMessage(id: 'msg-2', status: MessageStatus.delivered),
      ];
      final socket = _MockSocketClient();
      final vm     = _makeViewModel(get: get, socket: socket);

      vm.initChat(
        conversationId: _convId, currentUserId: _senderId, participantName: 'Alice',
      );
      await Future<void>.delayed(Duration.zero);

      expect(vm.messages.length, 2);
      expect(vm.messages.every((m) => m.isDelivered), isTrue);

      // Simular que el receptor leyó los mensajes.
      socket.simulateEvent('message:read', {
        'conversationId': _convId,
      });

      // Todos los mensajes propios deben cambiar a read.
      expect(vm.messages.every((m) => m.isRead), isTrue);
    });

    test('debe ignorar message:read de otra conversación', () async {
      final get    = _MockGetMessages()..returnValue = [
        _makeMessage(id: 'msg-1', status: MessageStatus.delivered),
      ];
      final socket = _MockSocketClient();
      final vm     = _makeViewModel(get: get, socket: socket);

      vm.initChat(
        conversationId: _convId, currentUserId: _senderId, participantName: 'Alice',
      );
      await Future<void>.delayed(Duration.zero);

      socket.simulateEvent('message:read', {
        'conversationId': 'otra-conv',
      });

      // No debe cambiar a read — la conversación no coincide.
      expect(vm.messages.first.isDelivered, isTrue);
    });
  });
}
