/**
 * @file SpeciesController.ts
 * @description Controlador HTTP de especies de plantas.
 * Solo búsqueda pública del catálogo (14 especies del seed). El catálogo
 * de especies se gestiona vía `npm run seed:species` (script idempotente);
 * no hay endpoints de creación o aprobación por parte de los usuarios.
 *
 * @module Plants
 * @layer Presentation
 *
 * @injectable
 * @dependencies ISearchSpeciesUseCase
 */

import { injectable, inject } from 'inversify';
import { Request, Response, NextFunction, Router } from 'express';
import type { ISearchSpeciesUseCase } from '../../domain/interfaces/usecases/plants/ISearchSpeciesUseCase.js';
import { TYPES } from '../../core/types.js';

/**
 * Controlador de rutas de especies.
 *
 * @injectable
 * @dependencies ISearchSpeciesUseCase
 */
@injectable()
export class SpeciesController {
  constructor(
    @inject(TYPES.ISearchSpeciesUseCase) private readonly searchSpecies: ISearchSpeciesUseCase,
  ) {}

  /**
   * Devuelve un Router de Express con la única ruta pública de especies.
   */
  router(): Router {
    const router = Router();
    router.get('/search', this.handleSearch.bind(this));
    return router;
  }

  /**
   * GET /species/search?q=texto — Busca especies públicas por nombre.
   * Query vacío → devuelve todas las públicas (necesario para que el
   * autocompletado del frontend muestre el listado al abrirse).
   *
   * @param req — Request con query param q.
   * @param res — Response con array de PlantSpeciesResponseDTO.
   * @param next — Manejador de errores.
   */
  private async handleSearch(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const query = String(req.query.q ?? '').trim();
      const results = await this.searchSpecies.execute(query);
      res.json(results);
    } catch (error) {
      next(error);
    }
  }
}
