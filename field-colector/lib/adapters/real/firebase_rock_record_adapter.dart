import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/rock_record.dart';
import '../../domain/ports/rock_record_remote_port.dart';
import '../../domain/entities/photo.dart';
import '../../domain/entities/coordinate.dart';
import 'record_photo_sync_helper.dart';

/// Adaptador concreto para operaciones de RockRecord en Firestore.
class FirebaseRockRecordAdapter implements RockRecordRemotePort {
  final FirebaseFirestore _firestore;
  final String _collection = 'rock_records';

  FirebaseRockRecordAdapter(this._firestore);

  /// Guarda un nuevo registro de RockRecord en Firestore y sincroniza sus datos.
  @override
  Future<void> saveRockRecord(RockRecord item) async {
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
      'rockType': item.rockType,
      'rockTypeFreeText': item.rockTypeFreeText,
      'dominantColor': item.dominantColor,
      'texture': item.texture,
      'structure': item.structure,
      'hardness': item.hardness,
      'minerals': item.minerals,
      'hasSample': item.hasSample,
      'sampleId': item.sampleId,
      'sampleDepth': item.sampleDepth,
      'observations': item.observations,
      'photos': item.photos.map((p) => {
        'id': p.id, 'filename': p.filename, 'localPath': p.localPath, 'storageUrl': p.storageUrl,
        'photoType': p.photoType, 'recordId': p.recordId, 'recordType': p.recordType,
      }).toList(),
    });

    if (item.photos.isNotEmpty) {
      await RecordPhotoSyncHelper.uploadAndSyncPhotos(
        recordId: item.id,
        recordType: 'rock',
        outingId: item.outingId,
        photos: item.photos,
        firestore: _firestore,
      );
    }
  }

  /// Actualiza un registro existente de RockRecord en Firestore con los nuevos datos.
  @override
  Future<void> updateRockRecord(String id, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(id).update(data);
  }

  /// Elimina un registro de RockRecord en Firestore mediante su id.
  @override
  Future<void> deleteRockRecord(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  /// Recupera un registro de [RockRecord] por su [id]. Retorna null si no existe.
  @override
  Future<RockRecord?> getRockRecordById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return _mapSnapshotToRockRecord(doc);
  }

  /// Obtiene de forma paginada un listado de registros de rocas.
  @override
  Future<RockRecordSearchResult> getRockRecords({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _firestore.collection(_collection).limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();

    return RockRecordSearchResult(
      items: snapshot.docs.map((doc) => _mapSnapshotToRockRecord(doc)).toList(),
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  /// Consulta todos los registros de rocas filtrables para exportación a Excel.
  @override
  Future<List<RockRecord>> getRockRecordsForExport({String? outingId, String? userId, DateTime? startDate, DateTime? endDate}) async {
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
    return snapshot.docs.map((doc) => _mapSnapshotToRockRecord(doc)).toList();
  }

  /// Stream para observar en tiempo real los registros de rocas de una expedición ([outingId]).
  @override
  Stream<List<RockRecord>> watchRockRecordsByOuting(String outingId) {
    return _firestore
        .collection(_collection)
        .where('outingId', isEqualTo: outingId)
        .snapshots()
        .map((snap) => snap.docs.map(_mapSnapshotToRockRecord).toList());
  }

  /// Mapea un documento de Firestore (`DocumentSnapshot`) a una entidad de dominio `RockRecord`.
  RockRecord _mapSnapshotToRockRecord(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final coord = data['coordinates'] as Map<String, dynamic>? ?? {};

    return RockRecord(
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
      rockType: data['rockType'] ?? '',
      rockTypeFreeText: data['rockTypeFreeText'],
      dominantColor: data['dominantColor'] ?? '',
      texture: List<String>.from(data['texture'] ?? []),
      structure: data['structure'] ?? '',
      hardness: data['hardness'] ?? '',
      minerals: data['minerals'] ?? '',
      hasSample: data['hasSample'] ?? false,
      sampleId: data['sampleId'],
      sampleDepth: data['sampleDepth']?.toDouble(),
      observations: data['observations'] ?? '',
      photos: (data['photos'] as List<dynamic>? ?? []).map((p) => Photo(
        id: p['id'] ?? '', filename: p['filename'] ?? '', localPath: p['localPath'] ?? '',
        storageUrl: p['storageUrl'] ?? '', photoType: p['photoType'] ?? '', recordId: p['recordId'] ?? '',
        recordType: p['recordType'] ?? '', syncStatus: 'synced',
      )).toList(),
    );
  }
}
