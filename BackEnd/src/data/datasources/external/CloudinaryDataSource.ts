/**
 * @file CloudinaryDataSource.ts
 * @description Datasource externo para gestión de imágenes en Cloudinary.
 * Encapsula la lógica de upload, delete y validación de mime/size.
 * @module Plants
 * @layer Data
 *
 * @injectable
 * @dependencies cloudinaryConfig
 */

import { injectable } from 'inversify';
import { v2 as cloudinary, UploadApiResponse } from 'cloudinary';
import { cloudinaryConfig } from '../../../core/config/cloudinary.config.js';
import { createLogger } from '../../../core/logger.js';
import { HttpException } from '../../../core/exceptions/HttpException.js';
import { ExternalServiceException } from '../../../core/exceptions/ExternalServiceException.js';

const logger = createLogger('CloudinaryDataSource');

/** Tipos MIME permitidos para imágenes */
const ALLOWED_MIME_TYPES = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
]);

/** Tamaño máximo de imagen en bytes (10 MB) */
const MAX_IMAGE_SIZE_BYTES = 10 * 1024 * 1024;

/**
 * Resultado de la subida de una imagen a Cloudinary.
 */
export interface UploadResult {
  /** URL pública de la imagen */
  url: string;
  /** Public ID en Cloudinary (necesario para borrar) */
  publicId: string;
  /** Formato de la imagen (jpeg, png, etc.) */
  format: string;
  /** Ancho en píxeles */
  width: number;
  /** Alto en píxeles */
  height: number;
}

/**
 * Datasource de Cloudinary para gestión de imágenes.
 * Inicializa el cliente de Cloudinary con las credenciales del config.
 *
 * @injectable
 */
@injectable()
export class CloudinaryDataSource {
  constructor() {
    cloudinary.config({
      cloud_name: cloudinaryConfig.CLOUDINARY_CLOUD_NAME,
      api_key:    cloudinaryConfig.CLOUDINARY_API_KEY,
      api_secret: cloudinaryConfig.CLOUDINARY_API_SECRET,
    });

    logger.info(`Cloudinary configurado: cloud=${cloudinaryConfig.CLOUDINARY_CLOUD_NAME}`);
  }

  /**
   * Sube una imagen a Cloudinary desde un buffer.
   * Valida el tipo MIME y el tamaño antes de subir.
   *
   * @param buffer — Buffer con los bytes de la imagen.
   * @param mimeType — Tipo MIME de la imagen (ej: 'image/jpeg').
   * @param folder — Subcarpeta dentro del upload folder (ej: 'plants', 'posts').
   * @returns Resultado de la subida con URL y publicId.
   * @throws {AppError} Si el tipo MIME no está permitido.
   * @throws {AppError} Si el tamaño supera el límite.
   * @throws {AppError} Si Cloudinary devuelve un error.
   */
  async uploadImage(
    buffer: Buffer,
    mimeType: string,
    folder: string = 'general',
  ): Promise<UploadResult> {
    this._validateMimeType(mimeType);
    this._validateSize(buffer.length);

    const uploadFolder = `${cloudinaryConfig.UPLOAD_FOLDER}/${folder}`;

    const result = await new Promise<UploadApiResponse>((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        {
          folder:          uploadFolder,
          resource_type:   'image',
          allowed_formats: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
        },
        (error, result) => {
          if (error || !result) {
            reject(new ExternalServiceException(
              'Cloudinary',
              error?.message ?? 'Unknown error',
            ));
          } else {
            resolve(result);
          }
        },
      );
      uploadStream.end(buffer);
    });

    logger.debug(`Imagen subida: ${result.public_id}`);

    return {
      url:      result.secure_url,
      publicId: result.public_id,
      format:   result.format,
      width:    result.width,
      height:   result.height,
    };
  }

  /**
   * Elimina una imagen de Cloudinary por su publicId.
   *
   * @param publicId — Public ID de la imagen en Cloudinary.
   * @throws {AppError} Si Cloudinary devuelve un error al eliminar.
   */
  async deleteImage(publicId: string): Promise<void> {
    const result = await cloudinary.uploader.destroy(publicId, { resource_type: 'image' });

    if (result.result !== 'ok' && result.result !== 'not found') {
      throw new ExternalServiceException('Cloudinary', `delete result: ${result.result}`);
    }

    logger.debug(`Imagen eliminada: ${publicId}`);
  }

  /**
   * Valida que el tipo MIME sea uno de los permitidos.
   *
   * @param mimeType — Tipo MIME a validar.
   * @throws {AppError} Si el tipo MIME no está permitido.
   * @private
   */
  private _validateMimeType(mimeType: string): void {
    if (!ALLOWED_MIME_TYPES.has(mimeType)) {
      throw new HttpException(
        `Tipo de imagen no permitido: ${mimeType}. Permitidos: ${[...ALLOWED_MIME_TYPES].join(', ')}`,
        400,
        'INVALID_IMAGE_TYPE',
      );
    }
  }

  /**
   * Valida que el tamaño del buffer no supere el límite máximo.
   *
   * @param sizeBytes — Tamaño en bytes.
   * @throws {AppError} Si el tamaño supera MAX_IMAGE_SIZE_BYTES.
   * @private
   */
  private _validateSize(sizeBytes: number): void {
    if (sizeBytes > MAX_IMAGE_SIZE_BYTES) {
      const maxMb = MAX_IMAGE_SIZE_BYTES / (1024 * 1024);
      throw new HttpException(
        `La imagen supera el tamaño máximo permitido de ${maxMb} MB`,
        400,
        'IMAGE_TOO_LARGE',
      );
    }
  }
}
