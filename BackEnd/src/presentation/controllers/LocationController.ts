/**
 * @file LocationController.ts
 * @description Controlador HTTP para el catálogo de ubicaciones.
 * Expone las 52 capitales de provincia de España para el selector de perfil.
 * No requiere base de datos — los datos son estáticos en tiempo de compilación.
 * @module User
 * @layer Presentation
 *
 * @injectable
 * @dependencies ninguna
 */

import { injectable } from 'inversify';
import { Request, Response, NextFunction, Router } from 'express';
import { SPAIN_LOCATIONS } from '../../data/static/spain-locations.js';

/**
 * Controlador de rutas del catálogo de ubicaciones.
 *
 * @injectable
 */
@injectable()
export class LocationController {

  /**
   * Devuelve un Router de Express con todas las rutas de ubicaciones.
   */
  router(): Router {
    const router = Router();
    router.get('/search', this.handleSearch.bind(this));
    return router;
  }

  /**
   * GET /locations/search?q=...
   * Filtra las capitales de provincia por nombre (case-insensitive, parcial).
   * Si q está vacío o ausente, devuelve todas.
   *
   * @param req — Request con query param q (opcional).
   * @param res — Response con array de SpainLocation.
   * @param next — Manejador de errores.
   */
  private handleSearch(req: Request, res: Response, next: NextFunction): void {
    try {
      const query = ((req.query['q'] as string) ?? '').trim().toLowerCase();

      const results = query.length === 0
        ? SPAIN_LOCATIONS
        : SPAIN_LOCATIONS.filter(
            (loc) => loc.name.toLowerCase().includes(query)
                  || loc.fullName.toLowerCase().includes(query),
          );

      res.json(results);
    } catch (error) {
      next(error);
    }
  }
}
