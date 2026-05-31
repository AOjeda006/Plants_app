/// @file date_utils.dart
/// @description Utilidades de fecha y hora para la app de plantas.
/// Cálculo de próximo riego, formateo localizado, normalización de timezone.
/// Todas las funciones son estáticas y puras (sin efectos secundarios).
/// @module Core
/// @layer Core
library;

// ═══════════════════════════════════════════════════════════════════════════════
// PLANT DATE UTILS
// ═══════════════════════════════════════════════════════════════════════════════

/// Utilidades de fecha especializadas en el dominio de gestión de plantas.
abstract final class PlantDateUtils {

  // ─── Próximo riego ────────────────────────────────────────────────────────────

  /// Calcula la fecha del próximo riego a partir del último riego y la frecuencia.
  ///
  /// [lastWatered]       — fecha UTC del último riego.
  /// [frequencyDays]     — frecuencia de riego en días (p.ej. 7 = semanal).
  ///
  /// Devuelve la fecha UTC del próximo riego previsto.
  static DateTime nextWateringDate({
    required DateTime lastWatered,
    required int frequencyDays,
  }) {
    return lastWatered.toUtc().add(Duration(days: frequencyDays));
  }

  /// Días restantes hasta el próximo riego. Negativo = ya debería haberse regado.
  ///
  /// Se calcula respecto a la medianoche de hoy (UTC) para ignorar la hora exacta.
  static int daysUntilNextWatering({
    required DateTime lastWatered,
    required int frequencyDays,
  }) {
    final next  = nextWateringDate(lastWatered: lastWatered, frequencyDays: frequencyDays);
    final today = _todayUtc();
    return next.difference(today).inDays;
  }

  /// true si la planta necesita riego hoy o ya estaba atrasada.
  static bool needsWateringToday({
    required DateTime lastWatered,
    required int frequencyDays,
  }) =>
      daysUntilNextWatering(
        lastWatered: lastWatered,
        frequencyDays: frequencyDays,
      ) <= 0;

  // ─── Formateo ─────────────────────────────────────────────────────────────────

  /// Formatea una fecha como "dd/MM/yyyy" (formato español).
  static String formatDate(DateTime date) {
    final d = date.toLocal();
    return '${_pad(d.day)}/${_pad(d.month)}/${d.year}';
  }

  /// Formatea una fecha como "dd/MM/yyyy HH:mm".
  static String formatDateTime(DateTime date) {
    final d = date.toLocal();
    return '${formatDate(d)} ${_pad(d.hour)}:${_pad(d.minute)}';
  }

  /// Devuelve una cadena relativa legible: "Hoy", "Mañana", "Hace 2 días", etc.
  ///
  /// [date] — fecha a comparar con hoy. Si no se indica [now], usa DateTime.now().
  static String relativeDay(DateTime date, {DateTime? now}) {
    final today  = _todayUtc();
    final target = _dayStart(date.toUtc());
    final diff   = target.difference(today).inDays;

    return switch (diff) {
      0           => 'Hoy',
      1           => 'Mañana',
      -1          => 'Ayer',
      final d when d > 1  => 'En $d días',
      final d when d < -1 => 'Hace ${-d} días',
      _                   => formatDate(date),
    };
  }

  /// Devuelve etiqueta de urgencia de riego:
  ///  - "Atrasado"  si daysUntil < 0
  ///  - "Hoy"       si daysUntil == 0
  ///  - "Mañana"    si daysUntil == 1
  ///  - "En N días" si daysUntil > 1
  static String wateringUrgencyLabel({
    required DateTime lastWatered,
    required int frequencyDays,
  }) {
    final days = daysUntilNextWatering(
      lastWatered: lastWatered,
      frequencyDays: frequencyDays,
    );
    if (days < 0) return 'Atrasado';
    if (days == 0) return 'Hoy';
    if (days == 1) return 'Mañana';
    return 'En $days días';
  }

  // ─── Normalización timezone ───────────────────────────────────────────────────

  /// Convierte una fecha ISO 8601 (string) a DateTime UTC.
  /// Devuelve null si la cadena es inválida o nula.
  static DateTime? parseUtc(String? isoString) {
    if (isoString == null || isoString.isEmpty) return null;
    return DateTime.tryParse(isoString)?.toUtc();
  }

  /// Serializa un DateTime a string ISO 8601 UTC.
  static String toIso8601(DateTime date) => date.toUtc().toIso8601String();

  // ─── Helpers privados ────────────────────────────────────────────────────────

  /// Medianoche UTC de hoy.
  static DateTime _todayUtc() {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day);
  }

  /// Medianoche UTC de la fecha indicada.
  static DateTime _dayStart(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  /// Rellena con cero a la izquierda para formateo de fechas.
  static String _pad(int n) => n.toString().padLeft(2, '0');
}
