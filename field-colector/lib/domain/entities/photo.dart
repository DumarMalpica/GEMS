/// Representa una fotografía adjunta a un registro de campo.
/// 
/// Esta entidad se encarga de manejar tanto la ruta del archivo local
/// como su URL en la nube una vez sincronizada con Cloudinary/Firebase.
class Photo {
  /// ID único de la fotografía.
  final String id;

  /// Nombre del archivo (e.g. foto_123.jpg).
  final String filename;

  /// Ruta absoluta del archivo en el sistema de archivos del dispositivo.
  final String localPath;

  /// URL de descarga pública provista por el proveedor de almacenamiento (Cloudinary).
  final String storageUrl;

  /// Clasificación de la foto según lo que muestra (e.g. 'animal', 'paisaje', 'suelo').
  final String photoType;

  /// ID del registro principal al que pertenece la foto.
  final String recordId;

  /// Tipo de registro asociado ('bird', 'rock', 'water', etc.).
  final String recordType;

  /// Estado actual de sincronización (e.g., 'pending', 'synced').
  final String syncStatus;

  Photo({
    required this.id,
    required this.filename,
    required this.localPath,
    required this.storageUrl,
    required this.photoType,
    required this.recordId,
    required this.recordType,
    required this.syncStatus,
  });
}
