/**
 * @file chat_usecase.spec.ts
 * @description Tests unitarios para SendMessageUseCase y MarkMessagesAsReadUseCase.
 * Verifica envío de mensajes, validación de participantes, push notifications
 * y marcado de mensajes como leídos.
 * @module Chat
 * @layer Domain
 */

import 'reflect-metadata';
import { SendMessageUseCase }       from './SendMessageUseCase.js';
import { MarkMessagesAsReadUseCase } from './MarkMessagesAsReadUseCase.js';
import { NotFoundException }         from '../../../core/exceptions/NotFoundException.js';
import { ForbiddenException }        from '../../../core/exceptions/ForbiddenException.js';
import { User }                      from '../../entities/User.js';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockConversationRepo = {
  findById:            jest.fn(),
  updateLastMessageAt: jest.fn(),
};

const mockMessageRepo = {
  create:                      jest.fn(),
  markAsRead:                  jest.fn(),
  updateStatus:                jest.fn(),
  // Usado por SendMessageUseCase para decidir si el título del push es
  // "[Nombre]" o "Varios usuarios". Por defecto solo el sender actual
  // aparece como pendiente (escenario normal "primer mensaje").
  findDistinctUnreadSenderIds: jest.fn(),
};

const mockUserRepo = {
  findById: jest.fn(),
  // SendMessageUseCase persiste el último título enviado para dedup.
  // Best-effort, retorna void.
  update:   jest.fn().mockResolvedValue(undefined),
};

const mockMessageMapper = {
  toResponseDTO: jest.fn(),
};

const mockSocketService = {
  emitToUser: jest.fn(),
  isOnline:   jest.fn(),
};

