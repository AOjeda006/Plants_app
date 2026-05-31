/// @file post_repository_impl.dart
/// @description Implementación del repositorio de posts y comentarios de la comunidad.
/// Coordina PostRemoteDataSource (API) y CacheLocalDataSource (caché con TTL).
/// Los errores de red propagan al ViewModel/UI — no se encolan acciones offline.
/// @module Community
/// @layer Data
library;

import '../../core/storage/cache_local_data_source.dart';
import '../../domain/dtos/community/create_post_request_dto.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/i_post_repository.dart';
import '../datasources/remote/post_remote_data_source.dart';
import '../i_mappers/i_comment_mapper.dart';
import '../i_mappers/i_post_mapper.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';

// ─── Constantes de caché ──────────────────────────────────────────────────────

const String   _kFeedPage1Key = 'community_feed_p1';
const Duration _kFeedTtl      = Duration(minutes: 3);
String _kPostKey(String id) => 'community_post_$id';
const Duration _kPostTtl    = Duration(minutes: 5);

// ═══════════════════════════════════════════════════════════════════════════════
// POST REPOSITORY IMPL
// ═══════════════════════════════════════════════════════════════════════════════

/// Implementación concreta de [IPostRepository].
///
/// Estrategia de caché:
///  - Feed (página 1): cache-first con TTL corto (3 min) para mostrar contenido rápido.
///  - Post individual: cache-first con TTL más largo (5 min).
///  - Comentarios: sin caché — se esperan frescos al abrir el detalle.
///  - Mutaciones (POST/DELETE): API → invalida caché afectada.
///
/// [implements] IPostRepository
/// [injectable] registrar en container.dart.
/// [dependencies] PostRemoteDataSource, CacheLocalDataSource,
///               IPostMapper, ICommentMapper.
class PostRepositoryImpl implements IPostRepository {
  final PostRemoteDataSource _remote;
  final CacheLocalDataSource _cache;
  final IPostMapper          _postMapper;
  final ICommentMapper       _commentMapper;

  const PostRepositoryImpl({
    required PostRemoteDataSource remote,
    required CacheLocalDataSource cache,
    required IPostMapper          postMapper,
    required ICommentMapper       commentMapper,
  })  : _remote        = remote,
        _cache         = cache,
        _postMapper    = postMapper,
        _commentMapper = commentMapper;

  // ─── Get feed ─────────────────────────────────────────────────────────────────

  @override
  Future<List<Post>> getFeed({int page = 1, int limit = 20, String? authorId}) async {
    final isFiltered = authorId != null && authorId.isNotEmpty;

    // Solo cachear el feed de comunidad sin filtro (página 1). Los feeds
    // por autor (propio u otro) se obtienen siempre frescos del servidor.
    if (!isFiltered && page == 1) {
      final cached = await _cache.get<List<dynamic>>(_kFeedPage1Key);
      if (cached != null) {
        return cached
            .cast<Map<String, dynamic>>()
            .map((json) => _postMapper.toEntity(PostModel.fromJson(json)))
            .toList();
      }
    }

    final rawList = await _remote.getFeed(
      page:     page,
      limit:    limit,
      authorId: authorId,
    );

    if (!isFiltered && page == 1) {
      await _cache.set(_kFeedPage1Key, rawList, ttl: _kFeedTtl);
    }

    return rawList
        .map((json) => _postMapper.toEntity(PostModel.fromJson(json)))
        .toList();
  }

  // ─── Get post by ID ───────────────────────────────────────────────────────────

  @override
  Future<Post> getPostById(String postId) async {
    final key    = _kPostKey(postId);
    final cached = await _cache.get<Map<String, dynamic>>(key);
    if (cached != null) {
      return _postMapper.toEntity(PostModel.fromJson(cached));
    }

    final raw = await _remote.getPostById(postId);
    await _cache.set(key, raw, ttl: _kPostTtl);
    return _postMapper.toEntity(PostModel.fromJson(raw));
  }

  // ─── Create post ──────────────────────────────────────────────────────────────

  @override
  Future<Post> createPost(CreatePostRequestDto dto) async {
    // Los errores de red propagan al ViewModel/UI.
    final raw = await _remote.createPost(dto.toJson());
    // Invalidar feed para que el nuevo post aparezca al refrescar.
    await _cache.invalidate(_kFeedPage1Key);
    return _postMapper.toEntity(PostModel.fromJson(raw));
  }

  // ─── Like / Unlike ────────────────────────────────────────────────────────────

  @override
  Future<void> likePost(String postId) async {
    await _remote.likePost(postId);
    // Invalidar caché del post y del feed para reflejar el nuevo likesCount.
    await Future.wait([
      _cache.invalidate(_kPostKey(postId)),
      _cache.invalidate(_kFeedPage1Key),
    ]);
  }

  @override
  Future<void> unlikePost(String postId) async {
    await _remote.unlikePost(postId);
    await Future.wait([
      _cache.invalidate(_kPostKey(postId)),
      _cache.invalidate(_kFeedPage1Key),
    ]);
  }

  // ─── Comments ─────────────────────────────────────────────────────────────────

  @override
  Future<List<Comment>> getComments(String postId) async {
    // Los comentarios no se cachean: se esperan frescos al abrir el detalle del post.
    final rawList = await _remote.getComments(postId);
    return rawList
        .map((json) => _commentMapper.toEntity(CommentModel.fromJson(json)))
        .toList();
  }

  @override
  Future<Comment> createComment(String postId, String content) async {
    final raw = await _remote.createComment(postId, content);
    // Invalidar caché del post y del feed para reflejar el nuevo commentsCount.
    await Future.wait([
      _cache.invalidate(_kPostKey(postId)),
      _cache.invalidate(_kFeedPage1Key),
    ]);
    return _commentMapper.toEntity(CommentModel.fromJson(raw));
  }
}
