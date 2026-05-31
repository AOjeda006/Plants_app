/// @file location.dart
/// @description Entidad de dominio que representa una capital de provincia española.
/// Usada en el selector de ubicación del perfil de usuario.
/// @module User
/// @layer Domain
library;

// ═══════════════════════════════════════════════════════════════════════════════
// LOCATION ENTITY
// ═══════════════════════════════════════════════════════════════════════════════

/// Capital de provincia española para el catálogo de ubicaciones.
///
/// Todos los campos son inmutables (final).
class Location {
  const Location({
    required this.name,
    required this.fullName,
    required this.lat,
    required this.lon,
  });

  /// Nombre corto de la ciudad (ej. "Sevilla").
  final String name;

  /// Nombre completo para mostrar y guardar en el perfil (ej. "Sevilla, España").
  final String fullName;

  /// Latitud geográfica.
  final double lat;

  /// Longitud geográfica.
  final double lon;

  /// Construye una Location desde un mapa JSON devuelto por GET /locations/search.
  factory Location.fromJson(Map<String, dynamic> json) => Location(
    name:     json['name']     as String,
    fullName: json['fullName'] as String,
    lat:      (json['lat']     as num).toDouble(),
    lon:      (json['lon']     as num).toDouble(),
  );

  @override
  String toString() => fullName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Location && other.fullName == fullName);

  @override
  int get hashCode => fullName.hashCode;
}
