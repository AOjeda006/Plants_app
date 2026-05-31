/**
 * @file process_pending_reminders_usecase.spec.ts
 * @description Tests unitarios para ProcessPendingRemindersUseCase.
 * Verifica: lock distribuido, idempotencia, envío de push, manejo de errores,
 * y suspensión tras MAX_ATTEMPTS.
 * @module Reminders
 * @layer Domain
 */

import 'reflect-metadata';
import { ProcessPendingRemindersUseCase } from './ProcessPendingRemindersUseCase.js';
import { User } from '../../entities/User.js';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockReminderRepo = {
  findPending:   jest.fn(),
  updateStatus:  jest.fn(),
};

const mockHistoryRepo = {
  exists: jest.fn(),
  create: jest.fn(),
};

const mockUserRepo = {
  findById: jest.fn(),
};

const mockNotifRepo = {
  create:            jest.fn(),
  countTodayByUserId: jest.fn(),
};

// Repos para _processHarvest (produceFruit) y _processPruning
const mockSpeciesRepo = {
  findFruitingThisMonth: jest.fn(),
  findPruningThisMonth:  jest.fn(),
  findById:              jest.fn(),
};

const mockPlantRepo = {
  findBySpeciesId:        jest.fn(),
  findPlantsNeedingCare:  jest.fn(),
  findDistinctUserIds:    jest.fn(),
  update:                 jest.fn(),
};

const mockWeatherDS = {
  keyForLocation:          jest.fn().mockReturnValue('40.4168,-3.7038'),
  fetchWeatherData:        jest.fn(),
  fetchYesterdayRainfall:  jest.fn().mockResolvedValue(0),
};

const mockNotificationService = {
  sendToUser: jest.fn(),
};

const mockLockService = {
  acquireLock: jest.fn(),
  releaseLock: jest.fn(),
};

// ─── Helper: reminder de ejemplo ──────────────────────────────────────────────

const makeReminder = (overrides = {}) => ({
  id:          'reminder-001',
  userId:      'user-001',
  plantId:     'plant-001',
  type:        'watering',
  message:     'Es hora de regar tu planta',
  scheduledDate: new Date(),
  attempts:    0,
  suspended:   false,
  ...overrides,
});

const makeUser = (withToken = true) =>
  new User({
    id:           'user-001',
    name:         'Test User',
    email:        'test@example.com',
    passwordHash: 'hash',
    fcmToken:     withToken ? 'fcm-token-abc' : undefined,
    preferences:  { appearInChatSearch: true, considerWeatherByDefault: false },
    createdAt:    new Date(),
    updatedAt:    new Date(),
  });

// ─── Suite ────────────────────────────────────────────────────────────────────

