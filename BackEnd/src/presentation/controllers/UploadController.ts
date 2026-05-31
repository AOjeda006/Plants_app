/**
 * @file UploadController.ts
 * @description Controlador HTTP para subida de imágenes a Cloudinary.
 * Recibe un archivo multipart/form-data, valida y sube a Cloudinary.
 * El cliente obtiene la URL y la usa en las peticiones de creación/actualización de recursos.
 * @module Plants
 * @layer Presentation
 *
 * @injectable
 * @dependencies CloudinaryDataSource
 */

import { injectable, inject } from 'inversify';
import { Request, Response, NextFunction, Router } from 'express';
import multer from 'multer';
import { TYPES } from '../../core/types.js';
import { CloudinaryDataSource } from '../../data/datasources/external/CloudinaryDataSource.js';
import { validateImageUpload } from '../validators/imageValidator.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('UploadController');

/** Multer configurado con almacenamiento en memoria (buffer) */
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB
});

/**
 * Controlador de subida de imágenes.
 *
 * @injectable
 * @dependencies CloudinaryDataSource
 */
@injectable()
export class UploadController {
  constructor(
    @inject(TYPES.CloudinaryDataSource) private readonly cloudinary: CloudinaryDataSource,
  ) {}

  /**
   * Devuelve un Router de Express con la ruta de upload.
   */
  router(): Router {
    const router = Router();
    // Multer procesa el campo 'image' del formulario multipart
    router.post('/image', upload.single('image'), this.handleUpload.bind(this));
    return router;
  }

  /**
   * POST /upload/image — Sube una imagen a Cloudinary.
   *
   * @param req — Request con req.file (campo 'image' del multipart/form-data).
   *              Incluye req.query.folder para la subcarpeta en Cloudinary (opcional).
   * @param res — Response con { url, publicId, width, height, format }.
   * @param next — Manejador de errores.
   */
  private async handleUpload(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      validateImageUpload(req);

      const file   = req.file!;
      const folder = String(req.query.folder ?? 'general');

      const result = await this.cloudinary.uploadImage(file.buffer, file.mimetype, folder);

      logger.debug(`Imagen subida por usuario: ${result.publicId}`);

      res.status(201).json({
        url:      result.url,
        publicId: result.publicId,
        width:    result.width,
        height:   result.height,
        format:   result.format,
      });
    } catch (error) {
      next(error);
    }
  }
}
