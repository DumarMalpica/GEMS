import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/coordinate.dart';
import '../../domain/entities/photo.dart';
import '../../domain/entities/social_record.dart';
import '../../domain/ports/social_record_remote_port.dart';
import 'record_photo_sync_helper.dart';

/// Adaptador concreto para operaciones de SocialRecord en Firestore.
class FirebaseSocialRecordAdapter implements SocialRecordRemotePort {
  final FirebaseFirestore _firestore;
  final String _collection = 'social_records';

  FirebaseSocialRecordAdapter(this._firestore);

  /// Guarda un nuevo registro de SocialRecord en Firestore y sincroniza sus datos.
  @override
  Future<void> saveSocialRecord(SocialRecord item) async {
    await _firestore.collection(_collection).doc(item.id).set(_toFirestore(item));

    if (item.photos.isNotEmpty) {
      await RecordPhotoSyncHelper.uploadAndSyncPhotos(
        recordId: item.id,
        recordType: 'social',
        outingId: item.outingId,
        photos: item.photos,
        firestore: _firestore,
      );
    }
  }

  /// Actualiza un registro existente de SocialRecord en Firestore con los nuevos datos.
  @override
  Future<void> updateSocialRecord(String id, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(id).update(data);
  }

  /// Elimina un registro de SocialRecord en Firestore mediante su id.
  @override
  Future<void> deleteSocialRecord(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  /// Recupera un registro de [SocialRecord] por su [id]. Retorna null si no existe.
  @override
  Future<SocialRecord?> getSocialRecordById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return _mapSnapshotToSocialRecord(doc);
  }

  /// Obtiene de forma paginada un listado de registros sociales (encuestas).
  @override
  Future<SocialRecordSearchResult> getSocialRecords({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _firestore.collection(_collection).limit(limit);
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }
    final snapshot = await query.get();
    return SocialRecordSearchResult(
      items: snapshot.docs.map(_mapSnapshotToSocialRecord).toList(),
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  /// Consulta todos los registros sociales filtrables para exportación a Excel.
  @override
  Future<List<SocialRecord>> getSocialRecordsForExport({
    String? outingId,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = _firestore.collection(_collection);
    if (outingId != null) {
      query = query.where('outingId', isEqualTo: outingId);
    } else if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    if (startDate != null) {
      query = query.where(
        'recordedAt',
        isGreaterThanOrEqualTo: startDate.toIso8601String(),
      );
    }
    if (endDate != null) {
      query = query.where(
        'recordedAt',
        isLessThanOrEqualTo: endDate.toIso8601String(),
      );
    }
    final snapshot = await query.get();
    return snapshot.docs.map(_mapSnapshotToSocialRecord).toList();
  }

  /// Stream para observar en tiempo real los registros sociales de una expedición ([outingId]).
  @override
  Stream<List<SocialRecord>> watchSocialRecordsByOuting(String outingId) {
    return _firestore
        .collection(_collection)
        .where('outingId', isEqualTo: outingId)
        .snapshots()
        .map((snap) => snap.docs.map(_mapSnapshotToSocialRecord).toList());
  }

  Map<String, dynamic> _toFirestore(SocialRecord item) => {
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
        'respondentId': item.respondentId,
        'actorName': item.actorName,
        'actorType': item.actorType,
        'age': item.age,
        'gender': item.gender,
        'educationLevel': item.educationLevel,
        'mainActivity': item.mainActivity,
        'timeInTerritory': item.timeInTerritory,
        'locationMunicipality': item.locationMunicipality,
        'locationVillage': item.locationVillage,
        'naturalResourceDependency': item.naturalResourceDependency,
        'coverageChangePerception': item.coverageChangePerception,
        'observedChangeType': item.observedChangeType,
        'organizationParticipation': item.organizationParticipation,
        'organizationName': item.organizationName,
        'actorInteractionFrequency': item.actorInteractionFrequency,
        'connectedKeyActors': item.connectedKeyActors,
        'relationshipType': item.relationshipType,
        'trustLevel': item.trustLevel,
        'environmentalInfoAccess': item.environmentalInfoAccess,
        'technologyUse': item.technologyUse,
        'territorialConnectivity': item.territorialConnectivity,
        'fragmentationPerception': item.fragmentationPerception,
        'productivePracticeChanges': item.productivePracticeChanges,
        'practiceType': item.practiceType,
        'perceivedLandscapeImpact': item.perceivedLandscapeImpact,
        'observations': item.observations,
        'photos': item.photos
            .map(
              (p) => {
                'id': p.id,
                'filename': p.filename,
                'localPath': p.localPath,
                'storageUrl': p.storageUrl,
                'photoType': p.photoType,
                'recordId': p.recordId,
                'recordType': p.recordType,
                'syncStatus': p.syncStatus,
              },
            )
            .toList(),
      };

  /// Mapea un documento de Firestore (`DocumentSnapshot`) a una entidad de dominio `SocialRecord`.
  SocialRecord _mapSnapshotToSocialRecord(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final coord = data['coordinates'] as Map<String, dynamic>? ?? {};
    return SocialRecord(
      id: doc.id,
      outingId: data['outingId'] ?? '',
      userId: data['userId'] ?? '',
      recordedAt: data['recordedAt'] != null
          ? DateTime.parse(data['recordedAt'])
          : DateTime.now(),
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
      respondentId: data['respondentId'] ?? '',
      actorName: data['actorName'] ?? '',
      actorType: data['actorType'] ?? '',
      age: (data['age'] ?? 0.0).toDouble(),
      gender: data['gender'] ?? '',
      educationLevel: data['educationLevel'] ?? '',
      mainActivity: data['mainActivity'] ?? '',
      timeInTerritory: (data['timeInTerritory'] ?? 0.0).toDouble(),
      locationMunicipality: data['locationMunicipality'],
      locationVillage: data['locationVillage'],
      naturalResourceDependency: data['naturalResourceDependency'] ?? '',
      coverageChangePerception: data['coverageChangePerception'] ?? '',
      observedChangeType: data['observedChangeType'],
      organizationParticipation: data['organizationParticipation'] ?? '',
      organizationName: data['organizationName'],
      actorInteractionFrequency: data['actorInteractionFrequency'] ?? '',
      connectedKeyActors: data['connectedKeyActors'],
      relationshipType: data['relationshipType'] ?? '',
      trustLevel: data['trustLevel'] ?? '',
      environmentalInfoAccess: data['environmentalInfoAccess'] ?? '',
      technologyUse: data['technologyUse'],
      territorialConnectivity: data['territorialConnectivity'] ?? '',
      fragmentationPerception: data['fragmentationPerception'] ?? '',
      productivePracticeChanges: data['productivePracticeChanges'] ?? '',
      practiceType: data['practiceType'],
      perceivedLandscapeImpact: data['perceivedLandscapeImpact'] ?? '',
      observations: data['observations'],
      photos: (data['photos'] as List<dynamic>? ?? [])
          .map(
            (p) => Photo(
              id: p['id'] ?? '',
              filename: p['filename'] ?? '',
              localPath: p['localPath'] ?? '',
              storageUrl: p['storageUrl'] ?? '',
              photoType: p['photoType'] ?? '',
              recordId: p['recordId'] ?? '',
              recordType: p['recordType'] ?? '',
              syncStatus: p['syncStatus'] ?? 'synced',
            ),
          )
          .toList(),
    );
  }
}
