/// @file conversations_viewmodel.dart
/// @description ViewModel de la lista de conversaciones del usuario.
/// Carga y refresca las conversaciones activas.
/// Depende SOLO de interfaces de use cases — nunca de implementaciones concretas.
/// @module Chat
/// @layer Presentation
library;

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../domain/entities/conversation.dart';
import '../../../domain/interfaces/usecases/chat/i_get_conversations_use_case.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CONVERSATIONS VIEWMODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// ViewModel de la lista de conversaciones. Extiende [ChangeNotifier] para Provider.
///
/// Estado gestionado:
///  - [conversations] — lista de conversaciones activas del usuario.
///  - [isLoading]     — true durante la carga inicial.
///  - [error]         — último error (null si no hay).
///
/// [implements] ChangeNotifier
/// [injectable] registerFactory en container.dart.
/// [dependencies] IGetConversationsUseCase.
class ConversationsViewModel extends ChangeNotifier {
  final IGetConversationsUseCase _getConversations;

  ConversationsViewModel({required IGetConversationsUseCase getConversationsUseCase})
      : _getConversations = getConversationsUseCase;

  // ─── Estado ───────────────────────────────────────────────────────────────────

  List<Conversation> _conversations = [];
  bool               _isLoading     = false;
  AppError?          _error;

  List<Conversation> get conversations => _conversations;
  bool               get isLoading     => _isLoading;
  AppError?          get error         => _error;

  bool get isEmpty => !_isLoading && _conversations.isEmpty && _error == null;

  /// true si alguna conversación tiene mensajes sin leer.
  ///
  /// Usado por `MainTabsPage` para mostrar el punto rojo en la pestaña
  /// Mensajes al volver a la app o al refrescar en segundo plano.
  bool get hasAnyUnread => _conversations.any((c) => c.hasUnread);

  // ─── Carga ────────────────────────────────────────────────────────────────────

  /// Carga las conversaciones del usuario con indicador de carga.
  ///
  /// Llamar desde el initState de ConversationsListPage.
  Future<void> loadConversations() async {
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      _conversations = await _getConversations.execute();
    } on AppError catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresca forzando recarga desde la API (pull-to-refresh + socket
  /// `message:received`). Salta el caché local con `forceRefresh: true`
  /// para que el nuevo unreadCount se vea al instante.
  Future<void> refresh() async {
    _error = null;
    try {
      _conversations = await _getConversations.execute(forceRefresh: true);
    } on AppError catch (e) {
      _error = e;
    } finally {
      notifyListeners();
    }
  }
}
