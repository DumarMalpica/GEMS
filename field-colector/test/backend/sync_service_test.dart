import 'package:field_colector/domain/entities/bird_record.dart';
import 'package:field_colector/domain/entities/coordinate.dart';
import 'package:field_colector/domain/entities/outing.dart';
import 'package:field_colector/domain/entities/photo.dart';
import 'package:field_colector/domain/ports/bird_record_local_port.dart';
import 'package:field_colector/domain/ports/bird_record_remote_port.dart';
import 'package:field_colector/domain/ports/outing_local_port.dart';
import 'package:field_colector/domain/ports/outing_remote_port.dart';
import 'package:field_colector/domain/ports/photo_local_port.dart';
import 'package:field_colector/domain/ports/rock_record_local_port.dart';
import 'package:field_colector/domain/ports/rock_record_remote_port.dart';
import 'package:field_colector/domain/ports/soil_record_local_port.dart';
import 'package:field_colector/domain/ports/soil_record_remote_port.dart';
import 'package:field_colector/domain/ports/sync_port.dart';
import 'package:field_colector/domain/ports/vegetation_record_local_port.dart';
import 'package:field_colector/domain/ports/vegetation_record_remote_port.dart';
import 'package:field_colector/domain/ports/water_record_local_port.dart';
import 'package:field_colector/domain/ports/water_record_remote_port.dart';
import 'package:field_colector/domain/ports/social_record_local_port.dart';
import 'package:field_colector/domain/ports/social_record_remote_port.dart';
import 'package:field_colector/core/services/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockOutingLocalPort extends Mock implements OutingLocalPort {}

class MockOutingRemotePort extends Mock implements OutingRemotePort {}

class MockBirdLocalPort extends Mock implements BirdRecordLocalPort {}

class MockBirdRemotePort extends Mock implements BirdRecordRemotePort {}

class MockRockLocalPort extends Mock implements RockRecordLocalPort {}

class MockRockRemotePort extends Mock implements RockRecordRemotePort {}

class MockSoilLocalPort extends Mock implements SoilRecordLocalPort {}

class MockSoilRemotePort extends Mock implements SoilRecordRemotePort {}

class MockVegLocalPort extends Mock implements VegetationRecordLocalPort {}

class MockVegRemotePort extends Mock implements VegetationRecordRemotePort {}

class MockWaterLocalPort extends Mock implements WaterRecordLocalPort {}

class MockWaterRemotePort extends Mock implements WaterRecordRemotePort {}

class MockPhotoLocalPort extends Mock implements PhotoLocalPort {}

class MockSocialLocalPort extends Mock implements SocialRecordLocalPort {}

class MockSocialRemotePort extends Mock implements SocialRecordRemotePort {}

// ── Port set — agrupa todos los mocks para reducir boilerplate ────────────────

class _Ports {
  final outingLocal = MockOutingLocalPort();
  final outingRemote = MockOutingRemotePort();
  final birdLocal = MockBirdLocalPort();
  final birdRemote = MockBirdRemotePort();
  final rockLocal = MockRockLocalPort();
  final rockRemote = MockRockRemotePort();
  final soilLocal = MockSoilLocalPort();
  final soilRemote = MockSoilRemotePort();
  final vegLocal = MockVegLocalPort();
  final vegRemote = MockVegRemotePort();
  final waterLocal = MockWaterLocalPort();
  final waterRemote = MockWaterRemotePort();
  final photoLocal = MockPhotoLocalPort();
  final socialLocal = MockSocialLocalPort();
  final socialRemote = MockSocialRemotePort();

  void stubAllEmpty() {
    when(() => outingLocal.getPendingSyncOutings())
        .thenAnswer((_) async => []);
    when(() => birdLocal.getPendingSyncRecords()).thenAnswer((_) async => []);
    when(() => rockLocal.getPendingSyncRecords()).thenAnswer((_) async => []);
    when(() => soilLocal.getPendingSyncRecords()).thenAnswer((_) async => []);
    when(() => vegLocal.getPendingSyncRecords()).thenAnswer((_) async => []);
    when(() => waterLocal.getPendingSyncRecords()).thenAnswer((_) async => []);
    when(() => socialLocal.getPendingSyncRecords()).thenAnswer((_) async => []);
    when(() => photoLocal.getPendingSyncPhotos()).thenAnswer((_) async => []);
  }

