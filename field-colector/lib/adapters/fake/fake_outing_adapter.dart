import '../../domain/entities/outing.dart';
import '../../domain/ports/outing_local_port.dart';

class FakeOutingAdapter implements OutingLocalPort {
  int _nextId = _seed.length + 1;
  final Map<int, Outing> _storeById = {
    for (var i = 0; i < _seed.length; i++) i + 1: _seed[i],
  };

  static final List<Outing> _seed = [
    Outing(
      id: 'fake-outing-001',
      prefix: 'CIT-PAR',
      name: 'Muestreo Páramo de Ocetá',
      location: 'Monguí, Boyacá',
      zone: 'Páramo',
      reason: 'Inventario de flora paramuna',
      places: const [OutingPlace(id: 'place-001', name: 'Páramo de Ocetá', latitude: 5.7167, longitude: -72.9000, altitude: 3800)],
      startDate: DateTime(2025, 6, 10),
      endDate: DateTime(2025, 6, 17),
      createdById: 'fake-uid-001',
      participantIds: ['fake-uid-001', 'fake-uid-002'],
      participants: [
        const OutingMember(
          id: 'fake-uid-001',
          name: 'Ana García',
          email: 'ana@citeza.test',
        ),
        const OutingMember(
          id: 'fake-uid-002',
          name: 'Carlos Ruiz',
          email: 'carlos@citeza.test',
        ),
      ],
      status: 'active',
      syncStatus: 'synced',
    ),
    Outing(
      id: 'fake-outing-002',
      prefix: 'CIT-AGU',
      name: 'Caracterización Río Chicamocha',
      location: 'Socha, Boyacá',
      zone: 'Cuenca hídrica',
      reason: 'Análisis fisicoquímico de calidad de agua',
      places: const [OutingPlace(id: 'place-002', name: 'Río Chicamocha', latitude: 5.9611, longitude: -72.6880, altitude: 1200)],
      startDate: DateTime(2025, 8, 5),
      endDate: DateTime(2025, 8, 8),
      createdById: 'fake-uid-002',
      participantIds: ['fake-uid-002'],
      participants: [
        const OutingMember(
          id: 'fake-uid-002',
          name: 'Carlos Ruiz',
          email: 'carlos@citeza.test',
        ),
      ],
      status: 'active',
      syncStatus: 'synced',
    ),
    Outing(
      id: 'fake-outing-003',
      prefix: 'CIT-GEO',
      name: 'Estudio Geológico Cañón del Chicamocha',
      location: 'Santander',
      zone: 'Zona de falla geológica',
      reason: 'Identificación de formaciones rocosas',
      places: const [OutingPlace(id: 'place-003', name: 'Cañón del Chicamocha', latitude: 6.5750, longitude: -72.9083, altitude: 900)],
      startDate: DateTime(2025, 3, 1),
      endDate: DateTime(2025, 3, 5),
      createdById: 'fake-uid-001',
      participantIds: ['fake-uid-001'],
      participants: [
        const OutingMember(
          id: 'fake-uid-001',
          name: 'Ana García',
          email: 'ana@citeza.test',
        ),
      ],
      status: 'closed',
      syncStatus: 'pending',
    ),
  ];

  List<Outing> get _store => _storeById.values.toList();

  @override
  Future<void> saveOuting(Outing outing) async {
    final entry =
        _storeById.entries.where((e) => e.value.id == outing.id).firstOrNull;
    if (entry != null) {
      _storeById[entry.key] = outing;
    } else {
      _storeById[_nextId++] = outing;
    }
  }

  @override
  Future<Outing?> getOutingById(String firebaseId) async {
    try {
      return _store.firstWhere((o) => o.id == firebaseId);
    } on StateError {
      return null;
    }
  }

  @override
  Future<List<Outing>> getAllOutings() async => List.unmodifiable(_store);

