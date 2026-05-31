/**
 * @file location_controller.spec.ts
 * @description Tests unitarios para LocationController.
 * Verifica el filtrado del catálogo estático de capitales de provincia:
 * query vacía devuelve todas, query parcial filtra por nombre, búsqueda
 * case-insensitive, y query sin coincidencias devuelve array vacío.
 * @module User
 * @layer Presentation
 */

import 'reflect-metadata';
import { LocationController } from './LocationController.js';
import { SPAIN_LOCATIONS }    from '../../data/static/spain-locations.js';

// ─── Helpers ──────────────────────────────────────────────────────────────────

/**
 * Simula una petición Express mínima con la query dada.
 */
function makeReq(q?: string): any {
  return { query: q !== undefined ? { q } : {} };
}

/**
 * Simula una respuesta Express que captura el JSON devuelto.
 */
function makeRes(): { json: jest.Mock; capturedData: any[] } {
  const capturedData: any[] = [];
  return {
    capturedData,
    json: jest.fn((data) => { capturedData.push(data); }),
  };
}

// ─── Suite ────────────────────────────────────────────────────────────────────

describe('LocationController — GET /locations/search', () => {
  let controller: LocationController;

  beforeEach(() => {
    controller = new LocationController();
  });

  it('devuelve las 52 capitales cuando q está ausente', () => {
    const req  = makeReq();
    const res  = makeRes();
    const next = jest.fn();

    // Acceso al método privado vía cast any para test unitario.
    (controller as any).handleSearch(req, res, next);

    expect(res.json).toHaveBeenCalledTimes(1);
    const results = res.capturedData[0] as any[];
    expect(results.length).toBe(SPAIN_LOCATIONS.length);
  });

  it('devuelve las 52 capitales cuando q es cadena vacía', () => {
    const req  = makeReq('');
    const res  = makeRes();
    const next = jest.fn();

    (controller as any).handleSearch(req, res, next);

    const results = res.capturedData[0] as any[];
    expect(results.length).toBe(SPAIN_LOCATIONS.length);
  });

  it('filtra por nombre parcial: q=Sev devuelve Sevilla', () => {
    const req  = makeReq('Sev');
    const res  = makeRes();
    const next = jest.fn();

    (controller as any).handleSearch(req, res, next);

    const results = res.capturedData[0] as any[];
    expect(results.length).toBeGreaterThan(0);
    expect(results.some((loc: any) => loc.name === 'Sevilla')).toBe(true);
  });

  it('la búsqueda es case-insensitive: q=sev también devuelve Sevilla', () => {
    const req  = makeReq('sev');
    const res  = makeRes();
    const next = jest.fn();

    (controller as any).handleSearch(req, res, next);

    const results = res.capturedData[0] as any[];
    expect(results.some((loc: any) => loc.name === 'Sevilla')).toBe(true);
  });

  it('devuelve array vacío si no hay coincidencias', () => {
    const req  = makeReq('ZZZinexistente');
    const res  = makeRes();
    const next = jest.fn();

    (controller as any).handleSearch(req, res, next);

    const results = res.capturedData[0] as any[];
    expect(results).toEqual([]);
  });

  it('cada resultado tiene los campos name, fullName, lat y lon', () => {
    const req  = makeReq('Madrid');
    const res  = makeRes();
    const next = jest.fn();

    (controller as any).handleSearch(req, res, next);

    const results = res.capturedData[0] as any[];
    expect(results.length).toBeGreaterThan(0);
    const madrid = results[0];
    expect(madrid).toHaveProperty('name');
    expect(madrid).toHaveProperty('fullName');
    expect(madrid).toHaveProperty('lat');
    expect(madrid).toHaveProperty('lon');
    expect(typeof madrid.lat).toBe('number');
    expect(typeof madrid.lon).toBe('number');
  });

  it('también filtra por fullName: q=España devuelve las 52 capitales (sufijo común en fullName)', () => {
    const req  = makeReq('España');
    const res  = makeRes();
    const next = jest.fn();

    (controller as any).handleSearch(req, res, next);

    const results = res.capturedData[0] as any[];
    // Todos los fullName tienen el sufijo ", España", así que q=España coincide con las 52.
    expect(results.length).toBe(SPAIN_LOCATIONS.length);
    expect(results.every((loc: any) =>
      (loc.fullName as string).toLowerCase().includes('españa')
    )).toBe(true);
  });
});
