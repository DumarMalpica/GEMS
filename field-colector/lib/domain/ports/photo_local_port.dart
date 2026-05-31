import 'dart:typed_data';
import '../entities/photo.dart';

/// Interfaz (Puerto) que define el contrato para el almacenamiento y manejo local de fotos.
abstract class PhotoLocalPort {
  /// Guarda una foto comprimida localmente.
  /// 
  /// Los bytes de la foto se procesan y asocian a un [recordId] y [recordType] 
  /// específicos. Retorna el identificador único ([photoId]) generado localmente.
  Future<String> savePhotoLocally(
    Uint8List bytes,
    String recordId,
    String photoType, {
    required String recordType,
  });

  /// Obtiene la lista de todas las fotos asociadas a un registro específico ([recordId]).
  Future<List<Photo>> getPhotosByRecord(String recordId);

  /// Recupera un objeto [Photo] específico dado su identificador único ([photoId]).
  Future<Photo?> getPhotoById(String photoId);

  /// Elimina físicamente el archivo y su metadata en la base de datos local según el [photoId].
  Future<void> deletePhoto(String photoId);

  /// Retorna las fotos cuyo estado de sincronización es 'pending'.
  Future<List<Photo>> getPendingSyncPhotos();

  /// Actualiza el estado de sincronización ([status]) para una foto específica ([photoId]).
  Future<void> updatePhotoSyncStatus(String photoId, String status);

  /// Guarda la URL remota de almacenamiento ([storageUrl]) para una foto subida a la nube.
  Future<void> updatePhotoStorageUrl(String photoId, String storageUrl);

  /// Reasigna fotos de un borrador temporal ([fromRecordId]) al ID definitivo 
  /// del registro ([toRecordId]) una vez este se ha creado correctamente en el backend.
  Future<void> relinkPhotosToRecord(
    String fromRecordId,
    String toRecordId, {
    required String recordType,
  });
}
