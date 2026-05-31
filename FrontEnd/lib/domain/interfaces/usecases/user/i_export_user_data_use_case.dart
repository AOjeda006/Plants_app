/// @file i_export_user_data_use_case.dart
/// @description Interfaz: Exporta los datos personales del usuario (RGPD).
/// @module User
/// @layer Domain
library;
abstract interface class IExportUserDataUseCase {
  /// Exporta los datos personales del usuario (RGPD).
  Future<String> execute();
}
