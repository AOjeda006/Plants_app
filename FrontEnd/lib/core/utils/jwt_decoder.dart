/// @file jwt_decoder.dart
/// @description Helper para decodificar el payload de un JWT (sin verificar firma).
/// La verificación criptográfica corresponde al backend; el frontend solo
/// necesita leer el campo `exp` para decidir si renovar el token.
/// @module Core
/// @layer Core
library;

import 'dart:convert';

// ═══════════════════════════════════════════════════════════════════════════════
// JWT DECODER
// ═══════════════════════════════════════════════════════════════════════════════

/// Decodifica el payload (segunda parte) de un JWT codificado en base64url.
///
/// Devuelve `null` si el token no tiene tres segmentos, si el segmento
/// del payload no es base64url válido, o si el JSON decodificado no es un
/// `Map<String, dynamic>`. Nunca lanza — los errores se traducen a `null`
/// para simplificar el sitio de llamada.
///
/// Importante: NO verifica la firma. Es solo lectura del payload. El backend
/// es la única fuente de verdad sobre la validez del token.
Map<String, dynamic>? decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    final normalized = base64Url.normalize(parts[1]);
    final jsonStr    = utf8.decode(base64Url.decode(normalized));
    final decoded    = jsonDecode(jsonStr);
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}

/// Devuelve los días restantes hasta la expiración del token, o `null` si
/// el campo `exp` no está presente o el token no se puede decodificar.
///
/// El campo `exp` en JWT es Unix timestamp en SEGUNDOS (no ms).
double? jwtDaysUntilExpiry(String token, {DateTime? now}) {
  final payload = decodeJwtPayload(token);
  final exp = payload?['exp'];
  if (exp is! int) return null;
  final current = now ?? DateTime.now();
  final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
  return expDate.difference(current.toUtc()).inSeconds / (24 * 60 * 60);
}
