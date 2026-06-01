// ignore_for_file: experimental_member_use
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/photo.dart';
import '../../domain/ports/photo_local_port.dart';
import '../../core/database/isar_service.dart';
import 'photo_model.dart';

/// Adaptador que implementa [PhotoLocalPort] para el manejo de fotos.
///
/// Se encarga de guardar fotos localmente usando Isar (como base de datos local),
/// comprimirlas y posteriormente subirlas a Cloudinary. También se encarga de
/// actualizar las referencias de estas fotos en los registros correspondientes en Firestore.
class PhotoStorageAdapter implements PhotoLocalPort {
  /// Instancia de [FirebaseStorage] para interactuar con el almacenamiento en la nube (opcional, en esta implementación se usa Cloudinary).
  final FirebaseStorage? _storage;
  
  /// Cliente HTTP utilizado para realizar la petición a la API de Cloudinary.
  final http.Client _httpClient;

  /// Constructor de [PhotoStorageAdapter].
  ///
  /// Permite inyectar [storage] y [httpClient] para facilitar pruebas o mockeos.
  PhotoStorageAdapter({FirebaseStorage? storage, http.Client? httpClient})
    : _storage = storage,
      _httpClient = httpClient ?? http.Client();

  // ── PhotoLocalPort ────────────────────────────────────────────────────────

  /// Guarda una foto localmente, comprimiéndola y almacenando sus metadatos en Isar.
  /// 
  /// Recibe los [bytes] de la imagen, el [recordId] al que pertenece, el [photoType]
  /// (ej. 'bird', 'rock') y el [recordType]. Retorna el ID generado para la foto.
  @override
  Future<String> savePhotoLocally(
    Uint8List bytes,
    String recordId,
    String photoType, {
    required String recordType,
  }) async {
    final compressed = await _compress(bytes);

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final fileName = '${photoType}_$timestamp.jpg';
    final path = '${dir.path}/citesa_photos/$recordId/$fileName';

    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(compressed);

    final photoId = '$recordId-$timestamp';
    final model = PhotoModel()
      ..photoId = photoId
      ..filename = fileName
      ..localPath = path
      ..storageUrl = ''
      ..photoType = photoType
      ..recordId = recordId
      ..recordType = recordType
      ..syncStatus = 'pending'
      ..createdAt = DateTime.now();

    final isar = await IsarService.getInstance();
    await isar.writeTxn(() async {
      await isar.photoModels.putByPhotoId(model);
    });

    return photoId;
  }

  /// Recupera un objeto [Photo] específico dado su [photoId] consultando la BD local.
  @override
  Future<Photo?> getPhotoById(String photoId) async {
    final isar = await IsarService.getInstance();
    final query = isar.photoModels.buildQuery<PhotoModel>(
      filter: FilterCondition.equalTo(property: 'photoId', value: photoId),
      limit: 1,
    );
    final results = await query.findAll();
    if (results.isEmpty) return null;
    return results.first.toDomain();
  }

  /// Reasigna todas las fotos de un [fromRecordId] a un [toRecordId].
  /// 
  /// Útil cuando se genera un ID temporal y luego el servidor confirma el ID final del registro.
  @override
  Future<void> relinkPhotosToRecord(
    String fromRecordId,
    String toRecordId, {
    required String recordType,
  }) async {
    if (fromRecordId == toRecordId) return;

    final isar = await IsarService.getInstance();
    final query = isar.photoModels.buildQuery<PhotoModel>(
      filter: FilterCondition.equalTo(
        property: 'recordId',
        value: fromRecordId,
      ),
    );
    final results = await query.findAll();
    if (results.isEmpty) return;

    for (final model in results) {
      model.recordId = toRecordId;
      model.recordType = recordType;
    }

    await isar.writeTxn(() async {
      for (final model in results) {
        await isar.photoModels.put(model);
      }
    });
  }

  /// Obtiene todas las fotos asociadas a un registro específico ([recordId]).
  @override
  Future<List<Photo>> getPhotosByRecord(String recordId) async {
    final isar = await IsarService.getInstance();
    final query = isar.photoModels.buildQuery<PhotoModel>(
      filter: FilterCondition.equalTo(property: 'recordId', value: recordId),
    );
    final results = await query.findAll();
    return results.map((m) => m.toDomain()).toList();
  }

  /// Elimina una foto localmente (tanto el archivo físico como su registro en Isar) 
  /// basándose en su [photoId].
  @override
  Future<void> deletePhoto(String photoId) async {
    final isar = await IsarService.getInstance();
    final query = isar.photoModels.buildQuery<PhotoModel>(
      filter: FilterCondition.equalTo(property: 'photoId', value: photoId),
      limit: 1,
    );
    final results = await query.findAll();
    if (results.isEmpty) return;
    final model = results.first;

    final file = File(model.localPath);
    if (await file.exists()) await file.delete();

    await isar.writeTxn(() async {
      await isar.photoModels.deleteByPhotoId(photoId);
    });
  }

  /// Recupera todas las fotos que tienen estado de sincronización 'pending'.
  @override
  Future<List<Photo>> getPendingSyncPhotos() async {
    final isar = await IsarService.getInstance();
    final query = isar.photoModels.buildQuery<PhotoModel>(
      filter: FilterCondition.equalTo(property: 'syncStatus', value: 'pending'),
    );
    final results = await query.findAll();
    return results.map((m) => m.toDomain()).toList();
  }