describe('ProcessPendingRemindersUseCase', () => {
  let useCase: ProcessPendingRemindersUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    mockLockService.acquireLock.mockResolvedValue(true);
    mockLockService.releaseLock.mockResolvedValue(undefined);
    mockHistoryRepo.create.mockResolvedValue(undefined);
    mockReminderRepo.updateStatus.mockResolvedValue(undefined);
    mockNotificationService.sendToUser.mockResolvedValue(undefined);
    mockNotifRepo.create.mockResolvedValue(undefined);
    // _processHarvest/_processPruning solo ejecutan días 1 y 15; tests generales devuelven listas vacías.
    mockSpeciesRepo.findFruitingThisMonth.mockResolvedValue([]);
    mockSpeciesRepo.findPruningThisMonth.mockResolvedValue([]);
    // _processWeather requiere plantas con coordenadas; por defecto no hay.
    mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([]);
    // _processAllClear: por defecto no hay usuarios con plantas → no genera "Todo al día".
    mockPlantRepo.findDistinctUserIds.mockResolvedValue([]);
    mockNotifRepo.countTodayByUserId.mockResolvedValue(0);

    useCase = new ProcessPendingRemindersUseCase(
      mockReminderRepo          as any,
      mockHistoryRepo           as any,
      mockUserRepo              as any,
      mockNotifRepo             as any,
      mockSpeciesRepo           as any,
      mockPlantRepo             as any,
      mockWeatherDS             as any,
      mockNotificationService   as any,
      // SocketService mock — emit es no-op si el usuario no está online;
      // en tests basta con un stub.
      { emitToUser: jest.fn(), broadcast: jest.fn() } as any,
      mockLockService           as any,
    );
  });

  it('debe omitir el procesamiento si no puede adquirir el lock', async () => {
    mockLockService.acquireLock.mockResolvedValue(false);

    await useCase.execute();

    expect(mockReminderRepo.findPending).not.toHaveBeenCalled();
  });

  it('debe liberar el lock aunque ocurra un error durante el procesamiento', async () => {
    mockReminderRepo.findPending.mockRejectedValue(new Error('DB error'));

    // execute() usa try/finally: libera el lock y re-lanza el error. Lo absorbemos aquí.
    await useCase.execute().catch(() => {});

    expect(mockLockService.releaseLock).toHaveBeenCalledTimes(1);
  });

  it('debe saltar un recordatorio que ya fue procesado hoy (idempotencia)', async () => {
    mockReminderRepo.findPending.mockResolvedValue([makeReminder()]);
    mockHistoryRepo.exists.mockResolvedValue(true);

    await useCase.execute();

    expect(mockNotificationService.sendToUser).not.toHaveBeenCalled();
    expect(mockHistoryRepo.create).not.toHaveBeenCalled();
  });

  it('debe enviar push notification y crear notificación in-app si el usuario tiene FCM token', async () => {
    mockReminderRepo.findPending.mockResolvedValue([makeReminder()]);
    mockHistoryRepo.exists.mockResolvedValue(false);
    mockUserRepo.findById.mockResolvedValue(makeUser(true));

    await useCase.execute();

    expect(mockNotificationService.sendToUser).toHaveBeenCalledTimes(1);
    expect(mockNotifRepo.create).toHaveBeenCalledWith(
      expect.objectContaining({ userId: 'user-001', type: 'watering', isRead: false }),
    );
    expect(mockHistoryRepo.create).toHaveBeenCalledWith(
      expect.objectContaining({ result: 'success' }),
    );
  });

  it('no debe enviar push pero sí crear notificación in-app si el usuario no tiene FCM token', async () => {
    mockReminderRepo.findPending.mockResolvedValue([makeReminder()]);
    mockHistoryRepo.exists.mockResolvedValue(false);
    mockUserRepo.findById.mockResolvedValue(makeUser(false));

    await useCase.execute();

    expect(mockNotificationService.sendToUser).not.toHaveBeenCalled();
    // La notificación in-app se crea siempre, independientemente del push.
    expect(mockNotifRepo.create).toHaveBeenCalledWith(
      expect.objectContaining({ userId: 'user-001', isRead: false }),
    );
    expect(mockHistoryRepo.create).toHaveBeenCalledWith(
      expect.objectContaining({ result: 'success' }),
    );
  });

  it('debe suspender el recordatorio cuando attempts alcanza MAX_ATTEMPTS (3)', async () => {
    mockReminderRepo.findPending.mockResolvedValue([makeReminder({ attempts: 2 })]);
    mockHistoryRepo.exists.mockResolvedValue(false);
    mockUserRepo.findById.mockResolvedValue(makeUser(true));

    await useCase.execute();

    expect(mockReminderRepo.updateStatus).toHaveBeenCalledWith(
      'reminder-001',
      expect.objectContaining({ suspended: true, attempts: 3 }),
    );
  });

  it('debe registrar error en historial si ocurre una excepción durante el procesamiento', async () => {
    mockReminderRepo.findPending.mockResolvedValue([makeReminder()]);
    mockHistoryRepo.exists.mockResolvedValue(false);
    // El loop ya no llama findById (eso ahora ocurre solo en
    // _drainPushQueue al final). Forzamos el error en notifRepo.create
    // que sí es el primer punto de fallo dentro del catch del loop.
    mockNotifRepo.create.mockRejectedValueOnce(new Error('DB error'));
    mockHistoryRepo.create.mockResolvedValue(undefined);

    await useCase.execute();

    expect(mockHistoryRepo.create).toHaveBeenCalledWith(
      expect.objectContaining({ result: 'error' }),
    );
  });

  // ── _processWeather ───────────────────────────────────────────────────────────

  describe('_processWeather', () => {
    /** Planta de exterior con coordenadas. */
    const makePlantWithCoords = (overrides = {}) => ({
      id:               'plant-ext-001',
      userId:           'user-001',
      name:             'Rosa del jardín',
      location:         'Exterior',
      plantLocationLat: 40.4168,
      plantLocationLon: -3.7038,
      plantLocation:    'Madrid',
      ...overrides,
    });

    /** Forecast con probabilidad de lluvia uniforme en las primeras 24h. */
    const makeWeatherForecast = (rainProbability: number, condition = 'Partly cloudy') => ({
      current: { temperature: 20, humidity: 60, condition, rainProbability, windSpeed: 10, feelsLike: 19 },
      forecast: Array.from({ length: 48 }, (_, i) => ({
        hour:            new Date(Date.now() + i * 3_600_000).toISOString(),
        temperature:     20,
        humidity:        60,
        rainProbability: i < 24 ? rainProbability : 0,
        condition:       i === 3 && condition !== 'Partly cloudy' ? condition : 'Partly cloudy',
        willItRain:      rainProbability >= 70,
      })),
    });

    beforeEach(() => {
      // En los tests de weather no hay recordatorios pendientes ni cosecha/poda.
      mockReminderRepo.findPending.mockResolvedValue([]);
      mockSpeciesRepo.findFruitingThisMonth.mockResolvedValue([]);
      mockSpeciesRepo.findPruningThisMonth.mockResolvedValue([]);
    });

    it('debe crear notificación de lluvia cuando probabilidad >= 70% en las próximas 24h', async () => {
      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([makePlantWithCoords()]);
      mockHistoryRepo.exists.mockResolvedValue(false);
      mockWeatherDS.fetchWeatherData.mockResolvedValue(makeWeatherForecast(80));

      await useCase.execute();

      expect(mockNotifRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({
          userId:  'user-001',
          type:    'watering',
          plantId: 'plant-ext-001',
          isRead:  false,
        }),
      );
      expect(mockHistoryRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({
          idempotencyKey: expect.stringContaining('weather_rain_plant-ext-001'),
          result: 'success',
        }),
      );
    });

    it('no debe crear notificación de lluvia cuando probabilidad < 70%', async () => {
      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([makePlantWithCoords()]);
      mockHistoryRepo.exists.mockResolvedValue(false);
      mockWeatherDS.fetchWeatherData.mockResolvedValue(makeWeatherForecast(50));

      await useCase.execute();

      expect(mockNotifRepo.create).not.toHaveBeenCalled();
    });

    // Al posponer riego por lluvia se resetea nextWatering.
    it('debe resetear nextWatering = today + freq cuando se pospone riego por lluvia', async () => {
      const plant = makePlantWithCoords({ wateringFrequency: 7, speciesId: 'species-001' });
      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([plant]);
      mockHistoryRepo.exists.mockResolvedValue(false);
      mockWeatherDS.fetchWeatherData.mockResolvedValue(makeWeatherForecast(80));
      mockSpeciesRepo.findById.mockResolvedValue({ name: 'Rosa' }); // sin seasonalAdjustment → factor 1
      mockPlantRepo.update.mockResolvedValue({});

      await useCase.execute();

      expect(mockPlantRepo.update).toHaveBeenCalledWith(
        'plant-ext-001',
        expect.objectContaining({ nextWatering: expect.any(Date) }),
      );
      // La fecha resultante debe estar a ~7 días en el futuro (today + freq).
      const updateCall = mockPlantRepo.update.mock.calls[0];
      const newNextWatering = (updateCall[1] as { nextWatering: Date }).nextWatering;
      const diffMs   = newNextWatering.getTime() - Date.now();
      const diffDays = Math.round(diffMs / (1000 * 60 * 60 * 24));
      expect(diffDays).toBeGreaterThanOrEqual(6);
      expect(diffDays).toBeLessThanOrEqual(8);
    });

    it('NO debe resetear nextWatering si la idempotency key del día ya existe', async () => {
      const plant = makePlantWithCoords({ wateringFrequency: 7 });
      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([plant]);
      mockHistoryRepo.exists.mockResolvedValue(true); // ya existe → idempotente
      mockWeatherDS.fetchWeatherData.mockResolvedValue(makeWeatherForecast(80));

      await useCase.execute();

      expect(mockPlantRepo.update).not.toHaveBeenCalled();
      expect(mockNotifRepo.create).not.toHaveBeenCalled();
    });

    it('debe crear notificación de tormenta cuando la condición contiene "storm" en las próximas 24h', async () => {
      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([makePlantWithCoords()]);
      mockHistoryRepo.exists.mockResolvedValue(false);
      mockWeatherDS.fetchWeatherData.mockResolvedValue(makeWeatherForecast(40, 'Heavy Thunderstorm'));

      await useCase.execute();

      expect(mockHistoryRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({
          idempotencyKey: expect.stringContaining('weather_storm_plant-ext-001'),
          result: 'success',
        }),
      );
    });

    it('debe omitir plantas sin coordenadas de ubicación', async () => {
      const plantNoCoords = { id: 'plant-indoor', userId: 'user-001', name: 'Suculenta' };
      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([plantNoCoords]);

      await useCase.execute();

      expect(mockWeatherDS.fetchWeatherData).not.toHaveBeenCalled();
      expect(mockNotifRepo.create).not.toHaveBeenCalled();
    });

    it('debe respetar la idempotencia y no crear notificación si ya existe clave para hoy', async () => {
      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([makePlantWithCoords()]);
      // Simular que la clave ya existe en historial.
      mockHistoryRepo.exists.mockResolvedValue(true);
      mockWeatherDS.fetchWeatherData.mockResolvedValue(makeWeatherForecast(90));

      await useCase.execute();

      expect(mockNotifRepo.create).not.toHaveBeenCalled();
    });

    it('debe continuar con las siguientes plantas si una falla al obtener el clima', async () => {
      const plant1 = makePlantWithCoords({ id: 'plant-ok', name: 'Rosa' });
      const plant2 = makePlantWithCoords({ id: 'plant-fail', name: 'Tulipán' });

      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([plant1, plant2]);
      mockHistoryRepo.exists.mockResolvedValue(false);

      // La primera planta falla; la segunda devuelve lluvia alta.
      mockWeatherDS.fetchWeatherData
        .mockRejectedValueOnce(new Error('WeatherAPI error'))
        .mockResolvedValueOnce(makeWeatherForecast(85));

      // No debe lanzar excepción global; devuelve un resumen.
      await expect(useCase.execute()).resolves.toEqual(
        expect.objectContaining({ skipped: false }),
      );

      // La segunda planta sí generó notificación.
      expect(mockNotifRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({ plantId: 'plant-fail' }),
      );
    });

    it('debe excluir plantas de interior del procesamiento de weather', async () => {
      const interiorPlant = {
        id:               'plant-interior',
        userId:           'user-001',
        name:             'Helecho salón',
        location:         'Interior',
        plantLocationLat: 40.4168,
        plantLocationLon: -3.7038,
        plantLocation:    'Madrid',
      };
      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([interiorPlant]);
      mockHistoryRepo.exists.mockResolvedValue(false);

      await useCase.execute();

      // No debe consultar el clima ni crear notificaciones para plantas de interior.
      expect(mockWeatherDS.fetchWeatherData).not.toHaveBeenCalled();
      expect(mockNotifRepo.create).not.toHaveBeenCalled();
    });
  });

  // ── _processYesterdayRain ──────────────────────────────────────────────────

  describe('_processYesterdayRain', () => {
    const makePlantOutdoor = (overrides = {}) => ({
      id:                    'plant-ext-001',
      userId:                'user-001',
      name:                  'Rosa del jardín',
      location:              'Exterior',
      plantLocationLat:      40.4168,
      plantLocationLon:      -3.7038,
      plantLocation:         'Madrid',
      wateringFrequency:     7,
      speciesId:             'species-001',
      ...overrides,
    });

    beforeEach(() => {
      mockReminderRepo.findPending.mockResolvedValue([]);
      mockSpeciesRepo.findFruitingThisMonth.mockResolvedValue([]);
      mockSpeciesRepo.findPruningThisMonth.mockResolvedValue([]);
      // Reset del mock de fetchWeatherData para que un mockResolvedValue
      // sticky del bloque _processWeather no contamine este describe
      // (_processWeather también llama a plantRepo.update si maxRain >= 70).
      mockWeatherDS.fetchWeatherData.mockReset();
      mockWeatherDS.fetchWeatherData.mockRejectedValue(
        new Error('forecast not stubbed in _processYesterdayRain tests'),
      );
    });

    it('debe marcar planta como regada si precipitación ayer >= umbral de la especie', async () => {
      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([makePlantOutdoor()]);
      mockWeatherDS.fetchYesterdayRainfall.mockResolvedValue(10);
      mockSpeciesRepo.findById.mockResolvedValue({ minRainfallMm: 5, name: 'Rosa' });
      mockHistoryRepo.exists.mockResolvedValue(false);
      mockPlantRepo.update.mockResolvedValue({});

      await useCase.execute();

      // Debe actualizar nextWatering de la planta.
      expect(mockPlantRepo.update).toHaveBeenCalledWith(
        'plant-ext-001',
        expect.objectContaining({ nextWatering: expect.any(Date) }),
      );
      // Debe crear notificación de lluvia de ayer.
      expect(mockNotifRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({
          userId:  'user-001',
          type:    'watering',
          plantId: 'plant-ext-001',
          message: expect.stringContaining('Ayer llovió 10mm'),
        }),
      );
    });

    it('no debe marcar planta como regada si precipitación ayer < umbral', async () => {
      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([makePlantOutdoor()]);
      mockWeatherDS.fetchYesterdayRainfall.mockResolvedValue(3);
      mockSpeciesRepo.findById.mockResolvedValue({ minRainfallMm: 5, name: 'Rosa' });
      mockHistoryRepo.exists.mockResolvedValue(false);

      await useCase.execute();

      // No debe actualizar la planta ni crear notificación.
      expect(mockPlantRepo.update).not.toHaveBeenCalled();
    });

    it('debe excluir plantas de interior del procesamiento de lluvia de ayer', async () => {
      const interiorPlant = makePlantOutdoor({ location: 'Interior' });
      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([interiorPlant]);

      await useCase.execute();

      // No debe consultar la lluvia de ayer para plantas de interior.
      expect(mockWeatherDS.fetchYesterdayRainfall).not.toHaveBeenCalled();
    });

    it('debe usar DEFAULT_MIN_RAINFALL_MM (5mm) si la especie no define minRainfallMm', async () => {
      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([makePlantOutdoor()]);
      mockWeatherDS.fetchYesterdayRainfall.mockResolvedValue(6);
      // Especie sin minRainfallMm.
      mockSpeciesRepo.findById.mockResolvedValue({ name: 'Genérica' });
      mockHistoryRepo.exists.mockResolvedValue(false);
      mockPlantRepo.update.mockResolvedValue({});

      await useCase.execute();

      // 6mm >= 5mm (default) → debe actualizar.
      expect(mockPlantRepo.update).toHaveBeenCalled();
    });

    // ── Fórmula exhaustiva nextWatering = ayer + freq * factor ──

    /** Helper: extrae nextWatering del último update de plantRepo. */
    const lastNextWatering = (): Date => {
      const calls = mockPlantRepo.update.mock.calls;
      const last  = calls[calls.length - 1];
      return (last[1] as { nextWatering: Date }).nextWatering;
    };

    /** Helper: diferencia en días entre fecha y now (redondeada). */
    const daysFromNow = (d: Date): number =>
      Math.round((d.getTime() - Date.now()) / 86_400_000);

    it('freq=5, sin seasonalAdjustment, lluvia confirmada → ayer+5 = HOY+4', async () => {
      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([
        makePlantOutdoor({ wateringFrequency: 5 }),
      ]);
      mockWeatherDS.fetchYesterdayRainfall.mockResolvedValue(10);
      mockSpeciesRepo.findById.mockResolvedValue({ minRainfallMm: 5, name: 'Rosa' });
      mockHistoryRepo.exists.mockResolvedValue(false);
      mockPlantRepo.update.mockResolvedValue({});

      await useCase.execute();

      // ayer + 5 días = hoy + 4 días (asumiendo el cron corre cerca de la
      // medianoche de hoy; tolerancia ±1 día por husos horarios y rounding).
      const diff = daysFromNow(lastNextWatering());
      expect(diff).toBeGreaterThanOrEqual(3);
      expect(diff).toBeLessThanOrEqual(5);
    });

    it('freq=5, especie summer=0.6 en mes 7 (verano) → factor 0.6 → ayer+3', async () => {
      // Simulamos verano via jest fake timers.
      jest.useFakeTimers().setSystemTime(new Date('2026-07-15T08:00:00Z'));
      try {
        mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([
          makePlantOutdoor({ wateringFrequency: 5 }),
        ]);
        mockWeatherDS.fetchYesterdayRainfall.mockResolvedValue(10);
        mockSpeciesRepo.findById.mockResolvedValue({
          minRainfallMm: 5,
          name:          'Rosa',
          seasonalWateringAdjustment: { summer: 0.6, winter: 1.4 },
        });
        mockHistoryRepo.exists.mockResolvedValue(false);
        mockPlantRepo.update.mockResolvedValue({});

        await useCase.execute();

        // 5 * 0.6 = 3. ayer + 3 = HOY + 2.
        const diff = daysFromNow(lastNextWatering());
        expect(diff).toBeGreaterThanOrEqual(1);
        expect(diff).toBeLessThanOrEqual(3);
      } finally {
        jest.useRealTimers();
      }
    });

    it('freq=5, summer=0.6 pero mes 5 (primavera) → factor 1.0 → ayer+5', async () => {
      jest.useFakeTimers().setSystemTime(new Date('2026-05-15T08:00:00Z'));
      try {
        mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([
          makePlantOutdoor({ wateringFrequency: 5 }),
        ]);
        mockWeatherDS.fetchYesterdayRainfall.mockResolvedValue(10);
        mockSpeciesRepo.findById.mockResolvedValue({
          minRainfallMm: 5,
          name:          'Rosa',
          seasonalWateringAdjustment: { summer: 0.6, winter: 1.4 },
        });
        mockHistoryRepo.exists.mockResolvedValue(false);
        mockPlantRepo.update.mockResolvedValue({});

        await useCase.execute();

        // 5 * 1.0 = 5. ayer + 5 = HOY + 4.
        const diff = daysFromNow(lastNextWatering());
        expect(diff).toBeGreaterThanOrEqual(3);
        expect(diff).toBeLessThanOrEqual(5);
      } finally {
        jest.useRealTimers();
      }
    });

    it('freq=5, winter=1.4 en mes 1 (invierno) → factor 1.4 → ayer+7', async () => {
      jest.useFakeTimers().setSystemTime(new Date('2026-01-15T08:00:00Z'));
      try {
        mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([
          makePlantOutdoor({ wateringFrequency: 5 }),
        ]);
        mockWeatherDS.fetchYesterdayRainfall.mockResolvedValue(10);
        mockSpeciesRepo.findById.mockResolvedValue({
          minRainfallMm: 5,
          name:          'Rosa',
          seasonalWateringAdjustment: { summer: 0.7, winter: 1.4 },
        });
        mockHistoryRepo.exists.mockResolvedValue(false);
        mockPlantRepo.update.mockResolvedValue({});

        await useCase.execute();

        // round(5 * 1.4) = 7. ayer + 7 = HOY + 6.
        const diff = daysFromNow(lastNextWatering());
        expect(diff).toBeGreaterThanOrEqual(5);
        expect(diff).toBeLessThanOrEqual(7);
      } finally {
        jest.useRealTimers();
      }
    });

    it('freq=1, factor 1.0 → Math.max(1, round) garantiza mínimo 1 día', async () => {
      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([
        makePlantOutdoor({ wateringFrequency: 1 }),
      ]);
      mockWeatherDS.fetchYesterdayRainfall.mockResolvedValue(10);
      mockSpeciesRepo.findById.mockResolvedValue({ minRainfallMm: 5, name: 'Test' });
      mockHistoryRepo.exists.mockResolvedValue(false);
      mockPlantRepo.update.mockResolvedValue({});

      await useCase.execute();

      // ayer + 1 = HOY (o HOY-1 según hora).
      const diff = daysFromNow(lastNextWatering());
      expect(diff).toBeGreaterThanOrEqual(-1);
      expect(diff).toBeLessThanOrEqual(1);
    });

    it('especie sin coords NO se procesa por _processYesterdayRain', async () => {
      const noCoords = makePlantOutdoor({
        plantLocationLat: undefined,
        plantLocationLon: undefined,
      });
      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([noCoords]);

      await useCase.execute();

      expect(mockWeatherDS.fetchYesterdayRainfall).not.toHaveBeenCalled();
      expect(mockPlantRepo.update).not.toHaveBeenCalled();
    });

    it('idempotencia diaria — segunda ejecución del mismo día NO duplica', async () => {
      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([makePlantOutdoor()]);
      mockWeatherDS.fetchYesterdayRainfall.mockResolvedValue(10);
      mockSpeciesRepo.findById.mockResolvedValue({ minRainfallMm: 5, name: 'Rosa' });
      // historyRepo.exists devuelve true → key del día ya procesada.
      mockHistoryRepo.exists.mockResolvedValue(true);

      await useCase.execute();

      expect(mockPlantRepo.update).not.toHaveBeenCalled();
      expect(mockNotifRepo.create).not.toHaveBeenCalled();
    });
  });

  // ── _processWeather + pendingRainAdjustment ───────────────────────────────

  describe('_processWeather: pendingRainAdjustment guardado en reset', () => {
    const makePlantOutdoor = (overrides = {}) => ({
      id:                'plant-ext-001',
      userId:            'user-001',
      name:              'Rosa del jardín',
      location:          'Exterior',
      plantLocationLat:  40.4168,
      plantLocationLon:  -3.7038,
      plantLocation:     'Madrid',
      wateringFrequency: 7,
      speciesId:         'species-001',
      nextWatering:      new Date('2026-04-25T00:00:00Z'),
      pendingRainAdjustment: undefined,
      ...overrides,
    });

    const makeWeatherForecast = (rainProbability: number) => ({
      current: { temperature: 20, humidity: 60, condition: 'Cloudy', rainProbability, windSpeed: 10, feelsLike: 19 },
      forecast: Array.from({ length: 48 }, (_, i) => ({
        time:            new Date(Date.now() + i * 60 * 60 * 1000).toISOString(),
        temperature:     20,
        condition:       'Cloudy',
        rainProbability: i < 24 ? rainProbability : 0,
        precipitationMm: rainProbability >= 70 ? 5 : 0,
        willItRain:      rainProbability >= 70,
      })),
      cachedAt: new Date(),
    });

    beforeEach(() => {
      mockReminderRepo.findPending.mockResolvedValue([]);
      mockSpeciesRepo.findFruitingThisMonth.mockResolvedValue([]);
      mockSpeciesRepo.findPruningThisMonth.mockResolvedValue([]);
    });

    it('al hacer reset por previsión, persiste pendingRainAdjustment con previousNextWatering', async () => {
      const previous = new Date('2026-04-25T00:00:00Z');
      const plant = makePlantOutdoor({ nextWatering: previous });
      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([plant]);
      mockHistoryRepo.exists.mockResolvedValue(false);
      mockWeatherDS.fetchWeatherData.mockResolvedValue(makeWeatherForecast(85));
      mockSpeciesRepo.findById.mockResolvedValue({ name: 'Rosa' });
      mockPlantRepo.update.mockResolvedValue({});

      await useCase.execute();

      // El primer update debe incluir pendingRainAdjustment con previous.
      const updateCall = mockPlantRepo.update.mock.calls[0];
      expect(updateCall[0]).toBe('plant-ext-001');
      const patch = updateCall[1] as Record<string, unknown>;
      expect(patch).toHaveProperty('nextWatering');
      expect(patch).toHaveProperty('pendingRainAdjustment');
      const adj = patch['pendingRainAdjustment'] as Record<string, unknown>;
      expect(adj['previousNextWatering']).toBe(previous);
      expect(adj['expectedMm']).toBe(85);
      expect(adj['locationLat']).toBe(40.4168);
      expect(adj['locationLon']).toBe(-3.7038);
    });

    it('NO sobrescribe pendingRainAdjustment si la planta ya tiene uno (previsión consecutiva)', async () => {
      const firstResetDate = new Date('2026-04-24T00:00:00Z');
      const oldPrevious    = new Date('2026-04-22T00:00:00Z');
      const plant = makePlantOutdoor({
        pendingRainAdjustment: {
          resetAt:              firstResetDate,
          previousNextWatering: oldPrevious,
          expectedMm:           80,
          locationLat:          40.4168,
          locationLon:          -3.7038,
        },
      });
      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([plant]);
      mockHistoryRepo.exists.mockResolvedValue(false);
      mockWeatherDS.fetchWeatherData.mockResolvedValue(makeWeatherForecast(90));
      mockSpeciesRepo.findById.mockResolvedValue({ name: 'Rosa' });
      mockPlantRepo.update.mockResolvedValue({});

      await useCase.execute();

      const updateCall = mockPlantRepo.update.mock.calls[0];
      const patch = updateCall[1] as Record<string, unknown>;
      // Actualiza nextWatering pero NO incluye pendingRainAdjustment en el patch.
      expect(patch).toHaveProperty('nextWatering');
      expect(patch).not.toHaveProperty('pendingRainAdjustment');
    });
  });

  // ── _processYesterdayRain: confirmación / rollback ─────────────────────────

  describe('_processYesterdayRain: rollback de pendingRainAdjustment', () => {
    const makePlantWithPending = (overrides = {}) => ({
      id:                'plant-ext-001',
      userId:            'user-001',
      name:              'Rosa del jardín',
      location:          'Exterior',
      plantLocationLat:  40.4168,
      plantLocationLon:  -3.7038,
      plantLocation:     'Madrid',
      wateringFrequency: 7,
      speciesId:         'species-001',
      pendingRainAdjustment: {
        resetAt:              new Date('2026-04-25T00:00:00Z'),
        previousNextWatering: new Date('2026-04-26T00:00:00Z'),
        expectedMm:           80,
        locationLat:          40.4168,
        locationLon:          -3.7038,
      },
      ...overrides,
    });

    beforeEach(() => {
      mockReminderRepo.findPending.mockResolvedValue([]);
      mockSpeciesRepo.findFruitingThisMonth.mockResolvedValue([]);
      mockSpeciesRepo.findPruningThisMonth.mockResolvedValue([]);
      mockWeatherDS.fetchWeatherData.mockReset();
      mockWeatherDS.fetchWeatherData.mockRejectedValue(new Error('forecast not stubbed'));
    });

    it('confirma el reset si rainfall >= threshold: limpia pendingRainAdjustment y notifica "Confirmado"', async () => {
      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([makePlantWithPending()]);
      mockWeatherDS.fetchYesterdayRainfall.mockResolvedValue(8); // >= 5mm
      mockSpeciesRepo.findById.mockResolvedValue({ minRainfallMm: 5, name: 'Rosa' });
      mockHistoryRepo.exists.mockResolvedValue(false);
      mockPlantRepo.update.mockResolvedValue({});

      await useCase.execute();

      // Primer update debe limpiar pendingRainAdjustment a null.
      const updateCall = mockPlantRepo.update.mock.calls[0];
      const patch = updateCall[1] as Record<string, unknown>;
      expect(patch).toHaveProperty('pendingRainAdjustment', null);
      expect(patch).not.toHaveProperty('nextWatering');

      expect(mockNotifRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({
          message: expect.stringMatching(/Confirmado.*8mm/),
        }),
      );
    });

    it('aplica rollback si rainfall < threshold: restaura previousNextWatering + limpia + notifica', async () => {
      const previous = new Date('2026-04-26T00:00:00Z');
      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([
        makePlantWithPending({
          pendingRainAdjustment: {
            resetAt:              new Date('2026-04-25T00:00:00Z'),
            previousNextWatering: previous,
            expectedMm:           80,
            locationLat:          40.4168,
            locationLon:          -3.7038,
          },
        }),
      ]);
      mockWeatherDS.fetchYesterdayRainfall.mockResolvedValue(2); // < 5mm
      mockSpeciesRepo.findById.mockResolvedValue({ minRainfallMm: 5, name: 'Rosa' });
      mockHistoryRepo.exists.mockResolvedValue(false);
      mockPlantRepo.update.mockResolvedValue({});

      await useCase.execute();

      const updateCall = mockPlantRepo.update.mock.calls[0];
      const patch = updateCall[1] as Record<string, unknown>;
      expect(patch).toEqual(
        expect.objectContaining({
          nextWatering:          previous,
          pendingRainAdjustment: null,
        }),
      );

      expect(mockNotifRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({
          message: expect.stringMatching(/no llegó/),
        }),
      );
    });

    it('respeta idempotencia diaria — no procesa dos veces el mismo pendingRainAdjustment', async () => {
      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([makePlantWithPending()]);
      mockWeatherDS.fetchYesterdayRainfall.mockResolvedValue(8);
      mockSpeciesRepo.findById.mockResolvedValue({ minRainfallMm: 5, name: 'Rosa' });
      // Idempotency key del rollback ya existe → skip.
      mockHistoryRepo.exists.mockResolvedValue(true);

      await useCase.execute();

      expect(mockPlantRepo.update).not.toHaveBeenCalled();
      expect(mockNotifRepo.create).not.toHaveBeenCalled();
    });

    // ── Decisión #211: fixes detectados en el repaso de Mayo 2026 ───────────

    it('NO procesa pendingRainAdjustment creado HOY (resetAt=today) — se difiere a mañana', async () => {
      // Adjustment con resetAt=hoy → _processWeather lo acaba de crear en
      // el mismo execute() del cron. _processYesterdayRain debe ignorarlo
      // (no tiene sentido verificar la previsión de HOY contra la lluvia
      // de AYER, que es lo que devuelve fetchYesterdayRainfall).
      const today = new Date();
      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([
        makePlantWithPending({
          pendingRainAdjustment: {
            resetAt:              today,
            previousNextWatering: new Date('2026-04-26T00:00:00Z'),
            expectedMm:           80,
            locationLat:          40.4168,
            locationLon:          -3.7038,
          },
        }),
      ]);
      mockWeatherDS.fetchYesterdayRainfall.mockResolvedValue(2); // < 5mm — habría disparado rollback
      mockSpeciesRepo.findById.mockResolvedValue({ minRainfallMm: 5, name: 'Rosa' });
      mockHistoryRepo.exists.mockResolvedValue(false);

      const summary = await useCase.execute();

      // NO se llama a plantRepo.update (rollback no ejecutado).
      expect(mockPlantRepo.update).not.toHaveBeenCalled();
      // NO se crea notificación de rollback.
      expect(mockNotifRepo.create).not.toHaveBeenCalledWith(
        expect.objectContaining({ message: expect.stringMatching(/no llegó/) }),
      );
      // Diagnóstico explícito en el summary.
      expect(summary.diagnostics.join(' ')).toMatch(/yesterdayRain_skip_sameday/);
    });

    it('rollback con previousNextWatering=null → nextWatering pasa a HOY (no se queda en valor de reset)', async () => {
      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([
        makePlantWithPending({
          pendingRainAdjustment: {
            resetAt:              new Date('2026-04-25T00:00:00Z'), // ayer o antes
            previousNextWatering: null, // planta sin schedule previo
            expectedMm:           80,
            locationLat:          40.4168,
            locationLon:          -3.7038,
          },
        }),
      ]);
      mockWeatherDS.fetchYesterdayRainfall.mockResolvedValue(2);
      mockSpeciesRepo.findById.mockResolvedValue({ minRainfallMm: 5, name: 'Rosa' });
      mockHistoryRepo.exists.mockResolvedValue(false);
      mockPlantRepo.update.mockResolvedValue({});

      await useCase.execute();

      const updateCall = mockPlantRepo.update.mock.calls[0];
      const patch = updateCall![1] as Record<string, unknown>;
      // nextWatering NO debe ser undefined (eso dejaría el valor de reset
      // intacto en MongoDB $set). Debe ser una Date no nula.
      expect(patch).toHaveProperty('nextWatering');
      expect(patch['nextWatering']).toBeInstanceOf(Date);
      expect(patch).toHaveProperty('pendingRainAdjustment', null);
    });
  });

  // ── Decisión #211: rama no-pending sólo aplica si lluvia POSPONE riego ─

  describe('rama no-pending de _processYesterdayRain', () => {
    const makePlantOutdoor = (overrides = {}) => ({
      id:                'plant-out-001',
      userId:            'user-001',
      name:              'Cactus',
      location:          'Exterior',
      plantLocationLat:  40.4168,
      plantLocationLon:  -3.7038,
      plantLocation:     'Madrid',
      wateringFrequency: 5,
      speciesId:         'species-001',
      ...overrides,
    });

    beforeEach(() => {
      mockReminderRepo.findPending.mockResolvedValue([]);
      mockSpeciesRepo.findFruitingThisMonth.mockResolvedValue([]);
      mockSpeciesRepo.findPruningThisMonth.mockResolvedValue([]);
      mockWeatherDS.fetchWeatherData.mockReset();
      mockWeatherDS.fetchWeatherData.mockRejectedValue(new Error('forecast not stubbed'));
      mockSpeciesRepo.findById.mockResolvedValue({ minRainfallMm: 5, name: 'Test' });
      mockHistoryRepo.exists.mockResolvedValue(false);
    });

    it('NO actualiza nextWatering si la lluvia de ayer daría una fecha ANTERIOR a la actual (sería traer el riego hacia adelante)', async () => {
      // Planta freq=5, nextWatering=today+10 (regada recientemente con freq custom larga).
      // Yesterday + 5 = today + 4 — anterior a today + 10 → NO actualizar.
      const today = new Date();
      const future = new Date(today);
      future.setDate(future.getDate() + 10);

      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([
        makePlantOutdoor({ nextWatering: future }),
      ]);
      mockWeatherDS.fetchYesterdayRainfall.mockResolvedValue(8); // >= 5mm

      const summary = await useCase.execute();

      expect(mockPlantRepo.update).not.toHaveBeenCalled();
      expect(summary.diagnostics.join(' ')).toMatch(/yesterdayRain_skip_no_improvement/);
    });

    it('SÍ actualiza nextWatering si la lluvia de ayer POSPONE el riego (fecha posterior a la actual)', async () => {
      // Planta freq=5, nextWatering=today (ya tocaba regar).
      // Yesterday + 5 = today + 4 — posterior a today → ACTUALIZAR.
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([
        makePlantOutdoor({ nextWatering: today }),
      ]);
      mockWeatherDS.fetchYesterdayRainfall.mockResolvedValue(8);
      mockPlantRepo.update.mockResolvedValue({});

      await useCase.execute();

      expect(mockPlantRepo.update).toHaveBeenCalledTimes(1);
      const patch = mockPlantRepo.update.mock.calls[0]![1] as Record<string, unknown>;
      expect(patch).toHaveProperty('nextWatering');
    });
  });

  // ── Decisión #211 (Bug 5): tormenta detectada en español ───────────────────

  describe('stormHour reconoce condiciones en español', () => {
    const makePlantOutdoor = (overrides = {}) => ({
      id:                'plant-storm-001',
      userId:            'user-001',
      name:              'Limonero',
      location:          'Exterior',
      plantLocationLat:  40.4168,
      plantLocationLon:  -3.7038,
      plantLocation:     'Madrid',
      wateringFrequency: 7,
      speciesId:         'species-001',
      nextWatering:      new Date('2026-04-25T00:00:00Z'),
      ...overrides,
    });

    const makeForecastWithCondition = (cond: string) => ({
      current: { temperature: 20, humidity: 60, condition: cond, rainProbability: 0, windSpeed: 10, feelsLike: 19 },
      forecast: Array.from({ length: 48 }, (_, i) => ({
        time:            new Date(Date.now() + i * 3600_000).toISOString(),
        temperature:     20,
        condition:       i === 5 ? cond : 'Parcialmente nublado',
        rainProbability: 0,
        willItRain:      false,
      })),
      cachedAt: new Date(),
    });

    beforeEach(() => {
      mockReminderRepo.findPending.mockResolvedValue([]);
      mockSpeciesRepo.findFruitingThisMonth.mockResolvedValue([]);
      mockSpeciesRepo.findPruningThisMonth.mockResolvedValue([]);
      mockPlantRepo.findPlantsNeedingCare.mockResolvedValue([makePlantOutdoor()]);
      mockHistoryRepo.exists.mockResolvedValue(false);
      mockSpeciesRepo.findById.mockResolvedValue({ name: 'Limonero' });
      mockPlantRepo.update.mockResolvedValue({});
    });

    it('detecta "Tormenta eléctrica" (lang=es) y crea notificación de tormenta', async () => {
      mockWeatherDS.fetchWeatherData.mockResolvedValue(makeForecastWithCondition('Tormenta eléctrica'));

      await useCase.execute();

      // El mensaje de NotificationMessages.watering.stormAlert es
      // `Alerta para "X": ${condition} esperada hoy` — el matcher cubre
      // tanto "Tormenta..." como "Truenos..." y futuras condiciones.
      expect(mockNotifRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({
          type:    'watering',
          message: expect.stringMatching(/^Alerta para/),
        }),
      );
    });

    it('detecta "Truenos dispersos" (lang=es) y crea notificación de tormenta', async () => {
      mockWeatherDS.fetchWeatherData.mockResolvedValue(makeForecastWithCondition('Truenos dispersos'));

      await useCase.execute();

      // El mensaje de NotificationMessages.watering.stormAlert es
      // `Alerta para "X": ${condition} esperada hoy` — el matcher cubre
      // tanto "Tormenta..." como "Truenos..." y futuras condiciones.
      expect(mockNotifRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({
          type:    'watering',
          message: expect.stringMatching(/^Alerta para/),
        }),
      );
    });

    it('sigue detectando "Thunderstorm" en inglés (compatibilidad atrás)', async () => {
      mockWeatherDS.fetchWeatherData.mockResolvedValue(makeForecastWithCondition('Thunderstorm'));

      await useCase.execute();

      expect(mockNotifRepo.create).toHaveBeenCalled();
    });
  });

  // ── CronRunSummary ─────────────────────────────────────────────────────────

  describe('CronRunSummary', () => {
    it('execute() debe devolver un objeto CronRunSummary con contadores y diagnostics', async () => {
      mockReminderRepo.findPending.mockResolvedValue([]);

      const result = await useCase.execute();

      expect(result).toEqual(
        expect.objectContaining({
          skipped:     false,
          created:     expect.objectContaining({ total: expect.any(Number) }),
          diagnostics: expect.any(Array),
        }),
      );
    });
  });
});
