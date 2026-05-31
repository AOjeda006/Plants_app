/// @file api_client.dart
/// @description Wrapper sobre Dio que expone get/post/put/delete/patch/uploadImage.
/// Centraliza la configuración de Dio (timeouts, base URL, interceptores) y mapea
/// todos los DioException a AppError para que los repositorios solo manejen AppError.
/// @module Core
/// @layer Core
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../config/app_config.dart';
import '../errors/app_error.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// TIMEOUTS
// ═══════════════════════════════════════════════════════════════════════════════

// Timeouts agresivos pero suficientes para absorber el cold start de
// Render Free Tier (~40-60 s tras 15 min de inactividad). Rangos:
//  - connectTimeout 60 s — handshake TCP/TLS durante spin-up.
//  - receiveTimeout 60 s — primera respuesta del backend recién despierto.
//  - sendTimeout    30 s — uploads (imágenes); peticiones JSON normales
//                          terminan en milisegundos.
// Los timeouts NUNCA deben categorizarse como `unauthorized`; siempre
// son `AppError.network()` (ver `_mapDioError`). De ese modo
// AuthViewModel.checkSession() los tolera y mantiene la sesión.
const Duration _kConnectTimeout = Duration(seconds: 60);
const Duration _kReceiveTimeout = Duration(seconds: 60);
const Duration _kSendTimeout    = Duration(seconds: 30);

/// Timeout corto pensado para llamadas de "optimización" cuyo fallo no
/// debe bloquear el flujo — p.ej. /auth/refresh: si tarda demasiado,
/// abandonamos y mantenemos el token actual (sigue siendo válido).
/// Se aplica desde el call site con `Options(receiveTimeout: ...)`.
const Duration kShortReceiveTimeout = Duration(seconds: 30);

// ═══════════════════════════════════════════════════════════════════════════════
// API CLIENT
// ═══════════════════════════════════════════════════════════════════════════════

/// Cliente HTTP centralizado para toda la app.
///
/// Configuración de Dio:
///  - Base URL desde [AppConfig.apiBaseUrl].
///  - Interceptores: Auth → Retry → Logging (en ese orden).
///  - Content-Type JSON por defecto; multipart/form-data para uploads.
///
/// Todos los métodos lanzan [AppError] en caso de fallo, nunca [DioException].
///
/// [injectable] registrar en container.dart como singleton.
/// [dependencies] tokenProvider: inyectado desde AuthLocalDataSource.
class ApiClient {
  late final Dio _dio;

  /// [tokenProvider] función que devuelve el access token actual (puede ser null).
  /// Se inyecta desde el DI container para no acoplar ApiClient a SecureStorage.
  ApiClient({required Future<String?> Function() tokenProvider}) {
    _dio = Dio(
      BaseOptions(
        baseUrl:        AppConfig.instance.apiBaseUrl,
        connectTimeout: _kConnectTimeout,
        receiveTimeout: _kReceiveTimeout,
        sendTimeout:    _kSendTimeout,
        headers: const {'Content-Type': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // Orden de interceptores: Auth primero (añade token), luego Retry, luego Log.
    _dio.interceptors.addAll([
      AuthInterceptor(tokenProvider: tokenProvider),
      RetryInterceptor(),
      LoggingInterceptor(),
    ]);
  }

  // ─── Métodos HTTP ────────────────────────────────────────────────────────────

  /// GET genérico. Devuelve el [data] de la respuesta o lanza [AppError].
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _safeRequest<T>(
      () => _dio.get<T>(path, queryParameters: queryParameters, options: options),
    );
    return response;
  }

  /// POST genérico.
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _safeRequest<T>(
      () => _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options),
    );
  }