const mockNotificationService = {
  sendToUser: jest.fn(),
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

const SENDER_ID   = 'sender-001';
const RECEIVER_ID = 'receiver-001';
const CONV_ID     = 'conv-001';

const makeConversation = () => ({
  id:           CONV_ID,
  participants: [SENDER_ID, RECEIVER_ID],
  getOtherParticipantId: jest.fn().mockReturnValue(RECEIVER_ID),
});

const makeMessage = () => ({
  id:             'msg-001',
  conversationId: CONV_ID,
  senderId:       SENDER_ID,
  receiverId:     RECEIVER_ID,
  text:           'Hola',
  createdAt:      new Date(),
});

const makeUser = (id: string, withToken = false) =>
  new User({
    id, name: 'User', email: `${id}@example.com`, passwordHash: 'hash',
    fcmToken:    withToken ? 'fcm-token-xyz' : undefined,
    preferences: {
      appearInChatSearch:        true,
      considerWeatherByDefault:  false,
      isPrivate:                 false,
    },
    createdAt:   new Date(), updatedAt: new Date(),
  });

const makeMsgDTO = () => ({ id: 'msg-001', text: 'Hola', senderName: 'User', status: 'sent' });

// ─── SendMessageUseCase ───────────────────────────────────────────────────────

describe('SendMessageUseCase', () => {
  let useCase: SendMessageUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    mockConversationRepo.updateLastMessageAt.mockResolvedValue(undefined);
    mockSocketService.emitToUser.mockImplementation(() => {});
    mockSocketService.isOnline.mockReturnValue(true);
    mockNotificationService.sendToUser.mockResolvedValue(undefined);
    // Por defecto solo el sender de este mensaje aparece como pendiente
    // (escenario base "primer mensaje"). Los tests específicos sobrescriben.
    mockMessageRepo.findDistinctUnreadSenderIds.mockResolvedValue([SENDER_ID]);

    useCase = new SendMessageUseCase(
      mockConversationRepo   as any,
      mockMessageRepo        as any,
      mockUserRepo           as any,
      mockMessageMapper      as any,
      mockSocketService      as any,
      mockNotificationService as any,
    );
  });

  it('debe persistir el mensaje y devolver MessageResponseDTO', async () => {
    mockConversationRepo.findById.mockResolvedValue(makeConversation());
    mockUserRepo.findById.mockResolvedValue(makeUser(SENDER_ID));
    mockMessageRepo.create.mockResolvedValue(makeMessage());
    mockMessageMapper.toResponseDTO.mockReturnValue(makeMsgDTO());

    const dto = { text: 'Hola', tempId: 'temp-001' };
    const result = await useCase.execute(CONV_ID, SENDER_ID, dto as any);

    expect(mockMessageRepo.create).toHaveBeenCalledTimes(1);
    expect(mockConversationRepo.updateLastMessageAt).toHaveBeenCalledTimes(1);
    // El receptor está online → status se muta a 'delivered'.
    expect(result).toEqual({ ...makeMsgDTO(), status: 'delivered' });
  });

  it('debe emitir el mensaje al receptor via socket', async () => {
    mockConversationRepo.findById.mockResolvedValue(makeConversation());
    mockUserRepo.findById.mockResolvedValue(makeUser(SENDER_ID));
    mockMessageRepo.create.mockResolvedValue(makeMessage());
    mockMessageMapper.toResponseDTO.mockReturnValue(makeMsgDTO());

    await useCase.execute(CONV_ID, SENDER_ID, { text: 'Hola' } as any);

    // emitToUser se llama ANTES de mutar status a 'delivered'.
    // Pero como el DTO es un objeto mutable y la mutación ocurre después del emit,
    // la referencia ya estará mutada cuando Jest verifica. Verificar con 'delivered'.
    expect(mockSocketService.emitToUser).toHaveBeenCalledWith(
      RECEIVER_ID, 'message:received', { ...makeMsgDTO(), status: 'delivered' },
    );
  });

  it('debe lanzar NotFoundException si la conversación no existe', async () => {
    mockConversationRepo.findById.mockResolvedValue(null);

    await expect(
      useCase.execute('no-existe', SENDER_ID, { text: 'Hola' } as any),
    ).rejects.toThrow(NotFoundException);
  });

  it('debe lanzar ForbiddenException si el emisor no es participante', async () => {
    const conv = { ...makeConversation(), participants: ['otro1', 'otro2'] };
    mockConversationRepo.findById.mockResolvedValue(conv);

    await expect(
      useCase.execute(CONV_ID, SENDER_ID, { text: 'Hola' } as any),
    ).rejects.toThrow(ForbiddenException);
  });

  it('debe enviar push si el receptor está offline y tiene FCM token', async () => {
    mockConversationRepo.findById.mockResolvedValue(makeConversation());
    mockUserRepo.findById
      .mockResolvedValueOnce(makeUser(SENDER_ID))        // sender lookup
      .mockResolvedValueOnce(makeUser(RECEIVER_ID, true)); // receiver lookup para push
    mockMessageRepo.create.mockResolvedValue(makeMessage());
    mockMessageMapper.toResponseDTO.mockReturnValue(makeMsgDTO());
    mockSocketService.isOnline.mockReturnValue(false);

    await useCase.execute(CONV_ID, SENDER_ID, { text: 'Hola' } as any);

    expect(mockNotificationService.sendToUser).toHaveBeenCalledTimes(1);
  });

  it('NO debe enviar push si el receptor está online', async () => {
    mockConversationRepo.findById.mockResolvedValue(makeConversation());
    // Solo se consume 1 findById (sender). El receiver no se busca porque
    // online → push omitido. NO encolar el receiver para no contaminar
    // la cola de mockResolvedValueOnce de tests subsiguientes
    // (clearAllMocks NO purga ese queue, solo .mock.calls).
    mockUserRepo.findById.mockResolvedValueOnce(makeUser(SENDER_ID));
    mockMessageRepo.create.mockResolvedValue(makeMessage());
    mockMessageMapper.toResponseDTO.mockReturnValue(makeMsgDTO());
    mockSocketService.isOnline.mockReturnValue(true);

    await useCase.execute(CONV_ID, SENDER_ID, { text: 'Hola' } as any);

    expect(mockNotificationService.sendToUser).not.toHaveBeenCalled();
  });

  it('push con un único sender pendiente → "Tienes nuevos mensajes de [Nombre]" + collapseKey por receptor + body vacío', async () => {
    mockConversationRepo.findById.mockResolvedValue(makeConversation());
    const sender = new User({
      id: SENDER_ID, name: 'Alicia', email: 'a@a.com', passwordHash: 'h',
      preferences: { appearInChatSearch: true, considerWeatherByDefault: false, isPrivate: false },
      createdAt: new Date(), updatedAt: new Date(),
    });
    mockUserRepo.findById
      .mockResolvedValueOnce(sender)
      .mockResolvedValueOnce(makeUser(RECEIVER_ID, true));
    mockMessageRepo.create.mockResolvedValue(makeMessage());
    mockMessageMapper.toResponseDTO.mockReturnValue(makeMsgDTO());
    mockSocketService.isOnline.mockReturnValue(false);
    mockMessageRepo.findDistinctUnreadSenderIds.mockResolvedValue([SENDER_ID]);

    // El body va vacío por privacidad — la notificación del SO no muestra
    // el contenido del mensaje, solo el título.
    await useCase.execute(CONV_ID, SENDER_ID, { text: 'Hola, cómo estás?' } as any);

    expect(mockNotificationService.sendToUser).toHaveBeenCalledWith(
      'fcm-token-xyz',
      {
        title:       'Tienes nuevos mensajes de Alicia',
        body:        '',
        data:        { conversationId: CONV_ID, type: 'chat_message' },
        userId:      RECEIVER_ID,
        collapseKey: `chat_${RECEIVER_ID}`,
      },
    );
  });

  it('dedup: NO debe re-enviar push si lastChatPushTitle === título nuevo (mismo sender)', async () => {
    mockConversationRepo.findById.mockResolvedValue(makeConversation());
    const sender = new User({
      id: SENDER_ID, name: 'Alicia', email: 'a@a.com', passwordHash: 'h',
      preferences: { appearInChatSearch: true, considerWeatherByDefault: false, isPrivate: false },
      createdAt: new Date(), updatedAt: new Date(),
    });
    // Receptor con lastChatPushTitle ya guardado igual al que se calculará.
    const receiver = new User({
      id:                'receiver-001',
      name:              'Receptor',
      email:             'r@r.com',
      passwordHash:      'h',
      fcmToken:          'fcm-token-xyz',
      lastChatPushTitle: 'Tienes nuevos mensajes de Alicia',
      preferences:       { appearInChatSearch: true, considerWeatherByDefault: false, isPrivate: false },
      createdAt:         new Date(),
      updatedAt:         new Date(),
    });
    mockUserRepo.findById
      .mockResolvedValueOnce(sender)
      .mockResolvedValueOnce(receiver);
    mockMessageRepo.create.mockResolvedValue(makeMessage());
    mockMessageMapper.toResponseDTO.mockReturnValue(makeMsgDTO());
    mockSocketService.isOnline.mockReturnValue(false);
    mockMessageRepo.findDistinctUnreadSenderIds.mockResolvedValue([SENDER_ID]);

    await useCase.execute(CONV_ID, SENDER_ID, { text: 'Otro mensaje' } as any);

    // NO se invoca FCM (push skipped por dedup) NI se persiste de nuevo
    // (el título no cambió).
    expect(mockNotificationService.sendToUser).not.toHaveBeenCalled();
    expect(mockUserRepo.update).not.toHaveBeenCalled();
  });

  it('SÍ envía push si el título cambia (sender único → varios usuarios)', async () => {
    mockConversationRepo.findById.mockResolvedValue(makeConversation());
    const sender = new User({
      id: SENDER_ID, name: 'Alicia', email: 'a@a.com', passwordHash: 'h',
      preferences: { appearInChatSearch: true, considerWeatherByDefault: false, isPrivate: false },
      createdAt: new Date(), updatedAt: new Date(),
    });
    // Receptor con lastChatPushTitle = "de Alicia"; ahora hay otro sender más.
    const receiver = new User({
      id:                'receiver-001',
      name:              'Receptor',
      email:             'r@r.com',
      passwordHash:      'h',
      fcmToken:          'fcm-token-xyz',
      lastChatPushTitle: 'Tienes nuevos mensajes de Alicia',
      preferences:       { appearInChatSearch: true, considerWeatherByDefault: false, isPrivate: false },
      createdAt:         new Date(),
      updatedAt:         new Date(),
    });
    mockUserRepo.findById
      .mockResolvedValueOnce(sender)
      .mockResolvedValueOnce(receiver);
    mockMessageRepo.create.mockResolvedValue(makeMessage());
    mockMessageMapper.toResponseDTO.mockReturnValue(makeMsgDTO());
    mockSocketService.isOnline.mockReturnValue(false);
    mockMessageRepo.findDistinctUnreadSenderIds.mockResolvedValue([SENDER_ID, 'otro-sender']);

    await useCase.execute(CONV_ID, SENDER_ID, { text: 'Hola' } as any);

    expect(mockNotificationService.sendToUser).toHaveBeenCalledWith(
      'fcm-token-xyz',
      expect.objectContaining({ title: 'Tienes nuevos mensajes de Varios usuarios' }),
    );
    // Persiste el nuevo título para futuro dedup.
    expect(mockUserRepo.update).toHaveBeenCalledWith(
      'receiver-001',
      { lastChatPushTitle: 'Tienes nuevos mensajes de Varios usuarios' },
    );
  });

  it('push con varios senders pendientes → "Tienes nuevos mensajes de Varios usuarios" + body vacío', async () => {
    mockConversationRepo.findById.mockResolvedValue(makeConversation());
    mockUserRepo.findById
      .mockResolvedValueOnce(makeUser(SENDER_ID))
      .mockResolvedValueOnce(makeUser(RECEIVER_ID, true));
    mockMessageRepo.create.mockResolvedValue(makeMessage());
    mockMessageMapper.toResponseDTO.mockReturnValue(makeMsgDTO());
    mockSocketService.isOnline.mockReturnValue(false);
    // El receiver ya tenía mensajes sin leer de otro sender; el actual añade el suyo.
    mockMessageRepo.findDistinctUnreadSenderIds.mockResolvedValue([SENDER_ID, 'otro-sender-id']);

    await useCase.execute(CONV_ID, SENDER_ID, { text: 'Hola' } as any);

    expect(mockNotificationService.sendToUser).toHaveBeenCalledWith(
      expect.any(String),
      expect.objectContaining({
        title:       'Tienes nuevos mensajes de Varios usuarios',
        body:        '',
        userId:      RECEIVER_ID,
        collapseKey: `chat_${RECEIVER_ID}`,
      }),
    );
  });
});

