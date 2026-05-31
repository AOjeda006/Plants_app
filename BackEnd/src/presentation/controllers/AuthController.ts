/**
 * @file AuthController.ts
 * @description Controlador HTTP de autenticación.
 * Depende exclusivamente de interfaces de use cases, nunca de implementaciones concretas.
 * Valida los DTOs de entrada con class-validator antes de delegar al use case.
 * @module Auth
 * @layer Presentation
 *
 * @injectable
 * @dependencies IRegisterUserUseCase, ILoginUserUseCase, IValidateTokenUseCase, IRefreshTokenUseCase
 */

import { injectable, inject } from 'inversify';
import { Request, Response, NextFunction, Router, RequestHandler } from 'express';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import type { IRegisterUserUseCase } from '../../domain/interfaces/usecases/auth/IRegisterUserUseCase.js';
import type { ILoginUserUseCase } from '../../domain/interfaces/usecases/auth/ILoginUserUseCase.js';
import type { IValidateTokenUseCase } from '../../domain/interfaces/usecases/auth/IValidateTokenUseCase.js';
import type { IRefreshTokenUseCase } from '../../domain/interfaces/usecases/auth/IRefreshTokenUseCase.js';
import { RegisterRequestDTO } from '../../domain/dtos/auth/register-request.dto.js';
import { LoginRequestDTO } from '../../domain/dtos/auth/login-request.dto.js';
import type { AuthenticatedRequest } from '../../core/middleware/AuthMiddleware.js';
import { TYPES } from '../../core/types.js';
import { ValidationException, ValidationError } from '../../core/exceptions/ValidationException.js';
import { authLoginRegisterLimiter } from '../../core/middleware/RateLimitMiddleware.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('AuthController');

/**
 * Valida un DTO usando class-validator y lanza ValidationException si hay errores.
 *
 * @param DtoClass — Clase del DTO a instanciar.
 * @param body — Cuerpo de la petición.
 * @throws {ValidationException} Si hay campos inválidos.
 * @private
 */
async function validateDTO<T extends object>(
  DtoClass: new () => T,
  body: unknown,
): Promise<T> {
  const instance = plainToInstance(DtoClass, body);
  const errors = await validate(instance as object);

  if (errors.length > 0) {
    const validationErrors: ValidationError[] = errors.map(e => ({
      field: e.property,
      message: Object.values(e.constraints ?? {}).join(', '),
    }));
    throw new ValidationException(validationErrors);
  }

  return instance;
}

/**
 * Controlador de rutas de autenticación.
 * Registra las rutas en bootstrap() o en el módulo NestJS correspondiente.
 *
 * @injectable
 * @dependencies IRegisterUserUseCase, ILoginUserUseCase, IValidateTokenUseCase, IRefreshTokenUseCase
 */
@injectable()
export class AuthController {
  constructor(
    @inject(TYPES.IRegisterUserUseCase)  private readonly register: IRegisterUserUseCase,
    @inject(TYPES.ILoginUserUseCase)     private readonly login: ILoginUserUseCase,
    @inject(TYPES.IValidateTokenUseCase) private readonly validateToken: IValidateTokenUseCase,
    @inject(TYPES.IRefreshTokenUseCase)  private readonly refreshToken: IRefreshTokenUseCase,
  ) {}

  /**
   * Devuelve un Router de Express con todas las rutas de autenticación.
   * Usar en bootstrap(): `app.use('/auth', authController.router(requireAuth))`.
   *
   * @param requireAuth — Middleware de autenticación JWT (creado en bootstrap).
   *                      Necesario para proteger `POST /auth/refresh`. Si no se
   *                      pasa, esa ruta no se registra (modo defensivo).
   */
  router(requireAuth?: RequestHandler): Router {
    const router = Router();
    // Rate limiting específico de auth: mitigación contra fuerza bruta.
    // El límite global (laxo) está en SecurityMiddleware.
    router.post('/register',         authLoginRegisterLimiter, this.handleRegister.bind(this));
    router.post('/login',            authLoginRegisterLimiter, this.handleLogin.bind(this));
    router.get('/validate-token',    this.handleValidateToken.bind(this));
    // Refresh de token bajo demanda. Sin rate limit — el frontend la
    // invoca al arrancar la app si quedan <7d para expirar (caso normal y
    // frecuente para usuarios legítimos).
    if (requireAuth) {
      router.post('/refresh', requireAuth, this.handleRefresh.bind(this));
    }
    return router;
  }

  /**
   * POST /auth/register
   * Registra un nuevo usuario y devuelve token + datos públicos.
   *
   * @param req — Body: { name, email, password }
   * @param res — 201 con AuthResponseDTO
   */
  private async handleRegister(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const dto = await validateDTO(RegisterRequestDTO, req.body);
      const result = await this.register.execute(dto);
      logger.info(`Nuevo usuario registrado: ${result.user.email}`);
      res.status(201).json(result);
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /auth/login
   * Autentica al usuario y devuelve token + datos públicos.
   *
   * @param req — Body: { email, password }
   * @param res — 200 con AuthResponseDTO
   */
  private async handleLogin(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const dto = await validateDTO(LoginRequestDTO, req.body);
      const result = await this.login.execute(dto);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  /**
   * GET /auth/validate-token
   * Valida el token JWT del header Authorization y devuelve los datos del usuario.
   * El token se extrae del header Authorization: Bearer <token>.
   *
   * @param req — Header: Authorization: Bearer <token>
   * @param res — 200 con UserResponseDTO
   */
  private async handleValidateToken(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const authHeader = req.headers['authorization'] ?? '';
      const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : authHeader;
      const user = await this.validateToken.execute(token ?? '');
      res.status(200).json(user);
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /auth/refresh
   * Renueva el token JWT del usuario actual con expiración fresca (30d).
   * Requiere JWT válido — el AuthMiddleware ya rechaza tokens expirados con 401.
   *
   * @param req — req.user.userId tras AuthMiddleware (no requiere body).
   * @param res — 200 con AuthResponseDTO `{ token, user }`.
   * @throws {NotFoundException} 404 si el usuario fue soft-deleted entre la
   *         emisión del token actual y este refresh.
   */
  private async handleRefresh(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { userId } = (req as AuthenticatedRequest).user;
      const result = await this.refreshToken.execute(userId);
      logger.debug(`Token renovado para userId=${userId}`);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }
}
