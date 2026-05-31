/// @file account_management_viewmodel.dart
/// @description ViewModel de la pantalla de gestión de cuenta.
/// Gestiona cambio de contraseña, exportación de datos y eliminación de cuenta.
/// Depende SOLO de interfaces de use cases.
/// @module User
/// @layer Presentation
library;

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../domain/interfaces/usecases/auth/i_logout_use_case.dart';
import '../../../domain/interfaces/usecases/user/i_change_password_use_case.dart';
import '../../../domain/interfaces/usecases/user/i_delete_user_account_use_case.dart';
import '../../../domain/interfaces/usecases/user/i_export_user_data_use_case.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ACCOUNT MANAGEMENT VIEWMODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// ViewModel de la pantalla de gestión de cuenta.
///
/// Estado gestionado:
///  - [isChangingPassword] — true mientras se procesa el cambio de contraseña.
///  - [isDeleting]         — true mientras se procesa la eliminación de cuenta.
///  - [isExporting]        — true mientras se exportan los datos.
///  - [exportedData]       — JSON exportado (null si no se ha exportado aún).
///  - [error]              — último error ocurrido.
///
/// [injectable] registrar en container.dart como factory.
/// [dependencies] IChangePasswordUseCase, IDeleteUserAccountUseCase, IExportUserDataUseCase, ILogoutUseCase.
class AccountManagementViewModel extends ChangeNotifier {
  final IChangePasswordUseCase    _changePassword;
  final IDeleteUserAccountUseCase _deleteAccount;
  final IExportUserDataUseCase    _exportData;
  final ILogoutUseCase            _logout;

  AccountManagementViewModel({
    required IChangePasswordUseCase    changePasswordUseCase,
    required IDeleteUserAccountUseCase deleteUserAccountUseCase,
    required IExportUserDataUseCase    exportUserDataUseCase,
    required ILogoutUseCase            logoutUseCase,
  })  : _changePassword = changePasswordUseCase,
        _deleteAccount  = deleteUserAccountUseCase,
        _exportData     = exportUserDataUseCase,
        _logout         = logoutUseCase;

  // ─── Estado ───────────────────────────────────────────────────────────────────

  bool      _isChangingPassword = false;
  bool      _isDeleting         = false;
  bool      _isExporting        = false;
  bool      _preserveContent    = false;
  String?   _exportedData;
  AppError? _error;

  bool      get isChangingPassword => _isChangingPassword;
  bool      get isDeleting         => _isDeleting;
  bool      get isExporting        => _isExporting;
  /// true = mantener publicaciones de forma anónima al eliminar la cuenta.
  bool      get preserveContent    => _preserveContent;
  String?   get exportedData       => _exportedData;
  AppError? get error              => _error;

  // ─── Cambiar contraseña ───────────────────────────────────────────────────────

  /// Cambia la contraseña del usuario. Devuelve true si fue exitoso.
  Future<bool> changePassword(String current, String newPass) async {
    if (current.isEmpty || newPass.isEmpty) {
      _error = AppError.validation('Rellena todos los campos.');
      notifyListeners();
      return false;
    }
    if (newPass.length < 8) {
      _error = AppError.validation('La nueva contraseña debe tener al menos 8 caracteres.');
      notifyListeners();
      return false;
    }

    _isChangingPassword = true;
    _error              = null;
    notifyListeners();

    try {
      await _changePassword.execute(current, newPass);
      return true;
    } on AppError catch (e) {
      _error = e;
      return false;
    } finally {
      _isChangingPassword = false;
      notifyListeners();
    }
  }

  // ─── Exportar datos ───────────────────────────────────────────────────────────

  /// Exporta los datos personales del usuario (RGPD).
  Future<void> exportUserData() async {
    _isExporting  = true;
    _exportedData = null;
    _error        = null;
    notifyListeners();

    try {
      _exportedData = await _exportData.execute();
    } on AppError catch (e) {
      _error = e;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  // ─── Eliminar cuenta ──────────────────────────────────────────────────────────

  /// Activa o desactiva la opción de mantener publicaciones de forma anónima.
  void setPreserveContent({required bool value}) {
    _preserveContent = value;
    notifyListeners();
  }

  /// Elimina la cuenta del usuario. Devuelve true si fue exitoso.
  Future<bool> deleteAccount(String password) async {
    if (password.isEmpty) {
      _error = AppError.validation('Introduce tu contraseña para confirmar.');
      notifyListeners();
      return false;
    }

    _isDeleting = true;
    _error      = null;
    notifyListeners();

    try {
      await _deleteAccount.execute(password, preserveContent: _preserveContent);
      // Limpiar tokens y estado local antes de que la página navegue al login.
      await _logout.execute();
      return true;
    } on AppError catch (e) {
      _error = e;
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
