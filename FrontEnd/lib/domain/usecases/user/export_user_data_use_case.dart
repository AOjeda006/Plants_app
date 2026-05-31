/// @file export_user_data_use_case.dart
/// @description Caso de uso para exportar los datos personales del usuario (RGPD).
/// @module User
/// @layer Domain
library;

import '../../interfaces/usecases/user/i_export_user_data_use_case.dart';
import '../../repositories/i_user_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// EXPORT USER DATA USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Exporta los datos personales del usuario en formato JSON (RGPD).
///
/// [implements] IExportUserDataUseCase
/// [injectable] registrar en container.dart como lazySingleton.
/// [dependencies] IUserRepository.
class ExportUserDataUseCase implements IExportUserDataUseCase {
  final IUserRepository _repository;

  const ExportUserDataUseCase({required IUserRepository repository})
      : _repository = repository;

  /// [returns] JSON string con todos los datos personales del usuario.
  @override
  Future<String> execute() => _repository.exportData();
}
