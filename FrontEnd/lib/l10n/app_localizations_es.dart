// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Plants App';

  @override
  String get tabPlants => 'Plantas';

  @override
  String get tabCommunity => 'Comunidad';

  @override
  String get tabMessages => 'Mensajes';

  @override
  String get tabNotifications => 'Avisos';

  @override
  String get tabCalendar => 'Calendario';

  @override
  String get tabProfile => 'Perfil';

  @override
  String get actionRetry => 'Reintentar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String get actionConfirm => 'Confirmar';

  @override
  String get errorNetwork => 'Sin conexión. Comprueba tu red.';

  @override
  String get errorUnauthorized => 'Sesión expirada. Inicia sesión de nuevo.';

  @override
  String get errorNotFound => 'El recurso solicitado no existe.';

  @override
  String get errorServer => 'Error del servidor. Inténtalo más tarde.';

  @override
  String get errorUnexpected => 'Error inesperado. Inténtalo de nuevo.';
}
