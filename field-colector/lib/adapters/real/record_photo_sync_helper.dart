import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import '../../core/database/isar_service.dart';
import '../../domain/entities/photo.dart';
import 'photo_model.dart';

/// Helper class (Clase de utilidad) para la sincronización y subida de fotos a Cloudinary.
///
/// Contiene lógica estática que abstrae el proceso iterativo de subir un 
/// listado de [Photo] pertenecientes a un registro, actualizando el estado
/// tanto a nivel local (Isar) como en la base de datos remota (Firestore).
class RecordPhotoSyncHelper {
  RecordPhotoSyncHelper._();

  /// Sube de manera asíncrona una lista de [photos] a Cloudinary y sincroniza 
  /// el resultado en las bases de datos correspondientes.
  /// 
  /// Para cada foto en [photos]:
  /// 1. Verifica su existencia local.
  /// 2. La sube usando HTTP Multipart Request.
  /// 3. Actualiza el documento de Firestore del registro padre incluyendo la URL de Cloudinary.
  /// 4. Actualiza el registro local de la foto en Isar a estado 'synced' o 'error'.
  static Future<void> uploadAndSyncPhotos({
    required String recordId,
    required String recordType,
    required String outingId,
    required List<Photo> photos,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    http.Client? httpClient,
  }) async {
    final fs = firestore ?? FirebaseFirestore.instance;

    if (photos.isEmpty) return;

    String prefix = 'unknown';
    try {
      final outingDoc = await fs.collection('outings').doc(outingId).get();
      if (outingDoc.exists) {
        prefix = outingDoc.data()?['prefix'] ?? 'unknown';
      }
    } catch (_) {
    }

    final client = httpClient ?? http.Client();

    try {
      for (final photo in photos) {
        if (photo.localPath.isEmpty) continue;
        final file = File(photo.localPath);
        if (!await file.exists()) continue;

        try {
          final url = Uri.parse('https://api.cloudinary.com/v1_1/dvcbrr7h7/image/upload');
          final request = http.MultipartRequest('POST', url)
            ..fields['upload_preset'] = 'proyectoApp'
            ..files.add(await http.MultipartFile.fromPath('file', photo.localPath));

          final streamedResponse = await client.send(request);
          final response = await http.Response.fromStream(streamedResponse);

          if (response.statusCode != 200) {
            throw Exception('Cloudinary upload failed with status ${response.statusCode}');
          }

          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          final secureUrl = responseData['secure_url'] as String;

          try {
            final isar = await IsarService.getInstance();
            final localPhoto = await isar.photoModels
                .filter()
                .photoIdEqualTo(photo.id)
                .findFirst();
            if (localPhoto != null) {
              localPhoto.storageUrl = secureUrl;
              localPhoto.syncStatus = 'synced';
              await isar.writeTxn(() async {
                await isar.photoModels.put(localPhoto);
              });
            }
          } catch (_) {
          }

          final collectionName = _collectionFromRecordType(recordType);
          if (collectionName != null) {
            final docRef = fs.collection(collectionName).doc(recordId);
            await fs.runTransaction((transaction) async {
              final docSnap = await transaction.get(docRef);
              if (docSnap.exists) {
                final data = docSnap.data();
                if (data != null) {
                  final photosList = List<dynamic>.from(data['photos'] ?? []);
                  var updated = false;
                  for (var i = 0; i < photosList.length; i++) {
                    final p = Map<String, dynamic>.from(photosList[i]);
                    if (p['id'] == photo.id) {
                      p['storageUrl'] = secureUrl;
                      p['syncStatus'] = 'synced';
                      photosList[i] = p;
                      updated = true;
                    }
                  }
                  if (updated) {
                    transaction.update(docRef, {'photos': photosList});
                  }
                }
              }
            });
          }
        } catch (_) {
          try {
            final isar = await IsarService.getInstance();
            final localPhoto = await isar.photoModels
                .filter()
                .photoIdEqualTo(photo.id)
                .findFirst();
            if (localPhoto != null) {
              localPhoto.syncStatus = 'error';
              await isar.writeTxn(() async {
                await isar.photoModels.put(localPhoto);
              });
            }
          } catch (_) {}
        }
      }
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  /// Retorna el nombre de la colección de Firestore que corresponde al [recordType].
  static String? _collectionFromRecordType(String recordType) {
    switch (recordType.toLowerCase()) {
      case 'bird':
        return 'bird_records';
      case 'rock':
        return 'rock_records';
      case 'soil':
        return 'soil_records';
      case 'water':
        return 'water_records';
      case 'vegetation':
        return 'vegetation_records';
      case 'social':
        return 'social_records';
      default:
        return null;
    }
  }
}