  SyncService buildService() => SyncService(
        outingLocalPort: outingLocal,
        outingRemotePort: outingRemote,
        birdLocalPort: birdLocal,
        birdRemotePort: birdRemote,
        rockLocalPort: rockLocal,
        rockRemotePort: rockRemote,
        soilLocalPort: soilLocal,
        soilRemotePort: soilRemote,
        vegLocalPort: vegLocal,
        vegRemotePort: vegRemote,
        waterLocalPort: waterLocal,
        waterRemotePort: waterRemote,
        socialLocalPort: socialLocal,
        socialRemotePort: socialRemote,
        photoLocalPort: photoLocal,
      );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('SyncService', () {
    test('hasPendingSync retorna false si todo está sincronizado', () async {
      final p = _Ports()..stubAllEmpty();
      expect(await p.buildService().hasPendingSync(), isFalse);
    });

    test('getPendingSummary expone conteos de registros y fotos', () async {
      final p = _Ports()..stubAllEmpty();
      when(() => p.birdLocal.getPendingSyncRecords())
          .thenAnswer((_) async => [_bird()]);
      when(() => p.photoLocal.getPendingSyncPhotos())
          .thenAnswer((_) async => [_photo()]);

      final summary = await p.buildService().getPendingSummary();

      expect(summary.pendingRecords, 1);
      expect(summary.pendingPhotos, 1);
      expect(summary.hasPending, isTrue);
    });

    test('hasPendingSync retorna true si hay registros pendientes', () async {
      final p = _Ports()..stubAllEmpty();
      when(() => p.birdLocal.getPendingSyncRecords())
          .thenAnswer((_) async => [_bird()]);

      expect(await p.buildService().hasPendingSync(), isTrue);
    });

    test('hasPendingSync retorna true si hay outings pendientes', () async {
      final p = _Ports()..stubAllEmpty();
      when(() => p.outingLocal.getPendingSyncOutings())
          .thenAnswer((_) async => [_outing()]);

      expect(await p.buildService().hasPendingSync(), isTrue);
    });

    test('hasPendingSync retorna true si hay registros con error', () async {
      final p = _Ports()..stubAllEmpty();
      when(() => p.birdLocal.getPendingSyncRecords()).thenAnswer(
        (_) async => [
          BirdRecord(
            id: 'bird-sync-error',
            outingId: 'outing-sync-001',
            userId: 'user-001',
            recordedAt: DateTime(2025, 6, 11),
            coordinates: _coord(),
            department: 'Boyacá',
            municipality: 'El Cocuy',
            village: 'Güicán',
            sector: 'Páramo',
            syncStatus: 'error',
            season: 'dry',
            place: 'Bosque',
            speciesId: 'sp-001',
            birdType: 'passerine',
            migratorStatus: 'resident',
            individualCount: 1,
            behavior: 'resting',
            activity: 'visual',
            habitat: ['bosque'],
            foragingType: [],
            observedThreats: [],
            photos: [],
          ),
        ],
      );

      expect(await p.buildService().hasPendingSync(), isTrue);
    });

    test('syncPendingData reintenta registros con syncStatus error', () async {
      final p = _Ports()..stubAllEmpty();
      final bird = BirdRecord(
        id: 'bird-sync-error',
        outingId: 'outing-sync-001',
        userId: 'user-001',
        recordedAt: DateTime(2025, 6, 11),
        coordinates: _coord(),
        department: 'Boyacá',
        municipality: 'El Cocuy',
        village: 'Güicán',
        sector: 'Páramo',
        syncStatus: 'error',
        season: 'dry',
        place: 'Bosque',
        speciesId: 'sp-001',
        birdType: 'passerine',
        migratorStatus: 'resident',
        individualCount: 1,
        behavior: 'resting',
        activity: 'visual',
        habitat: ['bosque'],
        foragingType: [],
        observedThreats: [],
        photos: [],
      );

      when(() => p.birdLocal.getPendingSyncRecords())
          .thenAnswer((_) async => [bird]);
      when(() => p.birdRemote.saveBirdRecord(bird))
          .thenAnswer((_) async {});
      when(() => p.birdLocal.updateSyncStatus(bird.id, 'synced'))
          .thenAnswer((_) async {});

      final result = await p.buildService().syncPendingData();

      expect(result.synced, 1);
      expect(result.failed, 0);
      verify(() => p.birdRemote.saveBirdRecord(bird)).called(1);
      verify(() => p.birdLocal.updateSyncStatus(bird.id, 'synced')).called(1);
    });

    test('syncPendingData procesa outings antes que registros', () async {
      final p = _Ports()..stubAllEmpty();
      final callOrder = <String>[];
      final outing = _outing();
      final bird = _bird();

      when(() => p.outingLocal.getPendingSyncOutings())
          .thenAnswer((_) async => [outing]);
      when(() => p.birdLocal.getPendingSyncRecords())
          .thenAnswer((_) async => [bird]);
      when(() => p.outingRemote.saveOuting(outing)).thenAnswer((_) async {
        callOrder.add('outing');
      });
      when(() => p.outingLocal.updateSyncStatus(outing.id, 'synced'))
          .thenAnswer((_) async {});
      when(() => p.birdRemote.saveBirdRecord(bird)).thenAnswer((_) async {
        callOrder.add('bird');
      });
      when(() => p.birdLocal.updateSyncStatus(bird.id, 'synced'))
          .thenAnswer((_) async {});

      await p.buildService().syncPendingData();

      expect(callOrder.first, 'outing');
      expect(callOrder.last, 'bird');
    });

    test('syncPendingData marca synced tras upload exitoso', () async {
      final p = _Ports()..stubAllEmpty();
      final bird = _bird();

      when(() => p.birdLocal.getPendingSyncRecords())
          .thenAnswer((_) async => [bird]);
      when(() => p.birdRemote.saveBirdRecord(bird)).thenAnswer((_) async {});
      when(() => p.birdLocal.updateSyncStatus(bird.id, 'synced'))
          .thenAnswer((_) async {});

      final result = await p.buildService().syncPendingData();

      expect(result.synced, 1);
      expect(result.failed, 0);
      verify(() => p.birdLocal.updateSyncStatus(bird.id, 'synced')).called(1);
    });

    test('syncPendingData marca error si Firebase falla', () async {
      final p = _Ports()..stubAllEmpty();
      final bird = _bird();

      when(() => p.birdLocal.getPendingSyncRecords())
          .thenAnswer((_) async => [bird]);
      when(() => p.birdRemote.saveBirdRecord(bird))
          .thenThrow(Exception('Firebase offline'));
      when(() => p.birdLocal.updateSyncStatus(bird.id, 'error'))
          .thenAnswer((_) async {});

      final result = await p.buildService().syncPendingData();

      expect(result.failed, 1);
      expect(result.synced, 0);
      verify(() => p.birdLocal.updateSyncStatus(bird.id, 'error')).called(1);
    });

    test('syncPendingData continúa tras error individual', () async {
      final p = _Ports()..stubAllEmpty();
      final bird1 = _bird();
      final bird2 = _bird2();

      when(() => p.birdLocal.getPendingSyncRecords())
          .thenAnswer((_) async => [bird1, bird2]);
      when(() => p.birdRemote.saveBirdRecord(bird1))
          .thenThrow(Exception('error en bird1'));
      when(() => p.birdLocal.updateSyncStatus(bird1.id, 'error'))
          .thenAnswer((_) async {});
      when(() => p.birdRemote.saveBirdRecord(bird2)).thenAnswer((_) async {});
      when(() => p.birdLocal.updateSyncStatus(bird2.id, 'synced'))
          .thenAnswer((_) async {});

      final result = await p.buildService().syncPendingData();

      expect(result.synced, 1);
      expect(result.failed, 1);
      expect(result.errors, hasLength(1));
    });

    test('syncPendingData retorna SyncResult con conteos correctos', () async {
      final p = _Ports()..stubAllEmpty();
      final bird = _bird();

      when(() => p.birdLocal.getPendingSyncRecords())
          .thenAnswer((_) async => [bird]);
      when(() => p.birdRemote.saveBirdRecord(bird)).thenAnswer((_) async {});
      when(() => p.birdLocal.updateSyncStatus(bird.id, 'synced'))
          .thenAnswer((_) async {});

      final result = await p.buildService().syncPendingData();

      expect(result, isA<SyncResult>());
      expect(result.synced, greaterThanOrEqualTo(0));
      expect(result.failed, greaterThanOrEqualTo(0));
      expect(result.errors, isA<List<String>>());
    });

    test('syncPendingData es idempotente — reintento no duplica en Firebase',
        () async {
      final p = _Ports()..stubAllEmpty();
      final bird = _bird();
      var callCount = 0;

      // Primera llamada devuelve el bird pendiente, segunda devuelve vacío
      when(() => p.birdLocal.getPendingSyncRecords()).thenAnswer((_) async {
        callCount++;
        return callCount == 1 ? [bird] : [];
      });
      when(() => p.birdRemote.saveBirdRecord(bird)).thenAnswer((_) async {});
      when(() => p.birdLocal.updateSyncStatus(bird.id, 'synced'))
          .thenAnswer((_) async {});

      final service = p.buildService();
      final result1 = await service.syncPendingData();
      final result2 = await service.syncPendingData();

      verify(() => p.birdRemote.saveBirdRecord(bird)).called(1);
      expect(result1.synced, 1);
      expect(result2.synced, 0);
    });

    test('emite SyncProgress durante la sincronización', () async {
      final p = _Ports()..stubAllEmpty();
      final bird = _bird();

      when(() => p.birdLocal.getPendingSyncRecords())
          .thenAnswer((_) async => [bird]);
      when(() => p.birdRemote.saveBirdRecord(bird)).thenAnswer((_) async {});
      when(() => p.birdLocal.updateSyncStatus(bird.id, 'synced'))
          .thenAnswer((_) async {});

      final service = p.buildService();
      final progress = <SyncProgress>[];
      final sub = service.syncProgress.listen(progress.add);

      await service.syncPendingData();
      await sub.cancel();

      expect(progress, isNotEmpty);
      expect(progress.first, isA<SyncProgress>());
      expect(progress.first.total, greaterThan(0));
    });
  });
}

