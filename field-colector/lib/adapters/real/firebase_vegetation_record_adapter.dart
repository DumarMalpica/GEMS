import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/vegetation_record.dart';
import '../../domain/ports/vegetation_record_remote_port.dart';
import '../../domain/entities/photo.dart';
import '../../domain/entities/coordinate.dart';
import '../../domain/entities/plot.dart';
import 'record_photo_sync_helper.dart';

/// Adaptador concreto para operaciones de VegetationRecord en Firestore.
class FirebaseVegetationRecordAdapter implements VegetationRecordRemotePort {
  final FirebaseFirestore _firestore;
  final String _collection = 'vegetation_records';

  FirebaseVegetationRecordAdapter(this._firestore);

  /// Guarda un nuevo registro de VegetationRecord en Firestore y sincroniza sus datos.
  @override
  Future<void> saveVegetationRecord(VegetationRecord item) async {
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
      'speciesId': item.speciesId,
      'speciesFreeText': item.speciesFreeText,
      'commonName': item.commonName,
      'origin': item.origin,
      'vegetationType': item.vegetationType,
      'height': item.height,
      'diameter': item.diameter,
      'diameterType': item.diameterType,
      'canopyLength': item.canopyLength,
      'physiognomy': item.physiognomy,
      'coveragePercent': item.coveragePercent,
      'coverageDistribution': item.coverageDistribution,
      'physicalCondition': item.physicalCondition,
      'hasPyrogeny': item.hasPyrogeny,
      'pyrogenyDescription': item.pyrogenyDescription,
      'groundCover': item.groundCover,
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
        recordType: 'vegetation',
        outingId: item.outingId,
        photos: item.photos,
        firestore: _firestore,
      );
    }
  }

  /// Actualiza un registro existente de VegetationRecord en Firestore con los nuevos datos.
  @override
  Future<void> updateVegetationRecord(String id, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(id).update(data);
  }

  /// Elimina un registro de VegetationRecord en Firestore mediante su id.
  @override
  Future<void> deleteVegetationRecord(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  /// Recupera un registro de [VegetationRecord] por su [id]. Retorna null si no existe.
  @override
  Future<VegetationRecord?> getVegetationRecordById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return _mapSnapshotToVegetationRecord(doc);
  }

  /// Obtiene de forma paginada un listado de registros de vegetación.
  @override
  Future<VegetationRecordSearchResult> getVegetationRecords({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _firestore.collection(_collection).limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();

    return VegetationRecordSearchResult(
      items: snapshot.docs.map((doc) => _mapSnapshotToVegetationRecord(doc)).toList(),
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  /// Consulta todos los registros de vegetación filtrables para exportación a Excel.
  @override
  Future<List<VegetationRecord>> getVegetationRecordsForExport({String? outingId, String? userId, DateTime? startDate, DateTime? endDate}) async {
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
    return snapshot.docs.map((doc) => _mapSnapshotToVegetationRecord(doc)).toList();
  }

  /// Stream para observar en tiempo real los registros de vegetación de una expedición ([outingId]).
  @override
  Stream<List<VegetationRecord>> watchVegetationRecordsByOuting(String outingId) {
    return _firestore
        .collection(_collection)
        .where('outingId', isEqualTo: outingId)
        .snapshots()
        .map((snap) => snap.docs.map(_mapSnapshotToVegetationRecord).toList());
  }

  /// Mapea un documento de Firestore (`DocumentSnapshot`) a una entidad de dominio `VegetationRecord`.
  VegetationRecord _mapSnapshotToVegetationRecord(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final coord = data['coordinates'] as Map<String, dynamic>? ?? {};
    final plotData = data['plot'] as Map<String, dynamic>? ?? {};

    return VegetationRecord(
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
      speciesId: data['speciesId'] ?? '',
      speciesFreeText: data['speciesFreeText'] ?? '',
      commonName: data['commonName'] ?? '',
      origin: data['origin'] ?? '',
      vegetationType: data['vegetationType'] ?? '',
      height: data['height']?.toDouble(),
      diameter: data['diameter']?.toDouble(),
      diameterType: data['diameterType'],
      canopyLength: data['canopyLength']?.toDouble(),
      physiognomy: data['physiognomy'] ?? '',
      coveragePercent: data['coveragePercent'] as int?,
      coverageDistribution: data['coverageDistribution'],
      physicalCondition: data['physicalCondition'] ?? '',
      hasPyrogeny: data['hasPyrogeny'] ?? false,
      pyrogenyDescription: data['pyrogenyDescription'],
      groundCover: data['groundCover'] ?? '',
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
