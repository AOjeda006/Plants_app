/// @file cache_local_data_source.dart
/// @description Caché local con TTL (Time-To-Live) implementada sobre Hive.
/// Permite guardar y leer objetos serializados (JSON como Map) con expiración
/// automática para cachear respuestas de la API (plantas, clima, comunidad…).
/// @module Core
/// @layer Core
library;

import 'package:hive_flutter/hive_flutter.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// NOMBRE DE LA BOX
// ═══════════════════════════════════════════════════════════════════════════════

/// Nombre de la box Hive usada para el caché general.
const String _kCacheBoxName = 'cache';

// ═══════════════════════════════════════════════════════════════════════════════
// MODELOS INTERNOS
// ═══════════════════════════════════════════════════════════════════════════════

/// Entrada interna de caché que almacena el valor junto con su expiración.
class _CacheEntry {
  const _CacheEntry({required this.value, required this.expiresAt});

  final dynamic value;

  /// Timestamp UTC de expiración en milisegundos desde epoch.
  final int expiresAt;

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch > expiresAt;

  Map<String, dynamic> toMap() => {
    'value':     value,
    'expiresAt': expiresAt,
  };

  factory _CacheEntry.fromMap(Map<dynamic, dynamic> map) => _CacheEntry(
    value:     map['value'],
    expiresAt: map['expiresAt'] as int,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// CACHE LOCAL DATA SOURCE
// ═══════════════════════════════════════════════════════════════════════════════

/// Caché local basada en Hive con soporte de TTL por entrada.
///
/// Uso típico:
/// ```dart
/// await cache.set('plants_list', plantsJson, ttl: Duration(minutes: 5));
/// final data = await cache.get('plants_list'); // null si expiró
/// ```
///
/// [injectable] registrar en container.dart como singleton.
/// Requiere que Hive esté inicializado antes de usar (ver main.dart).
class CacheLocalDataSource {
  late Box<Map> _box;

  // ─── Inicialización ───────────────────────────────────────────────────────────

  /// Abre la box Hive. Debe llamarse durante la inicialización de la app.
  Future<void> initialize() async {
    _box = await Hive.openBox<Map>(_kCacheBoxName);
  }

  // ─── Escritura ────────────────────────────────────────────────────────────────

  /// Guarda [value] bajo [key] con tiempo de vida [ttl].
  ///
  /// Si ya existe una entrada para la misma clave, la sobreescribe.
  Future<void> set(String key, dynamic value, {required Duration ttl}) async {
    final expiresAt =
        DateTime.now().millisecondsSinceEpoch + ttl.inMilliseconds;
    final entry = _CacheEntry(value: value, expiresAt: expiresAt);
    await _box.put(key, entry.toMap());
  }

  // ─── Lectura ──────────────────────────────────────────────────────────────────

  /// Devuelve el valor cacheado bajo [key] si existe y no ha expirado.
  /// Devuelve null si la clave no existe, la entrada expiró o el tipo no coincide.
  ///
  /// Hive deserializa los Maps como `Map<dynamic, dynamic>` y los Lists
  /// como `List<dynamic>`, perdiendo los genéricos exactos. Si el caller
  /// espera `Map<String, dynamic>` y luego hace `.cast<...>()` + `.map(...)`,
  /// al iterar lanza `TypeError` silencioso (no es `AppError`, no se
  /// captura en los ViewModels). Para evitarlo, convertimos
  /// recursivamente los tipos antes de devolver, de modo que el caller
  /// pueda hacer `cast<Map<String, dynamic>>()` sin errores.
  Future<T?> get<T>(String key) async {
    final raw = _box.get(key);
    if (raw == null) return null;

    final entry = _CacheEntry.fromMap(raw);
    if (entry.isExpired) {
      await _box.delete(key); // Limpieza perezosa de entradas expiradas.
      return null;
    }

    final value = _normalizeForRead(entry.value);
    return value is T ? value : null;
  }

  /// Convierte recursivamente los Maps deserializados por Hive a
  /// `Map<String, dynamic>` y mantiene los Lists. Necesario porque Hive
  /// pierde los genéricos al persistir/leer.
  static dynamic _normalizeForRead(dynamic value) {
    if (value is Map) {
      return <String, dynamic>{
        for (final entry in value.entries)
          entry.key.toString(): _normalizeForRead(entry.value),
      };
    }
    if (value is List) {
      return value.map(_normalizeForRead).toList();
    }
    return value;
  }

  /// true si existe una entrada no expirada para [key].
  Future<bool> has(String key) async => (await get<dynamic>(key)) != null;

  // ─── Invalidación ────────────────────────────────────────────────────────────

  /// Elimina la entrada cacheada bajo [key].
  Future<void> invalidate(String key) => _box.delete(key);

  /// Elimina todas las entradas cuya clave empiece por [prefix].
  /// Útil para invalidar todo el caché de un módulo (p.ej. 'plants_').
  Future<void> invalidateByPrefix(String prefix) async {
    final keys = _box.keys.whereType<String>().where((k) => k.startsWith(prefix)).toList();
    await _box.deleteAll(keys);
  }

  /// Borra todas las entradas del caché (logout o reset).
  Future<void> clearAll() => _box.clear();

  // ─── Limpieza de expirados ────────────────────────────────────────────────────

  /// Elimina todas las entradas expiradas. Llamar periódicamente si es necesario.
  Future<void> purgeExpired() async {
    final expiredKeys = <String>[];
    for (final key in _box.keys.whereType<String>()) {
      final raw = _box.get(key);
      if (raw != null && _CacheEntry.fromMap(raw).isExpired) {
        expiredKeys.add(key);
      }
    }
    await _box.deleteAll(expiredKeys);
  }
}