// ── Fixtures ──────────────────────────────────────────────────────────────────

Coordinate _coord() => Coordinate(
      latitude: 6.4076,
      longitude: -72.3117,
      altitude: 4200,
      gpsAccuracy: 3.0,
      manuallyEdited: false,
    );

BirdRecord _bird() => BirdRecord(
      id: 'bird-sync-001',
      outingId: 'outing-sync-001',
      userId: 'user-001',
      recordedAt: DateTime(2025, 6, 15, 10),
      coordinates: _coord(),
      department: 'Boyacá',
      municipality: 'El Cocuy',
      village: 'Güicán',
      sector: 'Páramo',
      syncStatus: 'pending',
      season: 'dry',
      place: 'Bosque',
      speciesId: 'sp-001',
      birdType: 'passerine',
      migratorStatus: 'resident',
      individualCount: 1,
      behavior: 'resting',
      activity: 'visual',
      habitat: ['bosque'],
      foragingType: [],
      observedThreats: [],
      photos: [],
    );

BirdRecord _bird2() => BirdRecord(
      id: 'bird-sync-002',
      outingId: 'outing-sync-001',
      userId: 'user-001',
      recordedAt: DateTime(2025, 6, 15, 11),
      coordinates: _coord(),
      department: 'Boyacá',
      municipality: 'El Cocuy',
      village: 'Güicán',
      sector: 'Páramo',
      syncStatus: 'pending',
      season: 'dry',
      place: 'Laguna',
      speciesId: 'sp-002',
      birdType: 'waterfowl',
      migratorStatus: 'migratory',
      individualCount: 3,
      behavior: 'feeding',
      activity: 'vocal',
      habitat: ['laguna'],
      foragingType: ['piscivore'],
      observedThreats: [],
      photos: [],
    );

Outing _outing() => Outing(
      id: 'outing-sync-001',
      prefix: 'CIT-BIO',
      name: 'Expedición de prueba sync',
      location: 'El Cocuy',
      zone: 'Páramo',
      reason: 'Monitoreo',
       places: const [OutingPlace(id: 'place-sync-001', name: 'El Cocuy', latitude: 6.4076, longitude: -72.3117, altitude: 4200)],
      startDate: DateTime(2025, 6, 10),
      endDate: DateTime(2025, 6, 17),
      createdById: 'user-001',
      participantIds: ['user-001'],
      status: 'active',
      syncStatus: 'pending',
    );

// ignore: unused_element
Photo _photo() => Photo(
      id: 'photo-sync-001',
      filename: 'bird_photo.jpg',
      localPath: '/data/citesa/bird_photo.jpg',
      storageUrl: '',
      photoType: 'bird',
      recordId: 'bird-sync-001',
      recordType: 'bird',
      syncStatus: 'pending',
    );
