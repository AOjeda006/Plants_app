/**
 * @file weather_service.spec.ts
 * @description Tests unitarios para WeatherService.
 * Verifica cache hit, cache miss (refresca desde API), getForecast y shouldWater.
 * @module Weather
 * @layer Presentation
 */

import 'reflect-metadata';
import { WeatherService } from './WeatherService.js';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockDataSource = {
  keyForLocation:   jest.fn(),
  fetchWeatherData: jest.fn(),
};

const mockCacheRepo = {
  findByLocationKey: jest.fn(),
  save:              jest.fn(),
};

const mockMapper = {
  toWeatherResponseDTO:  jest.fn(),
  toForecastResponseDTO: jest.fn(),
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

const LAT = 40.4168;
const LON = -3.7038;
const LOC_KEY = '40.42,-3.70';

const makeCachedWeather = () => ({
  locationKey: LOC_KEY,
  data:        { current: { tempC: 20 } },
  fetchedAt:   new Date(),
  expiresAt:   new Date(Date.now() + 3600_000),
});

const makeWeatherDTO = () => ({ location: LOC_KEY, tempC: 20, humidity: 60 });
const makeForecastDTO = (hours: { rainProbability: number }[] = []) => ({ hours });

// ─── Suite ────────────────────────────────────────────────────────────────────

describe('WeatherService', () => {
  let service: WeatherService;

  beforeEach(() => {
    jest.clearAllMocks();
    mockDataSource.keyForLocation.mockReturnValue(LOC_KEY);
    service = new WeatherService(
      mockDataSource as any,
      mockCacheRepo   as any,
      mockMapper      as any,
    );
  });

  // ── getWeatherForLocation ────────────────────────────────────────────────────

  describe('getWeatherForLocation()', () => {
    it('debe devolver datos del caché si existe y no ha expirado (cache hit)', async () => {
      const cached = makeCachedWeather();
      mockCacheRepo.findByLocationKey.mockResolvedValue(cached);
      mockMapper.toWeatherResponseDTO.mockReturnValue(makeWeatherDTO());

      const result = await service.getWeatherForLocation(LAT, LON);

      expect(mockDataSource.fetchWeatherData).not.toHaveBeenCalled();
      expect(mockMapper.toWeatherResponseDTO).toHaveBeenCalledWith(cached);
      expect(result).toEqual(makeWeatherDTO());
    });

    it('debe llamar a la API y guardar en caché si no hay datos en caché (cache miss)', async () => {
      mockCacheRepo.findByLocationKey.mockResolvedValue(null);
      const apiData = { current: { tempC: 18 } };
      mockDataSource.fetchWeatherData.mockResolvedValue(apiData);
      const savedCache = makeCachedWeather();
      mockCacheRepo.save.mockResolvedValue(savedCache);
      mockMapper.toWeatherResponseDTO.mockReturnValue(makeWeatherDTO());

      await service.getWeatherForLocation(LAT, LON);

      expect(mockDataSource.fetchWeatherData).toHaveBeenCalledTimes(1);
      expect(mockCacheRepo.save).toHaveBeenCalledTimes(1);
    });
  });

  // ── getForecast ─────────────────────────────────────────────────────────────

  describe('getForecast()', () => {
    it('debe devolver forecast del caché si existe', async () => {
      const cached = makeCachedWeather();
      mockCacheRepo.findByLocationKey.mockResolvedValue(cached);
      const forecastDTO = makeForecastDTO([{ rainProbability: 10 }]);
      mockMapper.toForecastResponseDTO.mockReturnValue(forecastDTO);

      const result = await service.getForecast(LAT, LON, 24);

      expect(result.hours).toHaveLength(1);
      expect(mockDataSource.fetchWeatherData).not.toHaveBeenCalled();
    });

    it('debe llamar a la API si no hay caché para el forecast', async () => {
      mockCacheRepo.findByLocationKey.mockResolvedValue(null);
      mockDataSource.fetchWeatherData.mockResolvedValue({});
      mockCacheRepo.save.mockResolvedValue(makeCachedWeather());
      mockMapper.toForecastResponseDTO.mockReturnValue(makeForecastDTO([]));

      await service.getForecast(LAT, LON, 12);

      expect(mockDataSource.fetchWeatherData).toHaveBeenCalledWith(LOC_KEY, 12);
    });
  });

  // ── shouldWater ─────────────────────────────────────────────────────────────

  describe('shouldWater()', () => {
    it('debe devolver false si se espera lluvia con probabilidad >= 60%', async () => {
      mockCacheRepo.findByLocationKey.mockResolvedValue(makeCachedWeather());
      mockMapper.toForecastResponseDTO.mockReturnValue(
        makeForecastDTO([{ rainProbability: 75 }, { rainProbability: 20 }]),
      );

      const result = await service.shouldWater(LAT, LON);
      expect(result).toBe(false);
    });

    it('debe devolver true si la probabilidad de lluvia es menor que el umbral', async () => {
      mockCacheRepo.findByLocationKey.mockResolvedValue(makeCachedWeather());
      mockMapper.toForecastResponseDTO.mockReturnValue(
        makeForecastDTO([{ rainProbability: 10 }, { rainProbability: 30 }]),
      );

      const result = await service.shouldWater(LAT, LON);
      expect(result).toBe(true);
    });

    it('debe devolver true si la API falla (regar por precaución)', async () => {
      mockCacheRepo.findByLocationKey.mockResolvedValue(null);
      mockDataSource.fetchWeatherData.mockRejectedValue(new Error('API error'));

      const result = await service.shouldWater(LAT, LON);
      expect(result).toBe(true);
    });
  });
});
