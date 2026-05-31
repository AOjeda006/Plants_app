/// @file create_post_request_dto.dart
/// @description DTO de creación de post en la comunidad.
/// El campo imageUrl es la URL de Cloudinary obtenida tras subir la imagen
/// previamente con POST /upload/image.
/// @module Community
/// @layer Domain
library;

/// DTO con los datos necesarios para crear un nuevo post.
class CreatePostRequestDto {
  const CreatePostRequestDto({
    required this.content,
    this.imageUrl,
    this.plantId,
  });

  /// Texto del post (máx. 1000 caracteres).
  final String content;

  /// URL de imagen en Cloudinary, ya subida previamente via /upload/image.
  final String? imageUrl;

  /// ID de la planta asociada al post (opcional).
  final String? plantId;

  /// Serializa el DTO a JSON para enviarlo al backend.
  Map<String, dynamic> toJson() => {
    'content': content,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (plantId  != null) 'plantId':  plantId,
  };
}