  /// PUT genérico.
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _safeRequest<T>(
      () => _dio.put<T>(path, data: data, queryParameters: queryParameters, options: options),
    );
  }

  /// PATCH genérico.
  Future<T> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _safeRequest<T>(
      () => _dio.patch<T>(path, data: data, queryParameters: queryParameters, options: options),
    );
  }

  /// DELETE genérico.
  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _safeRequest<T>(
      () => _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options),
    );
  }

  /// Subida de imagen a través de multipart/form-data.
  ///
  /// [path]      endpoint del backend (ej. /users/me/photo).
  /// [bytes]     bytes del archivo a subir (compatible con web y móvil).
  /// [filename]  nombre del archivo que se enviará al servidor.
  /// [fieldName] nombre del campo form — debe coincidir con `upload.single(fieldName)`
  ///             del backend. El backend espera 'image' (UploadController multer).
  /// [onProgress] callback opcional con progreso [0.0, 1.0].
  Future<T> uploadImage<T>(
    String path,
    Uint8List bytes,
    String filename, {
    String fieldName = 'image',
    void Function(double progress)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      fieldName: MultipartFile.fromBytes(
        bytes,
        filename:    filename,
        // Especificar contentType explícito para evitar application/octet-stream
        // que el backend rechaza en el validador de imágenes.
        contentType: _mediaTypeFromFilename(filename),
      ),
    });

    return _safeRequest<T>(
      () => _dio.post<T>(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: onProgress != null
            ? (sent, total) {
                if (total > 0) onProgress(sent / total);
              }
            : null,
      ),
    );
  }

  // ─── Error mapping ───────────────────────────────────────────────────────────

  /// Ejecuta [request] y mapea cualquier excepción a [AppError].
  Future<T> _safeRequest<T>(Future<Response<T>> Function() request) async {
    try {
      final response = await request();
      _assertSuccess(response);
      return response.data as T;
    } on AppError {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw AppError.unknown(e.toString());
    }
  }

  /// Lanza [AppError] si el status code indica un error del cliente (4xx).
  ///
  /// Los 5xx no llegan aquí porque [validateStatus] los deja pasar y Retry los
  /// reintenta; si agotan reintentos, llegan como DioException.
  void _assertSuccess(Response<dynamic> response) {
    final status = response.statusCode ?? 0;

    if (status >= 200 && status < 300) return;

    final body    = response.data;
    final message = body is Map ? (body['message'] as String?) : null;
    final details = body is Map ? body['details'] : null;

    throw switch (status) {
      401 => AppError.unauthorized(message ?? 'Unauthorized'),
      403 => AppError(
               code:       ErrorCode.server,
               message:    message ?? 'Forbidden',
               statusCode: 403,
             ),
      404 => AppError.notFound(message ?? 'Resource not found'),
      409 => AppError(
               code:       ErrorCode.server,
               message:    message ?? 'Conflict',
               statusCode: 409,
             ),
      422 => AppError.validation(message ?? 'Validation failed', details: details),
      400 => AppError.validation(message ?? 'Bad request',       details: details),
      429 => AppError(
               code:       ErrorCode.server,
               message:    message ?? 'Too many requests. Try again later.',
               statusCode: 429,
             ),
      _   => AppError(
               code:       ErrorCode.server,
               message:    message ?? 'Unexpected error ($status)',
               statusCode: status,
             ),
    };
  }

  /// Convierte un [DioException] en el [AppError] más específico posible.
  ///
  /// Reglas de categorización:
  ///  - Cualquier timeout (`connectionTimeout`, `receiveTimeout`,
  ///    `sendTimeout`) o fallo de transporte (`connectionError`) →
  ///    `AppError.network()`. NUNCA `unauthorized`, aunque la petición
  ///    sea contra `/auth/...`. Esto permite que
  ///    `AuthViewModel.checkSession()` distinga "el servidor no
  ///    responde" (mantener sesión) de "el servidor dice que el token
  ///    no vale" (cerrar sesión).
  ///  - `badResponse` se delega en `_assertSuccess` para mapear por
  ///    HTTP status: 401 → `unauthorized`, 404 → `notFound`, 422/400 →
  ///    `validation`, 429 → server con statusCode 429 (rate limit), etc.
  ///  - Cualquier otro tipo no clasificado → `AppError.unknown()`.
  AppError _mapDioError(DioException e) {
    // Si el error ya fue envuelto como AppError por un interceptor.
    if (e.error is AppError) return e.error as AppError;

    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout    ||
      DioExceptionType.sendTimeout       => AppError.network('Connection timeout. Check your connection.'),
      DioExceptionType.connectionError   => AppError.network('No internet connection.'),
      DioExceptionType.cancel            => AppError.network('Request cancelled.'),
      DioExceptionType.badResponse       => _assertSuccessOrThrow(e),
      _                                  => AppError.unknown(e.message ?? 'Unexpected network error'),
    };
  }

  AppError _assertSuccessOrThrow(DioException e) {
    try {
      _assertSuccess(e.response!);
      return AppError.unknown('Unknown response error');
    } on AppError catch (appErr) {
      return appErr;
    }
  }

  /// Deriva el [MediaType] correcto a partir de la extensión del nombre de archivo.
  /// Evita que el navegador envíe application/octet-stream en uploads desde web.
  MediaType _mediaTypeFromFilename(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
      'png'           => MediaType('image', 'png'),
      'gif'           => MediaType('image', 'gif'),
      'webp'          => MediaType('image', 'webp'),
      _               => MediaType('image', 'jpeg'),
    };
  }
}
