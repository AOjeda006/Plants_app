/**
 * @file notification_service.spec.ts
 * @description Tests unitarios para NotificationService.
 * Cubre el flujo de limpieza de fcmToken cuando el SDK de Firebase devuelve
 * UNREGISTERED u otros códigos de token inválido.
 * @module Reminders
 * @layer Presentation
 */

import 'reflect-metadata';
import { NotificationService } from './NotificationService.js';
import { User } from '../../domain/entities/User.js';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockFirebase = {
  sendPushNotification: jest.fn(),
};

const mockUserRepo = {
  update:   jest.fn(),
  // findById se usa para verificar preferences.pushNotifications antes de
  // enviar push. Por defecto devuelve un user con push habilitado.
  findById: jest.fn(),
};

/** Helper: crea un User entity de test con preferences configurable. */
function makeUser(
  pushNotifications: boolean | undefined = undefined,
  fcmToken: string = 'valid-token',
): User {
  return new User({
    id:           'user-001',
    role:         'user',
    name:         'Test User',
    email:        't@test.com',
    passwordHash: 'hashed',
    fcmToken,
    preferences:  {
      appearInChatSearch:       true,
      considerWeatherByDefault: false,
      isPrivate:                false,
      pushNotifications,
    },
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
  });
}

// ─── Suite ────────────────────────────────────────────────────────────────────