  /// Actualiza el estado de sincronización ([status]) de una foto en la BD local.
  @override
  Future<void> updatePhotoSyncStatus(String photoId, String status) async {
    final isar = await IsarService.getInstance();
    final query = isar.photoModels.buildQuery<PhotoModel>(
      filter: FilterCondition.equalTo(property: 'photoId', value: photoId),
      limit: 1,
    );
    final results = await query.findAll();
    if (results.isEmpty) return;
    final model = results.first..syncStatus = status;
    await isar.writeTxn(() async {
      await isar.photoModels.put(model);
    });
  }

  /// Actualiza la URL remota ([storageUrl]) de una foto luego de ser subida, 
  /// marcando su estado como 'synced'.
  @override
  Future<void> updatePhotoStorageUrl(String photoId, String storageUrl) async {
    final isar = await IsarService.getInstance();
    final query = isar.photoModels.buildQuery<PhotoModel>(
      filter: FilterCondition.equalTo(property: 'photoId', value: photoId),
      limit: 1,
    );
    final results = await query.findAll();
    if (results.isEmpty) return;
    final model = results.first
      ..storageUrl = storageUrl
      ..syncStatus = 'synced';
    await isar.writeTxn(() async {
      await isar.photoModels.put(model);
    });
  }

  // ── Cloudinary Storage upload ──────────────────────────────────────────────

  /// Sube la foto local a la plataforma **Cloudinary**.
  ///
  /// Lee el archivo local asociado al [photoId], lo sube vía HTTP Multipart a Cloudinary, 
  /// obtiene la `secure_url` y actualiza tanto el registro local (Isar) como el 
  /// documento remoto (Firestore) correspondiente al registro ([recordId]) con la URL final.
  Future<void> uploadToFirebase(String photoId, String outingPrefix) async {
    final isar = await IsarService.getInstance();
    final query = isar.photoModels.buildQuery<PhotoModel>(
      filter: FilterCondition.equalTo(property: 'photoId', value: photoId),
      limit: 1,
    );
    final results = await query.findAll();
    if (results.isEmpty) return;
    final model = results.first;

    if (model.syncStatus == 'synced') return;

    try {
      final file = File(model.localPath);
      if (!await file.exists()) {
        model.syncStatus = 'error';
      } else {
        final url = Uri.parse(
          'https://api.cloudinary.com/v1_1/dvcbrr7h7/image/upload',
        );
        final request = http.MultipartRequest('POST', url)
          ..fields['upload_preset'] = 'proyectoApp'
          ..files.add(
            await http.MultipartFile.fromPath('file', model.localPath),
          );

        final streamedResponse = await _httpClient.send(request);
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final responseData =
              jsonDecode(response.body) as Map<String, dynamic>;
          final secureUrl = responseData['secure_url'] as String;

          model
            ..storageUrl = secureUrl
            ..syncStatus = 'synced';

          final collection = _collectionFromRecordType(model.recordType);
          if (collection != null) {
            final docRef = FirebaseFirestore.instance
                .collection(collection)
                .doc(model.recordId);
            final doc = await docRef.get();
            if (doc.exists) {
              final data = doc.data();
              if (data != null) {
                final photosList = List<dynamic>.from(data['photos'] ?? []);
                var updated = false;
                for (var i = 0; i < photosList.length; i++) {
                  final p = Map<String, dynamic>.from(photosList[i]);
                  if (p['id'] == photoId) {
                    p['storageUrl'] = secureUrl;
                    p['syncStatus'] = 'synced';
                    photosList[i] = p;
                    updated = true;
                  }
                }
                if (updated) {
                  await docRef.update({'photos': photosList});
                }
              }
            }
          }
        } else {
          model.syncStatus = 'error';
        }
      }
    } catch (_) {
      model.syncStatus = 'error';
    }

    await isar.writeTxn(() async {
      await isar.photoModels.put(model);
    });
  }

  /// Determina el nombre de la colección en Firestore basándose en el [recordType].
  String? _collectionFromRecordType(String recordType) {
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

  // ── Helpers privados ──────────────────────────────────────────────────────

  /// Límite presentable en móvil; prioriza tamaño en Cloudinary.
  static const _maxPhotoDim = 1024;
  static const _jpegQuality = 40;

  /// Comprime una imagen a un máximo de `_maxPhotoDim` de ancho/alto
  /// y una calidad de `_jpegQuality`.
  Future<Uint8List> _compress(Uint8List bytes) async {
    final result = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: _maxPhotoDim,
      minHeight: _maxPhotoDim,
      quality: _jpegQuality,
      format: CompressFormat.jpeg,
    );
    return result;
  }

  /// Deduce el tipo de registro (ej. 'bird', 'rock') a partir de su ID o prefijo.
  String _recordTypeFromId(String recordId) {
    if (recordId.contains('bird')) return 'bird';
    if (recordId.contains('rock')) return 'rock';
    if (recordId.contains('soil')) return 'soil';
    if (recordId.contains('water')) return 'water';
    if (recordId.contains('vegetation')) return 'vegetation';
    return 'unknown';
  }
}
