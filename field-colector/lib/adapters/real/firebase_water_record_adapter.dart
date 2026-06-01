import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/water_record.dart';
import '../../domain/ports/water_record_remote_port.dart';
import '../../domain/entities/photo.dart';
import '../../domain/entities/coordinate.dart';
import 'record_photo_sync_helper.dart';

/// Adaptador concreto para operaciones de WaterRecord en Firestore.
class FirebaseWaterRecordAdapter implements WaterRecordRemotePort {
  final FirebaseFirestore _firestore;
  final String _collection = 'water_records';

  FirebaseWaterRecordAdapter(this._firestore);

  /// Guarda un nuevo registro de WaterRecord en Firestore y sincroniza sus datos.
  @override
  Future<void> saveWaterRecord(WaterRecord item) async {
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
      'weatherConditions': item.weatherConditions,
      'visibility': item.visibility,
      'access': item.access,
      'accessFreeText': item.accessFreeText,
      'samplingDepth': item.samplingDepth,
      'ph': item.ph,
      'temperature': item.temperature,
      'conductivity': item.conductivity,
      'dissolvedOxygen': item.dissolvedOxygen,
      'turbidity': item.turbidity,
      'apparentColor': item.apparentColor,
      'odor': item.odor,
      'hasSample': item.hasSample,
      'sampleId': item.sampleId,
      'sampleType': item.sampleType,
      'container': item.container,
      'samplingGoal': item.samplingGoal,
      // Faltaba agregar las fotos aquí
      'photos': item.photos.map((p) => {
        'id': p.id, 'filename': p.filename, 'localPath': p.localPath, 'storageUrl': p.storageUrl,
        'photoType': p.photoType, 'recordId': p.recordId, 'recordType': p.recordType,
      }).toList(),
    });

    if (item.photos.isNotEmpty) {
      await RecordPhotoSyncHelper.uploadAndSyncPhotos(
        recordId: item.id,
        recordType: 'water',
        outingId: item.outingId,
        photos: item.photos,
        firestore: _firestore,
      );
    }
  }

  /// Actualiza un registro existente de WaterRecord en Firestore con los nuevos datos.
  @override
  Future<void> updateWaterRecord(String id, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(id).update(data);
  }

  /// Elimina un registro de WaterRecord en Firestore mediante su id.
  @override
  Future<void> deleteWaterRecord(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  /// Recupera un registro de [WaterRecord] por su [id]. Retorna null si no existe.
  @override
  Future<WaterRecord?> getWaterRecordById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return _mapSnapshotToWaterRecord(doc);
  }

  /// Obtiene de forma paginada un listado de registros de agua.
  @override
  Future<WaterRecordSearchResult> getWaterRecords({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _firestore.collection(_collection).limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();

    return WaterRecordSearchResult(
      items: snapshot.docs.map((doc) => _mapSnapshotToWaterRecord(doc)).toList(),
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  /// Consulta todos los registros de agua filtrables para exportación a Excel.
  @override
  Future<List<WaterRecord>> getWaterRecordsForExport({String? outingId, String? userId, DateTime? startDate, DateTime? endDate}) async {
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
    return snapshot.docs.map((doc) => _mapSnapshotToWaterRecord(doc)).toList();
  }

  /// Stream para observar en tiempo real los registros de agua de una expedición ([outingId]).
  @override
  Stream<List<WaterRecord>> watchWaterRecordsByOuting(String outingId) {
    return _firestore
        .collection(_collection)
        .where('outingId', isEqualTo: outingId)
        .snapshots()
        .map((snap) => snap.docs.map(_mapSnapshotToWaterRecord).toList());
  }

  /// Mapea un documento de Firestore (`DocumentSnapshot`) a una entidad de dominio `WaterRecord`.
  WaterRecord _mapSnapshotToWaterRecord(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final coord = data['coordinates'] as Map<String, dynamic>? ?? {};

    return WaterRecord(
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
      weatherConditions: data['weatherConditions'] ?? '',
      visibility: data['visibility'] ?? '',
      access: data['access'] ?? '',
      accessFreeText: data['accessFreeText'],
      samplingDepth: data['samplingDepth'] ?? '',
      ph: data['ph']?.toDouble(),
      temperature: data['temperature']?.toDouble(),
      conductivity: data['conductivity']?.toDouble(),
      dissolvedOxygen: data['dissolvedOxygen']?.toDouble(),
      turbidity: data['turbidity']?.toDouble(),
      apparentColor: data['apparentColor'] ?? '',
      odor: data['odor'] ?? '',
      hasSample: data['hasSample'] ?? false,
      sampleId: data['sampleId'],
      sampleType: data['sampleType'],
      container: data['container'],
      samplingGoal: data['samplingGoal'],
      photos: (data['photos'] as List<dynamic>? ?? []).map((p) => Photo(
        id: p['id'] ?? '', filename: p['filename'] ?? '', localPath: p['localPath'] ?? '',
        storageUrl: p['storageUrl'] ?? '', photoType: p['photoType'] ?? '', recordId: p['recordId'] ?? '',
        recordType: p['recordType'] ?? '', syncStatus: 'synced',
      )).toList(),
    );
  }
}
