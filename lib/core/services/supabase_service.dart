// supabase_service.dart (agregando getRepliesStream sin modificar lo demás)

import 'dart:io';
import 'package:prueba_apkturismo_sbfr/core/models/user_profile.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String role,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username, 'full_name': username, 'role': role},
    );
  }

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<UserProfile?> getProfile() async {
    if (currentUser == null) return null;
    return await getProfileById(currentUser!.id);
  }

  Future<UserProfile?> getProfileById(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('username, avatar_url, role')
          .eq('id', userId)
          .single();
      return UserProfile.fromMap({'id': userId, ...response});
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getSites() async {
    return await _client
        .from('sites')
        .select('*, profiles (username), photos (image_url)')
        .order('created_at', ascending: false);
  }

  Future<Map<String, dynamic>> getSiteDetails(int siteId) async {
    return await _client
        .from('sites')
        .select('*, profiles (username), photos (id, image_url)')
        .eq('id', siteId)
        .single();
  }

  Future<void> deleteReview(int reviewId) async {
    await _client.from('reviews').delete().eq('id', reviewId);
  }

  Future<void> deleteReply(int replyId) async {
    await _client.from('replies').delete().eq('id', replyId);
  }

  Future<void> publishNewSite({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required List<XFile> photos,
  }) async {
    final userId = currentUser!.id;
    final siteResponse = await _client.from('sites').insert({
      'user_id': userId,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
    }).select().single();
    final siteId = siteResponse['id'];
    for (final photo in photos) {
      final file = File(photo.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}-${photo.name}';
      final storagePath = '$userId/$siteId/$fileName';
      await _client.storage.from('site-photos').upload(storagePath, file);
      final imageUrl = _client.storage.from('site-photos').getPublicUrl(storagePath);
      await _client.from('photos').insert({
        'site_id': siteId,
        'user_id': userId,
        'image_url': imageUrl,
      });
    }
  }
// Editar los sitios para esto: 
 Future<void> updateSite({
    required int siteId,
    required String title,
    required String description,
    double? latitude,
    double? longitude,
  }) async {
    final Map<String, dynamic> updateData = {
      'title': title,
      'description': description,
    };
    if (latitude != null && longitude != null) {
      updateData['latitude'] = latitude;
      updateData['longitude'] = longitude;
    }
    await _client.from('sites').update(updateData).eq('id', siteId);
  }

  Future<void> replaceSelectedPhotos({
    required int siteId,
    required List<String> keepImageUrls,
    required List<XFile> newPhotos,
  }) async {
    final userId = currentUser!.id;

    // 1. Eliminar fotos que no se quieren mantener
    final response = await _client.from('photos').select('id, image_url').eq('site_id', siteId);
    for (final photo in response) {
      final url = photo['image_url'] as String;
      if (!keepImageUrls.contains(url)) {
        await _client.from('photos').delete().eq('id', photo['id']);
        final path = Uri.parse(url).pathSegments.skipWhile((e) => e != 'site-photos').skip(1).join('/');
        await _client.storage.from('site-photos').remove([path]);
      }
    }

    // 2. Subir nuevas fotos
    for (final photo in newPhotos) {
      final file = File(photo.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}-${photo.name}';
      final storagePath = '$userId/$siteId/$fileName';

      await _client.storage.from('site-photos').upload(storagePath, file);
      final imageUrl = _client.storage.from('site-photos').getPublicUrl(storagePath);

      await _client.from('photos').insert({
        'site_id': siteId,
        'user_id': userId,
        'image_url': imageUrl,
      });
    }
  }

    Future<void> updatePartialSitePhotos({
    required int siteId,
    required List<String> photosToKeep, // URLs de las fotos que quieres conservar
    required List<XFile> newPhotos,     // Nuevas fotos que vas a subir
  }) async {
    final userId = currentUser!.id;

    // 1. Traer todas las fotos actuales de Supabase
    final currentPhotos = await _client
        .from('photos')
        .select('id, image_url')
        .eq('site_id', siteId);

    // 2. Identificar las que deben eliminarse
    final photosToDelete = currentPhotos.where((photo) =>
        !photosToKeep.contains(photo['image_url'])).toList();

    // 3. Eliminar solo las que no se van a mantener
    for (final photo in photosToDelete) {
      await _client.from('photos').delete().eq('id', photo['id']);
      // Extraer ruta de almacenamiento para borrar del bucket
      final imageUrl = photo['image_url'] as String;
      final path = Uri.decodeFull(Uri.parse(imageUrl).pathSegments.last);
      final storagePath = '$userId/$siteId/$path';
      await _client.storage.from('site-photos').remove([storagePath]);
    }

    // 4. Subir nuevas fotos
    for (final photo in newPhotos) {
      final file = File(photo.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}-${photo.name}';
      final storagePath = '$userId/$siteId/$fileName';

      await _client.storage.from('site-photos').upload(storagePath, file);
      final imageUrl = _client.storage.from('site-photos').getPublicUrl(storagePath);

      await _client.from('photos').insert({
        'site_id': siteId,
        'user_id': userId,
        'image_url': imageUrl,
      });
    }
  }

  // lo que se mantiene:
  Future<void> deleteSite(int siteId) async {
    await _client.from('sites').delete().eq('id', siteId);
  }

  Stream<List<Map<String, dynamic>>> getReviewsStream(int siteId) {
    return _client
        .from('reviews')
        .stream(primaryKey: ['id'])
        .eq('site_id', siteId)
        .order('created_at', ascending: true);
  }

  Stream<List<Map<String, dynamic>>> getRepliesStream(int reviewId) {
  return _client
      .from('replies')
      .stream(primaryKey: ['id'])
      .eq('review_id', reviewId)
      .order('created_at', ascending: true);
  }

  Future<List<Map<String, dynamic>>> getRepliesForReview(int reviewId) async {
    return await _client
        .from('replies')
        .select('*, profiles (username, avatar_url)')
        .eq('review_id', reviewId)
        .order('created_at', ascending: true);
  }

  Future<void> postReview({
    required int siteId,
    required String content,
    required int rating,
  }) async {
    await _client.from('reviews').insert({
      'site_id': siteId,
      'user_id': currentUser!.id,
      'content': content,
      'rating': rating,
    });
  }

  Future<void> postReply({
    required int reviewId,
    required String content,
  }) async {
    await _client.from('replies').insert({
      'review_id': reviewId,
      'user_id': currentUser!.id,
      'content': content,
    });
  }
  
  Future<void> updateSitePhotos({
  required int siteId,
  required List<XFile> newPhotos,
  }) async {
    final userId = currentUser!.id;

    // 1. Elimina las fotos actuales
    await _client.from('photos').delete().eq('site_id', siteId);

    // 2. Sube las nuevas fotos
    for (final photo in newPhotos) {
      final file = File(photo.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}-${photo.name}';
      final storagePath = '$userId/$siteId/$fileName';

      await _client.storage.from('site-photos').upload(storagePath, file);
      final imageUrl = _client.storage.from('site-photos').getPublicUrl(storagePath);

      await _client.from('photos').insert({
        'site_id': siteId,
        'user_id': userId,
        'image_url': imageUrl,
      });
    }
  }
}
