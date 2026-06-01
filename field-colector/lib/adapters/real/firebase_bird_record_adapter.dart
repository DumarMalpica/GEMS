import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/bird_record.dart';
import '../../domain/ports/bird_record_remote_port.dart';
import '../../domain/entities/photo.dart';
import '../../domain/entities/coordinate.dart';
import 'record_photo_sync_helper.dart';

/// Adaptador concreto para operaciones de BirdRecord en Firestore.
class FirebaseBirdRecordAdapter implements BirdRecordRemotePort {
  final FirebaseFirestore _firestore;
  final String _collection = 'bird_records';

  FirebaseBirdRecordAdapter(this._firestore);

  /// Guarda un nuevo registro de BirdRecord en Firestore y sincroniza sus datos.
  @override
  Future<void> saveBirdRecord(BirdRecord item) async {
    await _firestore.collection(_collection).doc(item.id).set({
      'outingId': item.outingId,
      'userId': item.userId,
      'recordedAt': item.recordedAt.toIso8601String(),
      'department': item.department,
      'municipality': item.municipality,
      'village': item.village,
      'sector': item.sector,
      'coordinates': {
        'latitude': item.coordinates.latitude,
        'longitude': item.coordinates.longitude,
        'altitude': item.coordinates.altitude,
        'gpsAccuracy': item.coordinates.gpsAccuracy,
        'manuallyEdited': item.coordinates.manuallyEdited,
      },
      'season': item.season,
      'place': item.place,
      'speciesId': item.speciesId,
      'birdType': item.birdType,
      'migratorStatus': item.migratorStatus,
      'individualCount': item.individualCount,
      'behavior': item.behavior,
      'activity': item.activity,
      'habitat': item.habitat,
      'foragingType': item.foragingType,
      'observedThreats': item.observedThreats,
      'photos': item.photos.map((p) => {
        'id': p.id, 'filename': p.filename, 'localPath': p.localPath, 'storageUrl': p.storageUrl,
        'photoType': p.photoType, 'recordId': p.recordId, 'recordType': p.recordType,
      }).toList(),
    });

    if (item.photos.isNotEmpty) {
      await RecordPhotoSyncHelper.uploadAndSyncPhotos(
        recordId: item.id,
        recordType: 'bird',
        outingId: item.outingId,
        photos: item.photos,
        firestore: _firestore,
      );
    }
  }

  /// Actualiza un registro existente de BirdRecord en Firestore con los nuevos datos.
  @override
  Future<void> updateBirdRecord(String id, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(id).update(data);
  }

  /// Elimina un registro de BirdRecord en Firestore mediante su id.
  @override
  Future<void> deleteBirdRecord(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  /// Recupera un registro de BirdRecord por su [id]. Retorna null si no existe.
  @override
  Future<BirdRecord?> getBirdRecordById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return _mapSnapshotToBirdRecord(doc);
  }

  /// Obtiene de forma paginada un listado de registros de aves.
  @override
  Future<BirdRecordSearchResult> getBirdRecords({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _firestore.collection(_collection).limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();

    return BirdRecordSearchResult(
      items: snapshot.docs.map((doc) => _mapSnapshotToBirdRecord(doc)).toList(),
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  /// Consulta todos los registros de aves filtrables para exportación a Excel.
  @override
  Future<List<BirdRecord>> getBirdRecordsForExport({String? outingId, String? userId, DateTime? startDate, DateTime? endDate}) async {
    Query query = _firestore.collection(_collection);

    if (outingId != null) {
      query = query.where('outingId', isEqualTo: outingId);
    } else if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    if (startDate != null) {
      query = query.where('recordedAt', isGreaterThanOrEqualTo: startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.where('recordedAt', isLessThanOrEqualTo: endDate.toIso8601String());
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => _mapSnapshotToBirdRecord(doc)).toList();
  }

  /// Stream para observar en tiempo real los registros de aves correspondientes a una expedición ([outingId]).
  @override
  Stream<List<BirdRecord>> watchBirdRecordsByOuting(String outingId) {
    return _firestore
        .collection(_collection)
        .where('outingId', isEqualTo: outingId)
        .snapshots()
        .map((snap) => snap.docs.map(_mapSnapshotToBirdRecord).toList());
  }

  /// Mapea un documento de Firestore (`DocumentSnapshot`) a una entidad de dominio `BirdRecord`.
  BirdRecord _mapSnapshotToBirdRecord(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final coord = data['coordinates'] as Map<String, dynamic>? ?? {};

    return BirdRecord(
      id: doc.id,
      outingId: data['outingId'] ?? '',
      userId: data['userId'] ?? '',
      recordedAt: data['recordedAt'] != null ? DateTime.parse(data['recordedAt']) : DateTime.now(),
      department: data['department'] ?? '',
      municipality: data['municipality'] ?? '',
      village: data['village'] ?? '',
      sector: data['sector'] ?? '',
      syncStatus: 'synced',
      coordinates: Coordinate(
        latitude: (coord['latitude'] ?? 0.0).toDouble(),
        longitude: (coord['longitude'] ?? 0.0).toDouble(),
        altitude: (coord['altitude'] ?? 0.0).toDouble(),
        gpsAccuracy: (coord['gpsAccuracy'] ?? 0.0).toDouble(),
        manuallyEdited: coord['manuallyEdited'] ?? false,
      ),
      season: data['season'] ?? '',
      place: data['place'] ?? '',
      speciesId: data['speciesId'] ?? '',
      birdType: data['birdType'] ?? '',
      migratorStatus: data['migratorStatus'] ?? '',
      individualCount: data['individualCount'] ?? 0,
      behavior: data['behavior'] ?? '',
      activity: data['activity'] ?? '',
      habitat: List<String>.from(data['habitat'] ?? []),
      foragingType: List<String>.from(data['foragingType'] ?? []),
      observedThreats: List<String>.from(data['observedThreats'] ?? []),
      photos: (data['photos'] as List<dynamic>? ?? []).map((p) => Photo(
        id: p['id'] ?? '', filename: p['filename'] ?? '', localPath: p['localPath'] ?? '',
        storageUrl: p['storageUrl'] ?? '', photoType: p['photoType'] ?? '', recordId: p['recordId'] ?? '',
        recordType: p['recordType'] ?? '', syncStatus: 'synced',
      )).toList(),
    );
  }
}
