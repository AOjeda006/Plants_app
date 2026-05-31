/// @file account_management_viewmodel_test.dart
/// @description Tests unitarios para AccountManagementViewModel.
/// Verifica cambio de contraseña, exportación de datos, eliminación de cuenta
/// y que deleteAccount llama a logout automáticamente.
/// @module User
/// @layer Presentation
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:plants_app/core/errors/app_error.dart';
import 'package:plants_app/domain/interfaces/usecases/auth/i_logout_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/user/i_change_password_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/user/i_delete_user_account_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/user/i_export_user_data_use_case.dart';
import 'package:plants_app/presentation/viewmodels/profile/account_management_viewmodel.dart';

// ─── Mocks manuales ───────────────────────────────────────────────────────────

class _MockChangePasswordUseCase implements IChangePasswordUseCase {
  AppError? throwError;
  bool wasCalled = false;

  @override
  Future<void> execute(String currentPassword, String newPassword) async {
    wasCalled = true;
    if (throwError != null) throw throwError!;
  }
}

class _MockDeleteUserAccountUseCase implements IDeleteUserAccountUseCase {
  AppError? throwError;
  bool wasCalled = false;

  @override
  Future<void> execute(String password, {bool preserveContent = false}) async {
    wasCalled = true;
    if (throwError != null) throw throwError!;
  }
}

class _MockExportUserDataUseCase implements IExportUserDataUseCase {
  String returnValue = '{"exportedAt":"2026-03-09T00:00:00.000Z","profile":{},"plants":[],"totalPlants":0}';
  AppError? throwError;

  @override
  Future<String> execute() async {
    if (throwError != null) throw throwError!;
    return returnValue;
  }
}

class _MockLogoutUseCase implements ILogoutUseCase {
  bool wasCalled = false;

  @override
  Future<void> execute() async {
    wasCalled = true;
  }
}

// ─── Helper ───────────────────────────────────────────────────────────────────

AccountManagementViewModel _makeVm({
  _MockChangePasswordUseCase?    changePassword,
  _MockDeleteUserAccountUseCase? deleteAccount,
  _MockExportUserDataUseCase?    exportData,
  _MockLogoutUseCase?            logout,
}) =>
    AccountManagementViewModel(
      changePasswordUseCase:    changePassword    ?? _MockChangePasswordUseCase(),
      deleteUserAccountUseCase: deleteAccount     ?? _MockDeleteUserAccountUseCase(),
      exportUserDataUseCase:    exportData        ?? _MockExportUserDataUseCase(),
      logoutUseCase:            logout            ?? _MockLogoutUseCase(),
    );

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── changePassword ─────────────────────────────────────────────────────────

  group('changePassword', () {
    test('devuelve true y llama al use case si las credenciales son válidas', () async {
      final changePass = _MockChangePasswordUseCase();
      final vm = _makeVm(changePassword: changePass);

      final result = await vm.changePassword('oldPass1!', 'newPass1!');

      expect(result, isTrue);
      expect(vm.error, isNull);
      expect(changePass.wasCalled, isTrue);
    });

    test('devuelve false y establece error.validation si algún campo está vacío', () async {
      final vm = _makeVm();

      final result = await vm.changePassword('', 'newPass1!');

      expect(result, isFalse);
      expect(vm.error?.code, ErrorCode.validation);
    });

    test('devuelve false si la nueva contraseña tiene menos de 8 caracteres', () async {
      final vm = _makeVm();

      final result = await vm.changePassword('oldPass1!', 'abc');

      expect(result, isFalse);
      expect(vm.error?.code, ErrorCode.validation);
    });

    test('devuelve false y propaga AppError si el use case lanza', () async {
      final changePass = _MockChangePasswordUseCase()
        ..throwError = AppError.unauthorized();
      final vm = _makeVm(changePassword: changePass);

      final result = await vm.changePassword('wrongPass!', 'newPass1!');

      expect(result, isFalse);
      expect(vm.error?.code, ErrorCode.unauthorized);
    });

    test('isChangingPassword vuelve a false tras finalizar', () async {
      final vm = _makeVm();
      expect(vm.isChangingPassword, isFalse);

      await vm.changePassword('oldPass1!', 'newPass1!');

      expect(vm.isChangingPassword, isFalse);
    });
  });

  // ── deleteAccount ──────────────────────────────────────────────────────────

  group('deleteAccount', () {
    test('devuelve true y llama a deleteAccount + logout si la contraseña no está vacía', () async {
      final deleteAcc = _MockDeleteUserAccountUseCase();
      final logout    = _MockLogoutUseCase();
      final vm = _makeVm(deleteAccount: deleteAcc, logout: logout);

      final result = await vm.deleteAccount('myPassword1!');

      expect(result, isTrue);
      expect(vm.error, isNull);
      expect(deleteAcc.wasCalled, isTrue);
      // logout debe ejecutarse automáticamente tras eliminar la cuenta
      expect(logout.wasCalled, isTrue);
    });

    test('devuelve false y establece error.validation si la contraseña está vacía', () async {
      final logout = _MockLogoutUseCase();
      final vm = _makeVm(logout: logout);

      final result = await vm.deleteAccount('');

      expect(result, isFalse);
      expect(vm.error?.code, ErrorCode.validation);
      // No debe llamarse a logout si la validación falla
      expect(logout.wasCalled, isFalse);
    });

    test('devuelve false y NO llama a logout si el use case lanza error', () async {
      final deleteAcc = _MockDeleteUserAccountUseCase()
        ..throwError = AppError.unauthorized();
      final logout = _MockLogoutUseCase();
      final vm = _makeVm(deleteAccount: deleteAcc, logout: logout);

      final result = await vm.deleteAccount('wrongPass!');

      expect(result, isFalse);
      expect(vm.error?.code, ErrorCode.unauthorized);
      expect(logout.wasCalled, isFalse);
    });

    test('isDeleting vuelve a false tras finalizar', () async {
      final vm = _makeVm();
      expect(vm.isDeleting, isFalse);

      await vm.deleteAccount('myPassword1!');

      expect(vm.isDeleting, isFalse);
    });
  });

  // ── exportUserData ─────────────────────────────────────────────────────────

  group('exportUserData', () {
    test('guarda el JSON en exportedData si el use case devuelve datos', () async {
      final exportData = _MockExportUserDataUseCase();
      final vm = _makeVm(exportData: exportData);

      await vm.exportUserData();

      expect(vm.exportedData, isNotNull);
      expect(vm.exportedData, contains('exportedAt'));
      expect(vm.error, isNull);
    });

    test('establece error si el use case lanza', () async {
      final exportData = _MockExportUserDataUseCase()
        ..throwError = AppError.network();
      final vm = _makeVm(exportData: exportData);

      await vm.exportUserData();

      expect(vm.exportedData, isNull);
      expect(vm.error?.code, ErrorCode.network);
    });

    test('isExporting vuelve a false tras finalizar', () async {
      final vm = _makeVm();
      expect(vm.isExporting, isFalse);

      await vm.exportUserData();

      expect(vm.isExporting, isFalse);
    });
  });

  // ── clearError ─────────────────────────────────────────────────────────────

  group('clearError', () {
    test('limpia el error previo', () async {
      final vm = _makeVm();
      await vm.changePassword('', '');   // provoca error.validation
      expect(vm.error, isNotNull);

      vm.clearError();

      expect(vm.error, isNull);
    });
  });
}
