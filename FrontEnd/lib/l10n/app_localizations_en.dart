// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Plants App';

  @override
  String get tabPlants => 'Plants';

  @override
  String get tabCommunity => 'Community';

  @override
  String get tabMessages => 'Messages';

  @override
  String get tabNotifications => 'Notifications';

  @override
  String get tabCalendar => 'Calendar';

  @override
  String get tabProfile => 'Profile';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get errorNetwork => 'No connection. Please check your network.';

  @override
  String get errorUnauthorized => 'Session expired. Please log in again.';

  @override
  String get errorNotFound => 'The requested resource does not exist.';

  @override
  String get errorServer => 'Server error. Please try again later.';

  @override
  String get errorUnexpected => 'Unexpected error. Please try again.';
}
