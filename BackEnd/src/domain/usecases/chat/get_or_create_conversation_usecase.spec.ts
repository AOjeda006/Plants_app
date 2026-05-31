/**
 * @file get_or_create_conversation_usecase.spec.ts
 * @description Tests unitarios para GetOrCreateConversationUseCase.
 * Verifica que se devuelve la conversación existente, se crea una nueva si no existe,
 * se lanza ForbiddenException al intentar crear conversación con un perfil privado
 * y NotFoundException si el participante no existe.
 * @module Chat
 * @layer Domain
 */

import 'reflect-metadata';
import { GetOrCreateConversationUseCase } from './GetOrCreateConversationUseCase.js';
import { NotFoundException }             from '../../../core/exceptions/NotFoundException.js';
import { ForbiddenException }            from '../../../core/exceptions/ForbiddenException.js';
import { User }                          from '../../entities/User.js';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockConversationRepo = {
  findByParticipants: jest.fn(),
  create:             jest.fn(),
};

const mockUserRepo = {
  findById: jest.fn(),
};

const mockMapper = {
  toResponseDTO: jest.fn(),
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

const USER_ID        = 'user-001';
const PARTICIPANT_ID = 'participant-001';
const CONV_ID        = 'conv-001';
const FIXED_DATE     = new Date('2026-03-16T00:00:00.000Z');

const makeConversation = () => ({
  id:           CONV_ID,
  participants: [USER_ID, PARTICIPANT_ID],
  createdAt:    FIXED_DATE,
});

const makeUser = (id: string, isPrivate: boolean, role?: 'user' | 'admin') =>
  new User({
    id, name: 'Test', email: `${id}@x.com`, passwordHash: 'h',
    role: role ?? 'user',
    preferences: {
      appearInChatSearch:        true,
      considerWeatherByDefault:  false,
      isPrivate,
    },
    createdAt: new Date(), updatedAt: new Date(),
  });

const makeConvDTO = () => ({
  id:           CONV_ID,
  participant:  { id: PARTICIPANT_ID, name: 'Test', photo: undefined },
  unreadCount:  0,
  createdAt:    FIXED_DATE,
});

// ─── Suite ────────────────────────────────────────────────────────────────────

describe('GetOrCreateConversationUseCase', () => {
  let useCase: GetOrCreateConversationUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    mockMapper.toResponseDTO.mockReturnValue(makeConvDTO());

    useCase = new GetOrCreateConversationUseCase(
      mockConversationRepo as any,
      mockUserRepo         as any,
      mockMapper           as any,
    );
  });

  it('debe devolver la conversación existente sin crear una nueva', async () => {
    const existing = makeConversation();
    mockUserRepo.findById.mockResolvedValue(makeUser(PARTICIPANT_ID, false));
    mockConversationRepo.findByParticipants.mockResolvedValue(existing);

    const result = await useCase.execute(PARTICIPANT_ID, USER_ID);

    expect(mockConversationRepo.create).not.toHaveBeenCalled();
    expect(result).toEqual(makeConvDTO());
  });

  it('debe crear una conversación nueva si no existe y el participante es público', async () => {
    mockUserRepo.findById.mockResolvedValue(makeUser(PARTICIPANT_ID, false));
    mockConversationRepo.findByParticipants.mockResolvedValue(null);
    mockConversationRepo.create.mockResolvedValue(makeConversation());

    await useCase.execute(PARTICIPANT_ID, USER_ID);

    expect(mockConversationRepo.create).toHaveBeenCalledWith(USER_ID, PARTICIPANT_ID);
  });

  it('debe lanzar ForbiddenException al iniciar conversación con perfil privado sin conversación previa', async () => {
    mockUserRepo.findById.mockResolvedValue(makeUser(PARTICIPANT_ID, true));
    mockConversationRepo.findByParticipants.mockResolvedValue(null);

    await expect(
      useCase.execute(PARTICIPANT_ID, USER_ID),
    ).rejects.toThrow(ForbiddenException);

    expect(mockConversationRepo.create).not.toHaveBeenCalled();
  });

  it('debe devolver conversación existente con perfil privado si ya hay conversación previa', async () => {
    const existing = makeConversation();
    mockUserRepo.findById.mockResolvedValue(makeUser(PARTICIPANT_ID, true));
    mockConversationRepo.findByParticipants.mockResolvedValue(existing);

    // No debe lanzar aunque el perfil sea privado — ya existe conversación
    await expect(
      useCase.execute(PARTICIPANT_ID, USER_ID),
    ).resolves.toEqual(makeConvDTO());

    expect(mockConversationRepo.create).not.toHaveBeenCalled();
  });

  it('debe lanzar NotFoundException si el participante no existe', async () => {
    mockUserRepo.findById.mockResolvedValue(null);

    await expect(
      useCase.execute('no-existe', USER_ID),
    ).rejects.toThrow(NotFoundException);
  });

  it('admin puede iniciar conversación con perfil privado sin conversación previa', async () => {
    const privateParticipant = makeUser(PARTICIPANT_ID, true);
    const adminUser          = makeUser(USER_ID, false, 'admin');
    // Primera llamada: participante (privado); segunda llamada: solicitante (admin)
    mockUserRepo.findById
      .mockResolvedValueOnce(privateParticipant)
      .mockResolvedValueOnce(adminUser);
    mockConversationRepo.findByParticipants.mockResolvedValue(null);
    mockConversationRepo.create.mockResolvedValue(makeConversation());

    await expect(
      useCase.execute(PARTICIPANT_ID, USER_ID),
    ).resolves.toBeDefined();

    // El admin debe poder crear la conversación.
    expect(mockConversationRepo.create).toHaveBeenCalledWith(USER_ID, PARTICIPANT_ID);
  });

  it('debe llamar al mapper con los datos del participante', async () => {
    const participant = makeUser(PARTICIPANT_ID, false);
    const conv        = makeConversation();
    mockUserRepo.findById.mockResolvedValue(participant);
    mockConversationRepo.findByParticipants.mockResolvedValue(conv);

    await useCase.execute(PARTICIPANT_ID, USER_ID);

    expect(mockMapper.toResponseDTO).toHaveBeenCalledWith(
      conv,
      { id: participant.id, name: participant.name, photo: participant.photo },
      undefined,
      0,
    );
  });
});
