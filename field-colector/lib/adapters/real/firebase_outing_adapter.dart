import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/outing.dart';
import '../../domain/ports/outing_remote_port.dart';

/// Adaptador concreto para operaciones de Outing en Firestore.
class FirebaseOutingAdapter implements OutingRemotePort {
  final FirebaseFirestore _firestore;
  final String _collection = 'outings';

  FirebaseOutingAdapter(this._firestore);

  /// Guarda un nuevo registro de Outing en Firestore y sincroniza sus datos.
  @override
  Future<void> saveOuting(Outing item) async {
    await _firestore.collection(_collection).doc(item.id).set({
      'prefix': item.prefix,
      'name': item.name,
      'location': item.location,
      'zone': item.zone,
      'reason': item.reason,
      'latitude': item.latitude,
      'longitude': item.longitude,
      'altitude': item.altitude,
      'startDate': item.startDate.toIso8601String(),
      'endDate': item.endDate.toIso8601String(),
      'createdById': item.createdById,
      'participantIds': item.participantIds,
      'participants': item.participants.map((u) => u.toMap()).toList(),
      'status': item.status,
      'pendingUsers': item.pendingUsers.map((u) => u.toMap()).toList(),
    });
  }

  /// Actualiza un registro existente de Outing en Firestore con los nuevos datos.
  @override
  Future<void> updateOuting(String id, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(id).update(data);
  }

  /// Elimina un registro de Outing en Firestore mediante su id.
  @override
  Future<void> deleteOuting(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  /// Recupera un registro de [Outing] por su [id]. Retorna null si no existe.
  @override
  Future<Outing?> getOutingById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return _mapSnapshotToOuting(doc);
  }

  /// Obtiene de forma paginada un listado de expediciones.
  @override
  Future<OutingSearchResult> getOutings({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _firestore.collection(_collection).limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();

    return OutingSearchResult(
      items: snapshot.docs.map((doc) => _mapSnapshotToOuting(doc)).toList(),
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  /// Obtiene de forma paginada expediciones creadas por un usuario específico ([userId]).
  @override
  Future<OutingSearchResult> getOutingsByCreatorId(String userId, {
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _firestore.collection(_collection)
        .where('createdById', isEqualTo: userId)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();

    return OutingSearchResult(
      items: snapshot.docs.map((doc) => _mapSnapshotToOuting(doc)).toList(),
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  /// Obtiene de forma paginada expediciones en las que un usuario ([userId]) participa.
  @override
  Future<OutingSearchResult> getOutingsByParticipantId(
    String userId, {
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _firestore
        .collection(_collection)
        .where('participantIds', arrayContains: userId)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();

    return OutingSearchResult(
      items: snapshot.docs.map((doc) => _mapSnapshotToOuting(doc)).toList(),
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  List<OutingMember> _parseMembers(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map((e) => OutingMember.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Mapea un documento de Firestore (`DocumentSnapshot`) a una entidad de dominio `Outing`.
  Outing _mapSnapshotToOuting(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Outing(
      id: doc.id,
      prefix: data['prefix'] ?? '',
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      zone: data['zone'] ?? '',
      reason: data['reason'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      altitude: (data['altitude'] as num?)?.toDouble() ?? 0.0,
      startDate: data['startDate'] != null ? DateTime.parse(data['startDate']) : DateTime.now(),
      endDate: data['endDate'] != null ? DateTime.parse(data['endDate']) : DateTime.now(),
      createdById: data['createdById'] ?? '',
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participants: _parseMembers(data['participants']),
      status: data['status'] ?? 'active',
      syncStatus: 'synced',
      pendingUsers: _parseMembers(data['pendingUsers']),
    );
  }

  /// Añade un usuario pendiente de confirmación a una salida.
  @override
  Future<void> addPendingUserToOuting(String outingId, PendingUser user) async {
    await _firestore.collection(_collection).doc(outingId).update({
      'pendingUsers': FieldValue.arrayUnion([user.toMap()]),
    });
  }

  /// Elimina un usuario pendiente de confirmación de una salida.
  @override
  Future<void> removePendingUserFromOuting(String outingId, String userId) async {
    final doc = await _firestore.collection(_collection).doc(outingId).get();
    if (!doc.exists) return;
    
    final data = doc.data();
    if (data == null) return;
    
    final pendingList = List<dynamic>.from(data['pendingUsers'] ?? []);
    pendingList.removeWhere((e) => e is Map && e['id'] == userId);
    
    await _firestore.collection(_collection).doc(outingId).update({
      'pendingUsers': pendingList,
    });
  }

  /// Obtiene la lista de usuarios pendientes (invitados sin confirmar) de una salida.
  @override
  Future<List<PendingUser>> getPendingUsersByOutingId(String outingId) async {
    final doc = await _firestore.collection(_collection).doc(outingId).get();
    if (!doc.exists) return [];
    
    final data = doc.data();
    if (data == null) return [];
    
    return (data['pendingUsers'] as List<dynamic>?)
        ?.map((e) => PendingUser.fromMap(e as Map<String, dynamic>))
        .toList() ?? [];
  }
}
