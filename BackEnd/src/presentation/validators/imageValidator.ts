/**
 * @file imageValidator.ts
 * @description Validador de archivos de imagen para uploads.
 * Centraliza las reglas de validación de MIME type y tamaño para las rutas multipart.
 * @module Plants
 * @layer Presentation
 */

import { Request } from 'express';
import { HttpException } from '../../core/exceptions/HttpException.js';

/** Tipos MIME permitidos para imágenes */
const ALLOWED_MIME_TYPES = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
]);

/** Tamaño máximo en bytes (10 MB) */
const MAX_SIZE_BYTES = 10 * 1024 * 1024;

/**
 * Valida que la request contenga un archivo de imagen válido.
 * Se usa como función auxiliar en los controllers que aceptan uploads.
 *
 * @param req — Request de Express con archivo adjunto (req.file de multer).
 * @throws {HttpException} 400 si no hay archivo.
 * @throws {HttpException} 400 si el tipo MIME no está permitido.
 * @throws {HttpException} 400 si el tamaño supera el límite.
 */
export function validateImageUpload(req: Request): void {
  const file = req.file;

  if (!file) {
    throw new HttpException('No se adjuntó ningún archivo de imagen', 400, 'NO_IMAGE_PROVIDED');
  }

  if (!ALLOWED_MIME_TYPES.has(file.mimetype)) {
    throw new HttpException(
      `Tipo de archivo no permitido: ${file.mimetype}. Permitidos: ${[...ALLOWED_MIME_TYPES].join(', ')}`,
      400,
      'INVALID_IMAGE_TYPE',
    );
  }

  if (file.size > MAX_SIZE_BYTES) {
    const maxMb = MAX_SIZE_BYTES / (1024 * 1024);
    throw new HttpException(
      `El archivo supera el tamaño máximo de ${maxMb} MB`,
      400,
      'IMAGE_TOO_LARGE',
    );
  }
}
