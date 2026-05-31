/**
 * @file weather_api_data_source.spec.ts
 * @description Tests del datasource de WeatherAPI.com. Verifica que las
 * llamadas HTTP incluyen `lang=es` para que `condition.text` llegue ya
 * traducido al español y no aparezca en inglés en las notificaciones del
 * cron.
 * @module Weather
 * @layer Data
 */

import axios from 'axios';
import { WeatherAPIDataSource } from './WeatherAPIDataSource.js';
import { weatherConfig } from '../../../core/config/weather.config.js';

jest.mock('axios');
const axiosMock = axios as jest.Mocked<typeof axios>;

describe('WeatherAPIDataSource', () => {
  const ORIG_MOCK_MODE = weatherConfig.MOCK_WEATHER_MODE;
  let datasource: WeatherAPIDataSource;

  beforeAll(() => {
    // Desactivar mock mode para que se ejecute la rama HTTP real.
    (weatherConfig as { MOCK_WEATHER_MODE: boolean }).MOCK_WEATHER_MODE = false;
  });

  afterAll(() => {
    (weatherConfig as { MOCK_WEATHER_MODE: boolean }).MOCK_WEATHER_MODE = ORIG_MOCK_MODE;
  });

  beforeEach(() => {
    datasource = new WeatherAPIDataSource();
    axiosMock.get.mockReset();
  });

  describe('fetchWeatherData → forecast.json', () => {
    it('incluye lang=es en los query params', async () => {
      axiosMock.get.mockResolvedValueOnce({
        data: {
          current: {
            temp_c: 20, feelslike_c: 20, humidity: 50, wind_kph: 5,
            precip_mm: 0, condition: { text: 'Despejado', icon: '//x.png' },
          },
          forecast: { forecastday: [{ hour: [] }] },
        },
      });

      await datasource.fetchWeatherData('40.4168,-3.7038', 24);

      expect(axiosMock.get).toHaveBeenCalledTimes(1);
      const [, options] = axiosMock.get.mock.calls[0]!;
      expect(options).toBeDefined();
      const params = options!['params'] as Record<string, unknown>;
      expect(params['lang']).toBe('es');
      expect(params['q']).toBe('40.4168,-3.7038');
      expect(params['aqi']).toBe('no');
    });

    it('devuelve condition.text traducido (asumiendo backend con lang=es)', async () => {
      axiosMock.get.mockResolvedValueOnce({
        data: {
          current: {
            temp_c: 18, feelslike_c: 17, humidity: 70, wind_kph: 10,
            precip_mm: 0, condition: { text: 'Parcialmente nublado', icon: '//x.png' },
          },
          forecast: {
            forecastday: [{
              hour: [{
                time: '2026-05-12 10:00', temp_c: 18, humidity: 70,
                chance_of_rain: 10, will_it_rain: 0,
                condition: { text: 'Parcialmente nublado' },
              }],
            }],
          },
        },
      });

      const result = await datasource.fetchWeatherData('40.4168,-3.7038', 1);
      expect(result.current.condition).toBe('Parcialmente nublado');
      expect(result.forecast[0]!.condition).toBe('Parcialmente nublado');
    });
  });

  describe('fetchYesterdayRainfall → history.json', () => {
    it('incluye lang=es en los query params del histórico', async () => {
      axiosMock.get.mockResolvedValueOnce({
        data: {
          forecast: { forecastday: [{ day: { totalprecip_mm: 3.5 } }] },
        },
      });

      const mm = await datasource.fetchYesterdayRainfall('40.4168,-3.7038');

      expect(mm).toBe(3.5);
      expect(axiosMock.get).toHaveBeenCalledTimes(1);
      const [, options] = axiosMock.get.mock.calls[0]!;
      const params = options!['params'] as Record<string, unknown>;
      expect(params['lang']).toBe('es');
      expect(params['q']).toBe('40.4168,-3.7038');
      expect(typeof params['dt']).toBe('string');
    });
  });

  describe('keyForLocation', () => {
    it('normaliza lat/lon a 4 decimales', () => {
      expect(datasource.keyForLocation(40.41678901, -3.70379456)).toBe('40.4168,-3.7038');
    });
  });
});
