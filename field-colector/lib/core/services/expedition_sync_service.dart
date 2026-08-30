import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:field_colector/domain/entities/outing.dart';
import 'package:field_colector/domain/ports/network_reachability.dart';
import 'package:field_colector/domain/ports/outing_local_port.dart';
import 'package:field_colector/domain/ports/outing_remote_port.dart';

/// Descarga expediciones de Firestore y las persiste en Isar (pull).
class ExpeditionSyncService {
  ExpeditionSyncService({
    required OutingLocalPort outingLocal,
    required OutingRemotePort outingRemote,
    required NetworkReachability reachability,
    this.pageSize = 50,
  })  : _outingLocal = outingLocal,
        _outingRemote = outingRemote,
        _reachability = reachability;

  final OutingLocalPort _outingLocal;
  final OutingRemotePort _outingRemote;
  final NetworkReachability _reachability;
  final int pageSize;

  Completer<int>? _activeSyncCompleter;

  /// Descarga todas las expediciones de Firestore a Isar (para listar y solicitar unión).
  /// Si ya hay un sync en curso, espera a que termine y devuelve su resultado.
  Future<int> syncExpeditionsForUser(String userId) async {
    if (userId.isEmpty) {
      debugPrint('[ExpeditionSync] userId empty, skipping');
      return 0;
    }
    if (!await _reachability.hasConnectivityNow()) {
      debugPrint('[ExpeditionSync] offline, skipping');
      return 0;
    }

    if (_activeSyncCompleter != null) {
      return _activeSyncCompleter!.future;
    }

    _activeSyncCompleter = Completer<int>();
    try {
      final result = await _doSync(userId);
      _activeSyncCompleter!.complete(result);
      return result;
    } catch (e, stack) {
      debugPrint('[ExpeditionSync] ERROR: $e');
      developer.log(
        'ExpeditionSyncService.syncExpeditionsForUser failed',
        name: 'ExpeditionSync',
        error: e,
        stackTrace: stack,
      );
      _activeSyncCompleter!.complete(0);
      return 0;
    } finally {
      _activeSyncCompleter = null;
    }
  }

  /// Descarga una expedición concreta desde Firestore (detalle / pull-to-refresh).
  Future<bool> syncOutingById(String outingId) async {
    if (outingId.isEmpty) {
      debugPrint('[ExpeditionSync] outingId empty, skipping');
      return false;
    }
    if (!await _reachability.hasConnectivityNow()) {
      debugPrint('[ExpeditionSync] offline, skipping');
      return false;
    }

    try {
      final remote = await _outingRemote.getOutingById(outingId);
      if (remote == null) return false;
      return await _upsertRemoteOuting(remote);
    } catch (e, stack) {
      debugPrint('[ExpeditionSync] syncOutingById ERROR: $e');
      developer.log(
        'ExpeditionSyncService.syncOutingById failed',
        name: 'ExpeditionSync',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  Future<int> _doSync(String userId) async {
    final remoteOutings = <String, Outing>{};

    for (final outing in await _fetchAllOutings()) {
      remoteOutings[outing.id] = outing;
    }

    debugPrint(
      '[ExpeditionSync] Fetched ${remoteOutings.length} remote outings (triggered by user $userId)',
    );

    var upserted = 0;
    for (final outing in remoteOutings.values) {
      if (await _upsertRemoteOuting(outing)) upserted++;
    }
    return upserted;
  }

  Future<List<Outing>> _fetchAllOutings() async {
    final all = <Outing>[];
    DocumentSnapshot? last;

    while (true) {
      final page = await _outingRemote.getOutings(
        limit: pageSize,
        lastDocument: last,
      );
      if (page.items.isEmpty) break;
      all.addAll(page.items);
      final next = page.lastDocument;
      if (next == null || page.items.length < pageSize) break;
      last = next;
    }

    return all;
  }

  Future<bool> _upsertRemoteOuting(Outing remote) async {
    final local = await _outingLocal.getOutingById(remote.id);
    if (local != null) {
      if (local.syncStatus == 'pending' || local.syncStatus == 'error') {
        return false;
      }
      if (_outingContentEquals(local, remote)) return false;
    }

    await _outingLocal.saveOuting(
      Outing(
        id: remote.id,
        prefix: remote.prefix,
        name: remote.name,
        location: remote.location,
        zone: remote.zone,
        reason: remote.reason,
        places: remote.places,
        startDate: remote.startDate,
        endDate: remote.endDate,
        createdById: remote.createdById,
        participantIds: remote.participantIds,
        status: remote.status,
        syncStatus: 'synced',
        participants: remote.participants,
        pendingUsers: remote.pendingUsers,
      ),
    );
    return true;
  }

  bool _outingContentEquals(Outing a, Outing b) {
    return a.prefix == b.prefix &&
        a.name == b.name &&
        a.location == b.location &&
        a.zone == b.zone &&
        a.reason == b.reason &&
        _placesEqual(a.places, b.places) &&
        a.startDate == b.startDate &&
        a.endDate == b.endDate &&
        a.createdById == b.createdById &&
        _listEquals(a.participantIds, b.participantIds) &&
        a.status == b.status &&
        a.participants.length == b.participants.length &&
        a.pendingUsers.length == b.pendingUsers.length;
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _placesEqual(List<OutingPlace> a, List<OutingPlace> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final left = a[i];
      final right = b[i];
      if (left.id != right.id ||
          left.name != right.name ||
          left.latitude != right.latitude ||
          left.longitude != right.longitude ||
          left.altitude != right.altitude) {
        return false;
      }
    }
    return true;
  }
}