// ─── MarkMessagesAsReadUseCase ────────────────────────────────────────────────

describe('MarkMessagesAsReadUseCase', () => {
  let useCase: MarkMessagesAsReadUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    mockMessageRepo.markAsRead.mockResolvedValue(undefined);
    useCase = new MarkMessagesAsReadUseCase(
      mockConversationRepo as any,
      mockMessageRepo      as any,
      mockSocketService    as any,
    );
  });

  it('debe marcar los mensajes como leídos para el participante', async () => {
    mockConversationRepo.findById.mockResolvedValue(makeConversation());

    await useCase.execute(CONV_ID, SENDER_ID);

    expect(mockMessageRepo.markAsRead).toHaveBeenCalledWith(CONV_ID, SENDER_ID);
  });

  it('debe lanzar NotFoundException si la conversación no existe', async () => {
    mockConversationRepo.findById.mockResolvedValue(null);

    await expect(useCase.execute('no-existe', SENDER_ID)).rejects.toThrow(NotFoundException);
  });

  it('debe lanzar ForbiddenException si el usuario no es participante', async () => {
    const conv = { ...makeConversation(), participants: ['otro1', 'otro2'] };
    mockConversationRepo.findById.mockResolvedValue(conv);

    await expect(useCase.execute(CONV_ID, SENDER_ID)).rejects.toThrow(ForbiddenException);
  });
});
