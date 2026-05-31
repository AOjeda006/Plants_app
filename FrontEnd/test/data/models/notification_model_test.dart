/// @file notification_model_test.dart
/// @description Tests unitarios para NotificationModel.
/// Verifica que fromJson acepta campos nullable (reminderId, plantId)
/// tanto presentes como ausentes sin lanzar excepción.
/// @module Reminders
/// @layer Data
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:plants_app/data/models/notification_model.dart';

void main() {
  // ── fromJson con campos completos ────────────────────────────────────────────

  group('NotificationModel.fromJson — campos completos', () {
    test('parsea correctamente todos los campos cuando están presentes', () {
      final json = {
        '_id':        'notif-001',
        'userId':     'user-001',
        'type':       'watering',
        'message':    'Riega tu Monstera',
        'reminderId': 'reminder-abc',
        'plantId':    'plant-xyz',
        'isRead':     false,
        'createdAt':  '2026-03-23T10:00:00.000Z',
      };

      final model = NotificationModel.fromJson(json);

      expect(model.id,         'notif-001');
      expect(model.userId,     'user-001');
      expect(model.type,       'watering');
      expect(model.message,    'Riega tu Monstera');
      expect(model.reminderId, 'reminder-abc');
      expect(model.plantId,    'plant-xyz');
      expect(model.isRead,     isFalse);
      expect(model.createdAt,  '2026-03-23T10:00:00.000Z');
    });

    test('acepta id bajo la clave "id" si "_id" no está presente', () {
      final json = {
        'id':         'notif-002',
        'userId':     'user-001',
        'type':       'pruning',
        'message':    'Poda tu rosal',
        'reminderId': null,
        'plantId':    null,
        'isRead':     true,
        'createdAt':  '2026-03-23T11:00:00.000Z',
      };

      final model = NotificationModel.fromJson(json);

      expect(model.id, 'notif-002');
    });
  });

  // ── fromJson con reminderId y plantId null ───────────────────────────────────

  group('NotificationModel.fromJson — campos nullable nulos', () {
    test('no lanza excepción cuando reminderId es null', () {
      final json = {
        '_id':        'notif-003',
        'userId':     'user-001',
        'type':       'watering',
        'message':    'Generada por weather',
        'reminderId': null,
        'plantId':    'plant-001',
        'isRead':     false,
        'createdAt':  '2026-03-23T12:00:00.000Z',
      };

      expect(() => NotificationModel.fromJson(json), returnsNormally);
      final model = NotificationModel.fromJson(json);
      expect(model.reminderId, isNull);
      expect(model.plantId,    'plant-001');
    });

    test('no lanza excepción cuando plantId es null', () {
      final json = {
        '_id':        'notif-004',
        'userId':     'user-001',
        'type':       'custom',
        'message':    'Notificación sin planta',
        'reminderId': 'reminder-001',
        'plantId':    null,
        'isRead':     false,
        'createdAt':  '2026-03-23T12:00:00.000Z',
      };

      expect(() => NotificationModel.fromJson(json), returnsNormally);
      final model = NotificationModel.fromJson(json);
      expect(model.reminderId, 'reminder-001');
      expect(model.plantId,    isNull);
    });

    test('no lanza excepción cuando reminderId Y plantId son null (trigger-reminders)', () {
      final json = {
        '_id':        'notif-005',
        'userId':     'user-001',
        'type':       'watering',
        'message':    'Lluvia prevista mañana',
        'reminderId': null,
        'plantId':    null,
        'isRead':     false,
        'createdAt':  '2026-03-23T13:00:00.000Z',
      };

      expect(() => NotificationModel.fromJson(json), returnsNormally);
      final model = NotificationModel.fromJson(json);
      expect(model.reminderId, isNull);
      expect(model.plantId,    isNull);
    });

    test('no lanza excepción cuando reminderId y plantId están ausentes del JSON', () {
      // La API podría omitir los campos en lugar de enviarlos como null explícito.
      final json = <String, dynamic>{
        '_id':       'notif-006',
        'userId':    'user-001',
        'type':      'harvest',
        'message':   'Época de cosecha',
        'isRead':    false,
        'createdAt': '2026-03-23T14:00:00.000Z',
      };

      expect(() => NotificationModel.fromJson(json), returnsNormally);
      final model = NotificationModel.fromJson(json);
      expect(model.reminderId, isNull);
      expect(model.plantId,    isNull);
    });
  });

  // ── isRead con fallback ───────────────────────────────────────────────────────

  group('NotificationModel.fromJson — isRead fallback', () {
    test('isRead es false cuando el campo está ausente del JSON', () {
      final json = {
        '_id':       'notif-007',
        'userId':    'user-001',
        'type':      'fertilizing',
        'message':   'Fertiliza tu planta',
        'createdAt': '2026-03-23T15:00:00.000Z',
      };

      final model = NotificationModel.fromJson(json);
      expect(model.isRead, isFalse);
    });
  });
}
