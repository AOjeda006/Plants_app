/// @file reminder_repository_impl.dart
/// @description Implementación del repositorio de recordatorios.
/// Coordina ReminderRemoteDataSource (API) y CacheLocalDataSource (caché corta).
/// Los recordatorios se procesan cada minuto (cron TFG), por lo que el TTL
/// de caché es breve para reflejar cambios de estado con agilidad.
/// @module Reminders
/// @layer Data
library;

import '../../core/storage/cache_local_data_source.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/repositories/i_reminder_repository.dart';
import '../datasources/remote/reminder_remote_data_source.dart';
import '../i_mappers/i_reminder_mapper.dart';
import '../models/reminder_model.dart';

// ─── Constantes de caché ──────────────────────────────────────────────────────

const String _kRemindersKey   = 'reminders_active';
const Duration _kRemindersTtl = Duration(seconds: 30);

// ═══════════════════════════════════════════════════════════════════════════════
// REMINDER REPOSITORY IMPL
// ═══════════════════════════════════════════════════════════════════════════════

/// Implementación concreta de [IReminderRepository].
///
/// Estrategia de caché:
///  - getActiveReminders: caché de 30 s (el cron backend corre cada minuto).
///  - markCompleted: invalida la caché para reflejar el cambio de estado.
///
/// [implements] IReminderRepository
/// [injectable] registrar en container.dart.
/// [dependencies] ReminderRemoteDataSource, CacheLocalDataSource, IReminderMapper.
class ReminderRepositoryImpl implements IReminderRepository {
  final ReminderRemoteDataSource _remote;
  final CacheLocalDataSource     _cache;
  final IReminderMapper          _mapper;

  const ReminderRepositoryImpl({
    required ReminderRemoteDataSource remote,
    required CacheLocalDataSource     cache,
    required IReminderMapper          mapper,
  })  : _remote = remote,
        _cache  = cache,
        _mapper = mapper;

  // ─── Get active reminders ─────────────────────────────────────────────────────

  @override
  Future<List<Reminder>> getActiveReminders() async {
    // Cache-first con TTL corto (30 s) para absorber recargas frecuentes.
    final cached = await _cache.get<List<dynamic>>(_kRemindersKey);
    if (cached != null) {
      return cached
          .cast<Map<String, dynamic>>()
          .map((json) => _mapper.toEntity(ReminderModel.fromJson(json)))
          .toList();
    }

    final rawList = await _remote.getActiveReminders();
    await _cache.set(_kRemindersKey, rawList, ttl: _kRemindersTtl);
    return rawList
        .map((json) => _mapper.toEntity(ReminderModel.fromJson(json)))
        .toList();
  }

  // ─── Mark completed ───────────────────────────────────────────────────────────

  @override
  Future<void> markCompleted(String reminderId) async {
    await _remote.markCompleted(reminderId);
    // Invalidar caché para que la próxima lectura refleje el nuevo estado.
    await _cache.invalidate(_kRemindersKey);
  }
}
