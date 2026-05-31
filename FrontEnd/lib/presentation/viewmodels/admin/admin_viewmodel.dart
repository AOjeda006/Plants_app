/// @file admin_viewmodel.dart
/// @description ViewModel compartido para las pantallas de administración.
/// Gestiona reports, deleted items y diagnostics del sistema.
/// @module Admin
/// @layer Presentation
library;

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/network/socket_client.dart';
import '../../../data/datasources/remote/admin_remote_data_source.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ADMIN VIEWMODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// ViewModel para las pantallas de administración.
///
/// Estado gestionado:
///  - [reports]      — estadísticas de la plataforma.
///  - [deletedItems] — elementos eliminados (soft-delete).
///  - [diagnostics]  — diagnóstico del servidor.
///  - [isLoading]    — carga en curso.
///  - [error]        — último error.
///
/// [injectable] registrar en container.dart como factory.
/// [dependencies] AdminRemoteDataSource, SocketClient.
class AdminViewModel extends ChangeNotifier {
  final AdminRemoteDataSource _dataSource;
  final SocketClient          _socketClient;

  AdminViewModel({
    required AdminRemoteDataSource dataSource,
    required SocketClient          socketClient,
  })  : _dataSource    = dataSource,
        _socketClient  = socketClient;

  // ─── Estado ───────────────────────────────────────────────────────────────

  Map<String, dynamic>? _reports;
  Map<String, dynamic>? _deletedItems;
  Map<String, dynamic>? _diagnostics;
  List<dynamic>         _incidentReports = [];
  bool                  _isLoading       = false;
  bool                  _isRestoring     = false;
  bool                  _isSubmitting    = false;
  AppError?             _error;

  Map<String, dynamic>? get reports         => _reports;
  Map<String, dynamic>? get deletedItems    => _deletedItems;
  Map<String, dynamic>? get diagnostics     => _diagnostics;
  List<dynamic>         get incidentReports => _incidentReports;
  bool                  get isLoading       => _isLoading;
  bool                  get isRestoring     => _isRestoring;
  bool                  get isSubmitting    => _isSubmitting;
  AppError?             get error           => _error;

  // ─── Estado de infraestructura ────────────────────────────────────────────

  /// true si el socket WebSocket está conectado.
  bool get socketConnected => _socketClient.isConnected;

  /// La "cola offline" se eliminó; el getter siempre devuelve 0 y se
  /// conserva como stub temporal para no romper la UI del dashboard de
  /// admin que aún lo consulta.
  int get offlineQueueCount => 0;

  // ─── Cargar datos ─────────────────────────────────────────────────────────

  /// Número de reportes de incidencias con status 'pending'.
  int get pendingReportsCount => _incidentReports
      .whereType<Map<String, dynamic>>()
      .where((r) => r['status'] == 'pending')
      .length;

