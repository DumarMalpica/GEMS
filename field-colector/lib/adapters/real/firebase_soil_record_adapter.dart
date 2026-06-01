import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/soil_record.dart';
import '../../domain/ports/soil_record_remote_port.dart';
import '../../domain/entities/photo.dart';
import '../../domain/entities/coordinate.dart';
import '../../domain/entities/plot.dart';
import 'record_photo_sync_helper.dart';

/// Adaptador concreto para operaciones de SoilRecord en Firestore.
class FirebaseSoilRecordAdapter implements SoilRecordRemotePort {
  final FirebaseFirestore _firestore;
  final String _collection = 'soil_records';

  FirebaseSoilRecordAdapter(this._firestore);

  /// Guarda un nuevo registro de SoilRecord en Firestore y sincroniza sus datos.
  @override
  Future<void> saveSoilRecord(SoilRecord item) async {
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
      'soilTypes': item.soilTypes,
      'soilTypeFreeText': item.soilTypeFreeText,
      'dominantColor': item.dominantColor,
      'colorVariability': item.colorVariability,
      'texture': item.texture,
      'textureFreeText': item.textureFreeText,
      'structure': item.structure,
      'structureFreeText': item.structureFreeText,
      'soilProfile': item.soilProfile,
      'hasSample': item.hasSample,
      'sampleId': item.sampleId,
      'sampleDepth': item.sampleDepth,
      'observations': item.observations,
      'plot': {
        'hasPlot': item.plot.hasPlot,
        'height': item.plot.height,
        'width': item.plot.width,
      },
      'photos': item.photos.map((p) => {
        'id': p.id, 'filename': p.filename, 'localPath': p.localPath, 'storageUrl': p.storageUrl,
        'photoType': p.photoType, 'recordId': p.recordId, 'recordType': p.recordType,
      }).toList(),
    });

    if (item.photos.isNotEmpty) {
      await RecordPhotoSyncHelper.uploadAndSyncPhotos(
        recordId: item.id,
        recordType: 'soil',
        outingId: item.outingId,
        photos: item.photos,
        firestore: _firestore,
      );
    }
  }

  /// Actualiza un registro existente de SoilRecord en Firestore con los nuevos datos.
  @override
  Future<void> updateSoilRecord(String id, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(id).update(data);
  }

  /// Elimina un registro de SoilRecord en Firestore mediante su id.
  @override
  Future<void> deleteSoilRecord(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  /// Recupera un registro de [SoilRecord] por su [id]. Retorna null si no existe.
  @override
  Future<SoilRecord?> getSoilRecordById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return _mapSnapshotToSoilRecord(doc);
  }

  /// Obtiene de forma paginada un listado de registros de suelos.
  @override
  Future<SoilRecordSearchResult> getSoilRecords({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _firestore.collection(_collection).limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();

    return SoilRecordSearchResult(
      items: snapshot.docs.map((doc) => _mapSnapshotToSoilRecord(doc)).toList(),
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  /// Consulta todos los registros de suelos filtrables para exportación a Excel.
  @override
  Future<List<SoilRecord>> getSoilRecordsForExport({String? outingId, String? userId, DateTime? startDate, DateTime? endDate}) async {
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
    return snapshot.docs.map((doc) => _mapSnapshotToSoilRecord(doc)).toList();
  }

  /// Stream para observar en tiempo real los registros de suelos de una expedición ([outingId]).
  @override
  Stream<List<SoilRecord>> watchSoilRecordsByOuting(String outingId) {
    return _firestore
        .collection(_collection)
        .where('outingId', isEqualTo: outingId)
        .snapshots()
        .map((snap) => snap.docs.map(_mapSnapshotToSoilRecord).toList());
  }

  /// Mapea un documento de Firestore (`DocumentSnapshot`) a una entidad de dominio `SoilRecord`.
  SoilRecord _mapSnapshotToSoilRecord(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final coord = data['coordinates'] as Map<String, dynamic>? ?? {};
    final plotData = data['plot'] as Map<String, dynamic>? ?? {};

    return SoilRecord(
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
      soilTypes: List<String>.from(data['soilTypes'] ?? []),
      soilTypeFreeText: data['soilTypeFreeText'],
      dominantColor: data['dominantColor'] ?? '',
      colorVariability: data['colorVariability'] ?? '',
      texture: List<String>.from(data['texture'] ?? []),
      textureFreeText: data['textureFreeText'],
      structure: data['structure'] ?? '',
      structureFreeText: data['structureFreeText'],
      soilProfile: data['soilProfile'] ?? '',
      hasSample: data['hasSample'] ?? false,
      sampleId: data['sampleId'],
      sampleDepth: data['sampleDepth']?.toDouble(),
      observations: data['observations'] ?? '',
      plot: Plot(
        hasPlot: plotData['hasPlot'] ?? false,
        height: plotData['height']?.toDouble(),
        width: plotData['width']?.toDouble(),
      ),
      photos: (data['photos'] as List<dynamic>? ?? []).map((p) => Photo(
        id: p['id'] ?? '', filename: p['filename'] ?? '', localPath: p['localPath'] ?? '',
        storageUrl: p['storageUrl'] ?? '', photoType: p['photoType'] ?? '', recordId: p['recordId'] ?? '',
        recordType: p['recordType'] ?? '', syncStatus: 'synced',
      )).toList(),
    );
  }
}
