import 'dart:convert';

import 'package:isar/isar.dart';
import '../../domain/entities/outing.dart';

part 'outing_model.g.dart';

/// Modelo embebido para persistir [OutingMember] dentro de [OutingModel].
@embedded
class OutingMemberModel {
  String id = '';
  String name = '';
  String email = '';

  OutingMember toDomain() => OutingMember(id: id, name: name, email: email);

  static OutingMemberModel fromDomain(OutingMember m) => OutingMemberModel()
    ..id = m.id
    ..name = m.name
    ..email = m.email;
}

/// Alias para compatibilidad con código que referencia PendingUserModel.
typedef PendingUserModel = OutingMemberModel;

/// Modelo de persistencia Isar para [Outing].
@Collection()
class OutingModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String outingId;

  late String prefix;
  late String name;
  late String location;
  late String zone;
  late String reason;
  // Kept for the current Isar schema. New place data is encoded in location.
  late double latitude;
  late double longitude;
  late double altitude;
  late DateTime startDate;
  late DateTime endDate;
  late String createdById;
  late List<String> participantIds;
  late String status;
  late String syncStatus;
  late List<OutingMemberModel> participants;
  late List<OutingMemberModel> pendingUsers;

  Outing toDomain() {
    Map<String, dynamic>? envelope;
    try {
      final decoded = jsonDecode(location);
      if (decoded is Map<String, dynamic> && decoded['places'] is List) {
        envelope = decoded;
      }
    } catch (_) {}

    final places = envelope == null
        ? [
            OutingPlace(
              id: 'legacy-place',
              name: location,
              latitude: latitude,
              longitude: longitude,
              altitude: altitude,
            ),
          ]
        : (envelope['places'] as List)
            .map((place) => OutingPlace.fromMap(
                  Map<String, dynamic>.from(place),
                ))
            .toList();

    return Outing(
        id: outingId,
        prefix: prefix,
        name: name,
        location: envelope?['location'] as String? ?? location,
        zone: zone,
        reason: reason,
        places: places,
        startDate: startDate,
        endDate: endDate,
        createdById: createdById,
        participantIds: List<String>.from(participantIds),
        status: status,
        syncStatus: syncStatus,
        participants: participants.map((m) => m.toDomain()).toList(),
        pendingUsers: pendingUsers.map((m) => m.toDomain()).toList(),
      );
  }

  static OutingModel fromDomain(Outing o) => OutingModel()
    ..outingId = o.id
    ..prefix = o.prefix
    ..name = o.name
    ..location = jsonEncode({
      'location': o.location,
      'places': o.places.map((place) => place.toMap()).toList(),
    })
    ..zone = o.zone
    ..reason = o.reason
    ..latitude = o.places.isEmpty ? 0 : o.places.first.latitude
    ..longitude = o.places.isEmpty ? 0 : o.places.first.longitude
    ..altitude = o.places.isEmpty ? 0 : o.places.first.altitude
    ..startDate = o.startDate
    ..endDate = o.endDate
    ..createdById = o.createdById
    ..participantIds = List<String>.from(o.participantIds)
    ..status = o.status
    ..syncStatus = o.syncStatus
    ..participants = o.participants.map(OutingMemberModel.fromDomain).toList()
    ..pendingUsers = o.pendingUsers.map(OutingMemberModel.fromDomain).toList();
}