  /// Carga diagnostics e incident reports en paralelo.
  Future<void> loadDashboard() async {
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      final results = await Future.wait<Object>([
        _dataSource.getDiagnostics(),
        _dataSource.getIncidentReports(),
      ]);
      _diagnostics     = results[0] as Map<String, dynamic>;
      _incidentReports = results[1] as List<dynamic>;
    } on AppError catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga la lista de elementos eliminados.
  Future<void> loadDeletedItems() async {
    _isLoading    = true;
    _deletedItems = null;
    _error        = null;
    notifyListeners();

    try {
      _deletedItems = await _dataSource.getDeletedItems();
    } on AppError catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga solo los reports.
  Future<void> loadReports() async {
    _isLoading = true;
    _reports   = null;
    _error     = null;
    notifyListeners();

    try {
      _reports = await _dataSource.getReports();
    } on AppError catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Restaurar elemento ───────────────────────────────────────────────────

  /// Restaura un elemento eliminado. Devuelve true si fue exitoso.
  ///
  /// [type]   — 'user' | 'plant' | 'post'.
  /// [itemId] — ID del elemento.
  Future<bool> restoreItem(String type, String itemId) async {
    _isRestoring = true;
    _error       = null;
    notifyListeners();

    try {
      await _dataSource.restoreItem(type, itemId);
      // Recargar la lista tras restaurar.
      await loadDeletedItems();
      return true;
    } on AppError catch (e) {
      _error = e;
      return false;
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  // ─── Reportes de incidencias ──────────────────────────────────────────────

  // ─── Filtros de reportes ───────────────────────────────────────────────────

  int?    _filterTicketNumber;
  String? _filterStatus;
  String? _filterFrom;
  String? _filterTo;

  int?    get filterTicketNumber => _filterTicketNumber;
  String? get filterStatus      => _filterStatus;
  String? get filterFrom        => _filterFrom;
  String? get filterTo          => _filterTo;

  /// Aplica filtros y recarga la lista de reportes.
  void setFilters({
    int?    ticketNumber,
    String? status,
    String? from,
    String? to,
    bool    clear = false,
  }) {
    if (clear) {
      _filterTicketNumber = null;
      _filterStatus       = null;
      _filterFrom         = null;
      _filterTo           = null;
    } else {
      _filterTicketNumber = ticketNumber;
      _filterStatus       = status;
      _filterFrom         = from;
      _filterTo           = to;
    }
    loadIncidentReports();
  }

  /// Carga la lista de reportes de incidencias (solo admin).
  /// Usa los filtros configurados con [setFilters].
  Future<void> loadIncidentReports() async {
    _isLoading       = true;
    _incidentReports = [];
    _error           = null;
    notifyListeners();

    try {
      _incidentReports = await _dataSource.getIncidentReports(
        ticketNumber: _filterTicketNumber,
        status:       _filterStatus,
        from:         _filterFrom,
        to:           _filterTo,
      );
    } on AppError catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Resuelve, descarta o reabre un reporte. Devuelve true si fue exitoso.
  ///
  /// [reportId] — ID del reporte.
  /// [status]   — 'resolved' | 'dismissed' | 'pending'.
  Future<bool> resolveIncidentReport(String reportId, String status) async {
    _isRestoring = true;
    _error       = null;
    notifyListeners();

    try {
      await _dataSource.resolveReport(reportId, status);
      // Actualiza el estado local sin recargar toda la lista.
      _incidentReports = _incidentReports.map((r) {
        final report = r as Map<String, dynamic>;
        if (report['id'] == reportId) {
          return {
            ...report,
            'status': status,
            // Limpiar resolvedBy al reabrir.
            if (status == 'pending') 'resolvedBy': null,
          };
        }
        return report;
      }).toList();
      return true;
    } on AppError catch (e) {
      _error = e;
      return false;
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  /// Envía un nuevo reporte de incidencia (cualquier usuario autenticado).
  ///
  /// [text]     — Descripción de la incidencia.
  /// [type]     — 'general' | 'post' | 'comment'.
  /// [targetId] — ID del elemento reportado (opcional).
  /// [imageUrl] — URL de imagen adjunta (opcional).
  Future<bool> submitReport({
    required String text,
    String  type     = 'general',
    String? targetId,
    String? imageUrl,
  }) async {
    _isSubmitting = true;
    _error        = null;
    notifyListeners();

    try {
      await _dataSource.createReport(
        text:      text,
        type:      type,
        targetId:  targetId,
        imageUrl:  imageUrl,
      );
      return true;
    } on AppError catch (e) {
      _error = e;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ─── Borrado de contenido (admin) ────────────────────────────────────────

  /// Elimina un post por admin. Devuelve true si fue exitoso.
  ///
  /// [postId] — ID del post a eliminar.
  Future<bool> deletePost(String postId) async {
    _isRestoring = true;
    _error       = null;
    notifyListeners();

    try {
      await _dataSource.deletePost(postId);
      return true;
    } on AppError catch (e) {
      _error = e;
      return false;
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  /// Elimina un comentario por admin. Devuelve true si fue exitoso.
  ///
  /// [commentId] — ID del comentario a eliminar.
  Future<bool> deleteComment(String commentId) async {
    _isRestoring = true;
    _error       = null;
    notifyListeners();

    try {
      await _dataSource.deleteComment(commentId);
      return true;
    } on AppError catch (e) {
      _error = e;
      return false;
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  // ─── Cron bajo demanda ─────────────────────────────────────────────────────

  bool                  _isRunningCron = false;
  Map<String, dynamic>? _cronResult;

  bool                  get isRunningCron => _isRunningCron;
  Map<String, dynamic>? get cronResult   => _cronResult;

  /// Ejecuta el procesamiento completo de recordatorios (cron) bajo demanda.
  /// Devuelve true si fue exitoso.
  Future<bool> runCron() async {
    _isRunningCron = true;
    _cronResult    = null;
    _error         = null;
    notifyListeners();

    try {
      _cronResult = await _dataSource.runCron();
      return true;
    } on AppError catch (e) {
      _error = e;
      return false;
    } finally {
      _isRunningCron = false;
      notifyListeners();
    }
  }

  // ─── Simulación de clima ────────────────────────────────────────────────────

  bool                  _isSimulatingRain  = false;
  bool                  _isSimulatingStorm = false;
  Map<String, dynamic>? _simulateResult;

  bool                  get isSimulatingRain  => _isSimulatingRain;
  bool                  get isSimulatingStorm => _isSimulatingStorm;
  Map<String, dynamic>? get simulateResult    => _simulateResult;

  /// Simula lluvia para todas las plantas. Devuelve true si fue exitoso.
  Future<bool> simulateRain() async {
    _isSimulatingRain = true;
    _simulateResult   = null;
    _error            = null;
    notifyListeners();

    try {
      _simulateResult = await _dataSource.simulateRain();
      return true;
    } on AppError catch (e) {
      _error = e;
      return false;
    } finally {
      _isSimulatingRain = false;
      notifyListeners();
    }
  }

  /// Simula tormenta para todas las plantas. Devuelve true si fue exitoso.
  Future<bool> simulateStorm() async {
    _isSimulatingStorm = true;
    _simulateResult    = null;
    _error             = null;
    notifyListeners();

    try {
      _simulateResult = await _dataSource.simulateStorm();
      return true;
    } on AppError catch (e) {
      _error = e;
      return false;
    } finally {
      _isSimulatingStorm = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
