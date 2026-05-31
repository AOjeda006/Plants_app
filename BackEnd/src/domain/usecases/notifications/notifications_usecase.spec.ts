/**
 * @file notifications_usecase.spec.ts
 * @description Tests unitarios para GetUserNotificationsUseCase,
 * MarkNotificationsReadUseCase y DeleteNotificationsUseCase.
 * Verifica: listado de notificaciones, marcado como leídas y eliminación.
 * @module Reminders
 * @layer Domain
 */

import 'reflect-metadata';
import { GetUserNotificationsUseCase }  from './GetUserNotificationsUseCase.js';
import { MarkNotificationsReadUseCase } from './MarkNotificationsReadUseCase.js';
import { DeleteNotificationsUseCase }   from './DeleteNotificationsUseCase.js';
import { Notification }                 from '../../entities/Notification.js';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockNotifRepo = {
  findByUserId:        jest.fn(),
  create:              jest.fn(),
  markAllReadByUserId: jest.fn(),
  deleteAllByUserId:   jest.fn(),
  markReadByIds:       jest.fn(),
  deleteByIds:         jest.fn(),
};

const mockMapper = {
  toResponseDTO: jest.fn(),
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

const FIXED_DATE = new Date('2026-03-17T00:00:00.000Z');
const USER_ID    = 'user-001';

const makeNotification = (overrides: Partial<{
  id: string; isRead: boolean; type: string;
}> = {}): Notification =>
  new Notification({
    id:         overrides.id         ?? 'notif-001',
    userId:     USER_ID,
    type:       (overrides.type ?? 'watering') as any,
    message:    'Es hora de regar tu planta',
    reminderId: 'reminder-001',
    plantId:    'plant-001',
    isRead:     overrides.isRead     ?? false,
    createdAt:  FIXED_DATE,
  });

const makeDTO = (id: string) => ({
  id,
  userId:     USER_ID,
  type:       'watering',
  message:    'Es hora de regar tu planta',
  reminderId: 'reminder-001',
  plantId:    'plant-001',
  isRead:     false,
  createdAt:  FIXED_DATE.toISOString(),
});

// ─── GetUserNotificationsUseCase ───────────────────────────────────────────────

describe('GetUserNotificationsUseCase', () => {
  let useCase: GetUserNotificationsUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    mockMapper.toResponseDTO.mockImplementation((n: Notification) => makeDTO(n.id));

    useCase = new GetUserNotificationsUseCase(
      mockNotifRepo as any,
      mockMapper    as any,
    );
  });

  it('debe devolver la lista de notificaciones mapeadas del usuario', async () => {
    const notifs = [
      makeNotification({ id: 'n1' }),
      makeNotification({ id: 'n2', isRead: true }),
    ];
    mockNotifRepo.findByUserId.mockResolvedValue(notifs);

    const result = await useCase.execute(USER_ID);

    expect(mockNotifRepo.findByUserId).toHaveBeenCalledWith(USER_ID);
    expect(result).toHaveLength(2);
    expect(result[0].id).toBe('n1');
    expect(result[1].id).toBe('n2');
  });

  it('debe devolver lista vacía si el usuario no tiene notificaciones', async () => {
    mockNotifRepo.findByUserId.mockResolvedValue([]);

    const result = await useCase.execute(USER_ID);

    expect(result).toHaveLength(0);
    expect(mockMapper.toResponseDTO).not.toHaveBeenCalled();
  });

  it('debe llamar al mapper una vez por notificación', async () => {
    const notifs = [
      makeNotification({ id: 'n1' }),
      makeNotification({ id: 'n2' }),
      makeNotification({ id: 'n3' }),
    ];
    mockNotifRepo.findByUserId.mockResolvedValue(notifs);

    await useCase.execute(USER_ID);

    expect(mockMapper.toResponseDTO).toHaveBeenCalledTimes(3);
  });
});

// ─── MarkNotificationsReadUseCase ─────────────────────────────────────────────

describe('MarkNotificationsReadUseCase', () => {
  let useCase: MarkNotificationsReadUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    mockNotifRepo.markAllReadByUserId.mockResolvedValue(undefined);

    useCase = new MarkNotificationsReadUseCase(mockNotifRepo as any);
  });

  it('debe llamar a markAllReadByUserId con el userId correcto', async () => {
    await useCase.execute(USER_ID);

    expect(mockNotifRepo.markAllReadByUserId).toHaveBeenCalledWith(USER_ID);
    expect(mockNotifRepo.markAllReadByUserId).toHaveBeenCalledTimes(1);
  });

  it('no debe lanzar error si el repositorio resuelve correctamente', async () => {
    await expect(useCase.execute(USER_ID)).resolves.toBeUndefined();
  });

  it('debe llamar a markReadByIds cuando se pasan ids específicos', async () => {
    mockNotifRepo.markReadByIds.mockResolvedValue(undefined);
    const ids = ['n1', 'n3'];

    await useCase.execute(USER_ID, ids);

    expect(mockNotifRepo.markReadByIds).toHaveBeenCalledWith(USER_ID, ids);
    expect(mockNotifRepo.markAllReadByUserId).not.toHaveBeenCalled();
  });

  it('debe llamar a markAllReadByUserId cuando ids es array vacío', async () => {
    await useCase.execute(USER_ID, []);

    expect(mockNotifRepo.markAllReadByUserId).toHaveBeenCalledWith(USER_ID);
    expect(mockNotifRepo.markReadByIds).not.toHaveBeenCalled();
  });
});

// ─── DeleteNotificationsUseCase ───────────────────────────────────────────────

describe('DeleteNotificationsUseCase', () => {
  let useCase: DeleteNotificationsUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    mockNotifRepo.deleteAllByUserId.mockResolvedValue(undefined);

    useCase = new DeleteNotificationsUseCase(mockNotifRepo as any);
  });

  it('debe llamar a deleteAllByUserId con el userId correcto', async () => {
    await useCase.execute(USER_ID);

    expect(mockNotifRepo.deleteAllByUserId).toHaveBeenCalledWith(USER_ID);
    expect(mockNotifRepo.deleteAllByUserId).toHaveBeenCalledTimes(1);
  });

  it('no debe lanzar error si el repositorio resuelve correctamente', async () => {
    await expect(useCase.execute(USER_ID)).resolves.toBeUndefined();
  });

  it('debe llamar a deleteByIds cuando se pasan ids específicos', async () => {
    mockNotifRepo.deleteByIds.mockResolvedValue(undefined);
    const ids = ['n2'];

    await useCase.execute(USER_ID, ids);

    expect(mockNotifRepo.deleteByIds).toHaveBeenCalledWith(USER_ID, ids);
    expect(mockNotifRepo.deleteAllByUserId).not.toHaveBeenCalled();
  });

  it('debe llamar a deleteAllByUserId cuando ids es array vacío', async () => {
    await useCase.execute(USER_ID, []);

    expect(mockNotifRepo.deleteAllByUserId).toHaveBeenCalledWith(USER_ID);
    expect(mockNotifRepo.deleteByIds).not.toHaveBeenCalled();
  });
});