  @override
  Future<void> updateOuting(String id, Map<String, dynamic> data) async {
    final entry =
        _storeById.entries.where((e) => e.value.id == id).firstOrNull;
    if (entry == null) return;
    final o = entry.value;
    _storeById[entry.key] = Outing(
      id: o.id,
      prefix: data['prefix'] as String? ?? o.prefix,
      name: data['name'] as String? ?? o.name,
      location: data['location'] as String? ?? o.location,
      zone: data['zone'] as String? ?? o.zone,
      reason: data['reason'] as String? ?? o.reason,
      places: data['places'] != null
          ? (data['places'] as List).map((e) => e is OutingPlace
              ? e
              : OutingPlace.fromMap(Map<String, dynamic>.from(e as Map))).toList()
          : o.places,
      startDate: data['startDate'] as DateTime? ?? o.startDate,
      endDate: data['endDate'] as DateTime? ?? o.endDate,
      createdById: data['createdById'] as String? ?? o.createdById,
      participantIds: data['participantIds'] != null
          ? List<String>.from(data['participantIds'] as List)
          : o.participantIds,
      participants: data['participants'] != null
          ? (data['participants'] as List)
              .map((e) => e is OutingMember
                  ? e
                  : OutingMember.fromMap(e as Map<String, dynamic>))
              .toList()
          : o.participants,
      status: data['status'] as String? ?? o.status,
      syncStatus: data['syncStatus'] as String? ?? o.syncStatus,
      pendingUsers: o.pendingUsers,
    );
  }

  @override
  Future<void> deleteOuting(String firebaseId) async {
    _storeById.removeWhere((_, o) => o.id == firebaseId);
  }

  @override
  Future<void> clearAll() async => _storeById.clear();

  @override
  Future<List<Outing>> getOutingsByStatus(String status) async =>
      _store.where((o) => o.status == status).toList();

  @override
  Future<List<Outing>> getOutingsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async =>
      _store
          .where((o) =>
              !o.startDate.isBefore(startDate) &&
              !o.startDate.isAfter(endDate))
          .toList();

  @override
  Future<List<Outing>> getOutingsByCreator(String userId) async =>
      _store.where((o) => o.createdById == userId).toList();

  @override
  Future<List<Outing>> getOutingsByParticipant(String userId) async =>
      _store.where((o) => o.participantIds.contains(userId)).toList();

  @override
  Future<void> addPendingUserToOuting(
    String outingId,
    PendingUser user,
  ) async {
    final entry =
        _storeById.entries.where((e) => e.value.id == outingId).firstOrNull;
    if (entry == null) return;
    final o = entry.value;
    if (o.pendingUsers.any((u) => u.id == user.id)) return;
    _storeById[entry.key] = _rebuildPendingUsers(
      o,
      pendingUsers: [...o.pendingUsers, user],
    );
  }

  @override
  Future<void> removePendingUserFromOuting(
    String outingId,
    String userId,
  ) async {
    final entry =
        _storeById.entries.where((e) => e.value.id == outingId).firstOrNull;
    if (entry == null) return;
    final o = entry.value;
    _storeById[entry.key] = _rebuildPendingUsers(
      o,
      pendingUsers: o.pendingUsers.where((u) => u.id != userId).toList(),
    );
  }

  @override
  Future<List<PendingUser>> getPendingUsersByOutingId(String outingId) async {
    final o = _store.where((o) => o.id == outingId).firstOrNull;
    return o?.pendingUsers ?? [];
  }

  @override
  Future<List<Outing>> getPendingSyncOutings() async =>
      _store.where((o) => o.syncStatus == 'pending').toList();

  @override
  Future<void> updateSyncStatus(String firebaseId, String syncStatus) async {
    final entry =
        _storeById.entries.where((e) => e.value.id == firebaseId).firstOrNull;
    if (entry == null) return;
    final o = entry.value;
    _storeById[entry.key] = _rebuildStatus(o, syncStatus: syncStatus);
  }

  @override
  Future<void> updateFirebaseId(int localIsarId, String firebaseId) async {
    final o = _storeById[localIsarId];
    if (o == null) return;
    _storeById[localIsarId] = _rebuildStatus(o, id: firebaseId);
  }

  Outing _rebuildStatus(Outing o, {String? id, String? status, String? syncStatus}) =>
      Outing(
        id: id ?? o.id,
        prefix: o.prefix,
        name: o.name,
        location: o.location,
        zone: o.zone,
        reason: o.reason,
         places: o.places,
        startDate: o.startDate,
        endDate: o.endDate,
        createdById: o.createdById,
        participantIds: o.participantIds,
        participants: o.participants,
        status: status ?? o.status,
        syncStatus: syncStatus ?? o.syncStatus,
        pendingUsers: o.pendingUsers,
      );

  Outing _rebuildPendingUsers(Outing o, {required List<PendingUser> pendingUsers}) =>
      Outing(
        id: o.id,
        prefix: o.prefix,
        name: o.name,
        location: o.location,
        zone: o.zone,
        reason: o.reason,
         places: o.places,
        startDate: o.startDate,
        endDate: o.endDate,
        createdById: o.createdById,
        participantIds: o.participantIds,
        participants: o.participants,
        status: o.status,
        syncStatus: o.syncStatus,
        pendingUsers: pendingUsers,
      );
}
