// ignore_for_file: experimental_member_use
import 'dart:convert';

import 'package:isar/isar.dart';
import '../../domain/entities/outing.dart';
import '../../domain/ports/outing_local_port.dart';
import '../../core/database/isar_service.dart';
import 'outing_model.dart';

class IsarOutingAdapter implements OutingLocalPort {
  @override
  Future<void> saveOuting(Outing outing) async {
    final isar = await IsarService.getInstance();
    final model = OutingModel.fromDomain(outing);
    await isar.writeTxn(() async {
      await isar.outingModels.putByOutingId(model);
    });
  }

  @override
  Future<Outing?> getOutingById(String firebaseId) async {
    final isar = await IsarService.getInstance();
    final query = isar.outingModels.buildQuery<OutingModel>(
      filter: FilterCondition.equalTo(property: 'outingId', value: firebaseId),
      limit: 1,
    );
    final results = await query.findAll();
    if (results.isEmpty) return null;
    return results.first.toDomain();
  }

  @override
  Future<List<Outing>> getAllOutings() async {
    final isar = await IsarService.getInstance();
    final results = await isar.outingModels.buildQuery<OutingModel>().findAll();
    return results.map((m) => m.toDomain()).toList();
  }

  @override
  Future<void> updateOuting(String id, Map<String, dynamic> data) async {
    final isar = await IsarService.getInstance();
    final query = isar.outingModels.buildQuery<OutingModel>(
      filter: FilterCondition.equalTo(property: 'outingId', value: id),
      limit: 1,
    );
    final results = await query.findAll();
    if (results.isEmpty) return;
    final model = results.first;
    if (data.containsKey('prefix')) model.prefix = data['prefix'] as String;
    if (data.containsKey('name')) model.name = data['name'] as String;
    if (data.containsKey('location')) {
      final places = model.toDomain().places;
      model.location = jsonEncode({
        'location': data['location'] as String,
        'places': places.map((place) => place.toMap()).toList(),
      });
    }
    if (data.containsKey('zone')) model.zone = data['zone'] as String;
    if (data.containsKey('reason')) model.reason = data['reason'] as String;
    if (data.containsKey('places')) {
      final places = (data['places'] as List)
          .map((place) => place is OutingPlace
              ? place
              : OutingPlace.fromMap(Map<String, dynamic>.from(place as Map)))
          .toList();
      final currentLocation = model.toDomain().location;
      model.location = jsonEncode({
        'location': currentLocation,
        'places': places.map((place) => place.toMap()).toList(),
      });
      model.latitude = places.isEmpty ? 0 : places.first.latitude;
      model.longitude = places.isEmpty ? 0 : places.first.longitude;
      model.altitude = places.isEmpty ? 0 : places.first.altitude;
    }
    if (data.containsKey('latitude')) model.latitude = (data['latitude'] as num).toDouble();
    if (data.containsKey('longitude')) model.longitude = (data['longitude'] as num).toDouble();
    if (data.containsKey('altitude')) model.altitude = (data['altitude'] as num).toDouble();
    if (data.containsKey('startDate')) model.startDate = data['startDate'] as DateTime;
    if (data.containsKey('endDate')) model.endDate = data['endDate'] as DateTime;
    if (data.containsKey('createdById')) model.createdById = data['createdById'] as String;
    if (data.containsKey('participantIds')) {
      model.participantIds = List<String>.from(data['participantIds'] as List);
    }
    if (data.containsKey('participants')) {
      final list = data['participants'] as List;
      model.participants = list
          .map((e) => OutingMemberModel.fromDomain(
                e is OutingMember
                    ? e
                    : OutingMember.fromMap(e as Map<String, dynamic>),
              ))
          .toList();
    }
    if (data.containsKey('status')) model.status = data['status'] as String;
    if (data.containsKey('syncStatus')) model.syncStatus = data['syncStatus'] as String;
    await isar.writeTxn(() async {
      await isar.outingModels.put(model);
    });
  }

  @override
  Future<void> deleteOuting(String firebaseId) async {
    final isar = await IsarService.getInstance();
    await isar.writeTxn(() async {
      await isar.outingModels.deleteByOutingId(firebaseId);
    });
  }

  @override
  Future<void> clearAll() async {
    final isar = await IsarService.getInstance();
    await isar.writeTxn(() async {
      await isar.outingModels.clear();
    });
  }