describe('NotificationService', () => {
  let service: NotificationService;

  beforeEach(() => {
    jest.clearAllMocks();
    // Default: findById devuelve un user con push habilitado (default true).
    mockUserRepo.findById.mockResolvedValue(makeUser());
    // SocketService mock (emit es no-op en tests).
    const mockSocketService = { emitToUser: jest.fn(), broadcast: jest.fn() };
    service = new NotificationService(
      mockFirebase as any,
      mockUserRepo as any,
      mockSocketService as any,
    );
  });

  // ── sendToUser sin token ───────────────────────────────────────────────────

  it('debe omitir notificación si fcmToken vacío', async () => {
    await service.sendToUser('', { title: 'Título', body: 'Cuerpo' });
    expect(mockFirebase.sendPushNotification).not.toHaveBeenCalled();
  });

  // ── sendToUser éxito ───────────────────────────────────────────────────────

  it('envía push correctamente y NO limpia el token', async () => {
    mockFirebase.sendPushNotification.mockResolvedValue('msg-id-123');

    await service.sendToUser('valid-token', { title: 'Hola', body: 'Cuerpo', userId: 'user-001' });

    expect(mockFirebase.sendPushNotification).toHaveBeenCalledWith({
      token: 'valid-token',
      title: 'Hola',
      body:  'Cuerpo',
      data:  undefined,
    });
    expect(mockUserRepo.update).not.toHaveBeenCalled();
  });

  // ── sendToUser error UNREGISTERED → cleanup ────────────────────────────────

  it('si el SDK devuelve UNREGISTERED, limpia User.fcmToken', async () => {
    const err = Object.assign(new Error('Token not registered'), {
      code: 'messaging/registration-token-not-registered',
    });
    mockFirebase.sendPushNotification.mockRejectedValue(err);

    await service.sendToUser('expired-token', { title: 'Hola', body: 'Cuerpo', userId: 'user-001' });

    expect(mockUserRepo.update).toHaveBeenCalledWith('user-001', { fcmToken: '' });
  });

  it('si el SDK devuelve invalid-registration-token, también limpia el token', async () => {
    const err = Object.assign(new Error('Invalid'), {
      code: 'messaging/invalid-registration-token',
    });
    mockFirebase.sendPushNotification.mockRejectedValue(err);

    await service.sendToUser('bad-token', { title: 'Hola', body: 'Cuerpo', userId: 'user-001' });

    expect(mockUserRepo.update).toHaveBeenCalledWith('user-001', { fcmToken: '' });
  });

  // ── sendToUser error genérico → NO limpiar ─────────────────────────────────

  it('si el error NO es de token inválido, NO limpia el token', async () => {
    const err = Object.assign(new Error('Network'), {
      code: 'messaging/internal-error',
    });
    mockFirebase.sendPushNotification.mockRejectedValue(err);

    await service.sendToUser('valid-token', { title: 'Hola', body: 'Cuerpo', userId: 'user-001' });

    expect(mockUserRepo.update).not.toHaveBeenCalled();
  });

  // ── sendToUser sin userId → NO limpiar (no podemos identificar al usuario) ─

  it('si no se pasa userId, NO se limpia ningún token aunque el error sea UNREGISTERED', async () => {
    const err = Object.assign(new Error('Token not registered'), {
      code: 'messaging/registration-token-not-registered',
    });
    mockFirebase.sendPushNotification.mockRejectedValue(err);

    await service.sendToUser('expired-token', { title: 'Hola', body: 'Cuerpo' });

    expect(mockUserRepo.update).not.toHaveBeenCalled();
  });

  // ── el push fallido NO debe romper el flujo ────────────────────────────────

  it('una excepción del SDK NO se propaga al caller (notifs in-app/Socket.IO siguen)', async () => {
    mockFirebase.sendPushNotification.mockRejectedValue(new Error('any'));

    await expect(
      service.sendToUser('token', { title: 'Hola', body: 'Cuerpo' }),
    ).resolves.toBeUndefined();
  });

  // ── Respeto de preferences.pushNotifications ───────────────────────────────

  describe('pushNotifications preference', () => {
    it('user con fcmToken + pushNotifications=true → ENVÍA push', async () => {
      mockUserRepo.findById.mockResolvedValue(makeUser(true));
      mockFirebase.sendPushNotification.mockResolvedValue('msg-id');

      await service.sendToUser('valid-token', { title: 'Hola', body: 'Cuerpo', userId: 'user-001' });

      expect(mockFirebase.sendPushNotification).toHaveBeenCalledTimes(1);
    });

    it('user con fcmToken + pushNotifications=false → NO envía push', async () => {
      mockUserRepo.findById.mockResolvedValue(makeUser(false));

      await service.sendToUser('valid-token', { title: 'Hola', body: 'Cuerpo', userId: 'user-001' });

      expect(mockFirebase.sendPushNotification).not.toHaveBeenCalled();
    });

    it('user con fcmToken y preferences.pushNotifications=undefined (legacy) → ENVÍA push (default true)', async () => {
      mockUserRepo.findById.mockResolvedValue(makeUser(undefined));
      mockFirebase.sendPushNotification.mockResolvedValue('msg-id');

      await service.sendToUser('valid-token', { title: 'Hola', body: 'Cuerpo', userId: 'user-001' });

      expect(mockFirebase.sendPushNotification).toHaveBeenCalledTimes(1);
    });

    it('user con pushNotifications=true pero sin fcmToken (BD) → NO envía (no hay destino)', async () => {
      mockUserRepo.findById.mockResolvedValue(makeUser(true, ''));

      // Aunque el caller pase un fcmToken "huérfano" (no coincide con BD),
      // canReceiveNotifications() devuelve false porque el user en BD no
      // tiene fcmToken — el destino real no existe.
      await service.sendToUser('huerfano', { title: 'Hola', body: 'Cuerpo', userId: 'user-001' });

      expect(mockFirebase.sendPushNotification).not.toHaveBeenCalled();
    });
  });

  // ── collapseKey de mensajes agrupados ─────────────────────────────────────

  describe('collapseKey', () => {
    it('si se pasa collapseKey, se propaga al payload FCM', async () => {
      mockFirebase.sendPushNotification.mockResolvedValue('msg-id');

      await service.sendToUser('valid-token', {
        title:       'Tienes nuevos mensajes de Alicia',
        body:        'Hola',
        data:        { conversationId: 'c1', type: 'chat_message' },
        userId:      'user-001',
        collapseKey: 'chat_user-001',
      });

      expect(mockFirebase.sendPushNotification).toHaveBeenCalledWith({
        token:       'valid-token',
        title:       'Tienes nuevos mensajes de Alicia',
        body:        'Hola',
        data:        { conversationId: 'c1', type: 'chat_message' },
        collapseKey: 'chat_user-001',
      });
    });

    it('si NO se pasa collapseKey, el payload NO contiene el campo (compatibilidad atrás)', async () => {
      mockFirebase.sendPushNotification.mockResolvedValue('msg-id');

      await service.sendToUser('valid-token', {
        title:  'Recordatorio',
        body:   'Cuerpo',
        data:   { type: 'watering' },
        userId: 'user-001',
      });

      const payload = mockFirebase.sendPushNotification.mock.calls[0][0];
      expect(payload.collapseKey).toBeUndefined();
    });
  });
});