  @override
  Future<List<Outing>> getOutingsByStatus(String status) async {
    final isar = await IsarService.getInstance();
    final query = isar.outingModels.buildQuery<OutingModel>(
      filter: FilterCondition.equalTo(property: 'status', value: status),
    );
    final results = await query.findAll();
    return results.map((m) => m.toDomain()).toList();
  }

  @override
  Future<List<Outing>> getOutingsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final isar = await IsarService.getInstance();
    final query = isar.outingModels.buildQuery<OutingModel>(
      filter: FilterCondition.between(
        property: 'startDate',
        lower: startDate,
        upper: endDate,
      ),
    );
    final results = await query.findAll();
    return results.map((m) => m.toDomain()).toList();
  }

  @override
  Future<List<Outing>> getOutingsByCreator(String userId) async {
    final isar = await IsarService.getInstance();
    final query = isar.outingModels.buildQuery<OutingModel>(
      filter: FilterCondition.equalTo(property: 'createdById', value: userId),
    );
    final results = await query.findAll();
    return results.map((m) => m.toDomain()).toList();
  }

  @override
  Future<List<Outing>> getOutingsByParticipant(String userId) async {
    final all = await getAllOutings();
    return all.where((o) => o.participantIds.contains(userId)).toList();
  }

  @override
  Future<void> addPendingUserToOuting(
    String outingId,
    PendingUser user,
  ) async {
    final isar = await IsarService.getInstance();
    final query = isar.outingModels.buildQuery<OutingModel>(
      filter: FilterCondition.equalTo(property: 'outingId', value: outingId),
      limit: 1,
    );
    final results = await query.findAll();
    if (results.isEmpty) return;
    final model = results.first;
    final alreadyExists = model.pendingUsers.any((m) => m.id == user.id);
    if (alreadyExists) return;
    model.pendingUsers = [...model.pendingUsers, PendingUserModel.fromDomain(user)];
    await isar.writeTxn(() async {
      await isar.outingModels.put(model);
    });
  }

  @override
  Future<void> removePendingUserFromOuting(
    String outingId,
    String userId,
  ) async {
    final isar = await IsarService.getInstance();
    final query = isar.outingModels.buildQuery<OutingModel>(
      filter: FilterCondition.equalTo(property: 'outingId', value: outingId),
      limit: 1,
    );
    final results = await query.findAll();
    if (results.isEmpty) return;
    final model = results.first;
    model.pendingUsers =
        model.pendingUsers.where((m) => m.id != userId).toList();
    await isar.writeTxn(() async {
      await isar.outingModels.put(model);
    });
  }

  @override
  Future<List<PendingUser>> getPendingUsersByOutingId(String outingId) async {
    final isar = await IsarService.getInstance();
    final query = isar.outingModels.buildQuery<OutingModel>(
      filter: FilterCondition.equalTo(property: 'outingId', value: outingId),
      limit: 1,
    );
    final results = await query.findAll();
    if (results.isEmpty) return [];
    return results.first.pendingUsers.map((m) => m.toDomain()).toList();
  }

  @override
  Future<List<Outing>> getPendingSyncOutings() async {
    final isar = await IsarService.getInstance();
    final query = isar.outingModels.buildQuery<OutingModel>(
      filter: FilterGroup.or([
        FilterCondition.equalTo(property: 'syncStatus', value: 'pending'),
        FilterCondition.equalTo(property: 'syncStatus', value: 'error'),
      ]),
    );
    final results = await query.findAll();
    return results.map((m) => m.toDomain()).toList();
  }

  @override
  Future<void> updateSyncStatus(String firebaseId, String syncStatus) async {
    final isar = await IsarService.getInstance();
    final query = isar.outingModels.buildQuery<OutingModel>(
      filter: FilterCondition.equalTo(property: 'outingId', value: firebaseId),
      limit: 1,
    );
    final results = await query.findAll();
    if (results.isEmpty) return;
    final model = results.first..syncStatus = syncStatus;
    await isar.writeTxn(() async {
      await isar.outingModels.put(model);
    });
  }

  @override
  Future<void> updateFirebaseId(int localIsarId, String firebaseId) async {
    final isar = await IsarService.getInstance();
    final model = await isar.outingModels.get(localIsarId);
    if (model == null) return;
    model.outingId = firebaseId;
    await isar.writeTxn(() async {
      await isar.outingModels.put(model);
    });
  }
}
