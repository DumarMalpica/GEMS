import 'package:field_colector/domain/entities/outing.dart';
import 'package:field_colector/domain/ports/outing_local_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockOutingLocalPort extends Mock implements OutingLocalPort {}

void main() {
  late MockOutingLocalPort mockPort;

  setUp(() => mockPort = MockOutingLocalPort());

  group('OutingLocalPort — contrato de expediciones locales', () {
    // ── CRUD ────────────────────────────────────────────────────────────────

    test('saveOuting guarda expedición correctamente', () async {
      final outing = _outingActiva();
      when(() => mockPort.saveOuting(outing)).thenAnswer((_) async {});

      await mockPort.saveOuting(outing);

      verify(() => mockPort.saveOuting(outing)).called(1);
    });

    test('getOutingById retorna participantes con nombre y email', () async {
      final outing = _outingActiva();
      when(() => mockPort.getOutingById(outing.id))
          .thenAnswer((_) async => outing);

      final result = await mockPort.getOutingById(outing.id);
      expect(result!.participants, hasLength(2));
      expect(result.participants.first.name, 'Director Test');
      expect(result.participants.last.email, 'colega@citesa.co');
    });

    test('getOutingById retorna expedición existente', () async {
      final outing = _outingActiva();
      when(() => mockPort.getOutingById(outing.id))
          .thenAnswer((_) async => outing);

      final result = await mockPort.getOutingById(outing.id);

      expect(result, isNotNull);
      expect(result!.id, outing.id);
      expect(result.name, 'Muestreo de flora — El Cocuy');
      expect(result.status, 'active');
    });

    test('getOutingById retorna null si no existe', () async {
      when(() => mockPort.getOutingById('no-existe'))
          .thenAnswer((_) async => null);

      expect(await mockPort.getOutingById('no-existe'), isNull);
    });

    test('getAllOutings retorna lista completa', () async {
      final outings = [_outingActiva(), _outingCerrada()];
      when(() => mockPort.getAllOutings()).thenAnswer((_) async => outings);

      final result = await mockPort.getAllOutings();

      expect(result, hasLength(2));
      expect(result.map((o) => o.id),
          containsAll([outings[0].id, outings[1].id]));
    });

    test('updateOuting actualiza campos parciales correctamente', () async {
      when(() => mockPort.updateOuting('outing-test-001', {'status': 'closed'}))
          .thenAnswer((_) async {});

      await mockPort.updateOuting('outing-test-001', {'status': 'closed'});

      verify(() =>
              mockPort.updateOuting('outing-test-001', {'status': 'closed'}))
          .called(1);
    });

    test('deleteOuting elimina correctamente', () async {
      final outing = _outingActiva();
      when(() => mockPort.deleteOuting(outing.id)).thenAnswer((_) async {});

      await mockPort.deleteOuting(outing.id);

      verify(() => mockPort.deleteOuting(outing.id)).called(1);
    });

    test('clearAll limpia todas las expediciones', () async {
      when(() => mockPort.clearAll()).thenAnswer((_) async {});

      await mockPort.clearAll();

      verify(() => mockPort.clearAll()).called(1);
    });

    // ── Queries ──────────────────────────────────────────────────────────────

    test('getOutingsByStatus retorna solo expediciones activas', () async {
      final activa = _outingActiva();
      when(() => mockPort.getOutingsByStatus('active'))
          .thenAnswer((_) async => [activa]);

      final result = await mockPort.getOutingsByStatus('active');

      expect(result, hasLength(1));
      expect(result.first.status, 'active');
    });

    test('getOutingsByStatus retorna lista vacía si no hay coincidencias',
        () async {
      when(() => mockPort.getOutingsByStatus('draft'))
          .thenAnswer((_) async => []);

      expect(await mockPort.getOutingsByStatus('draft'), isEmpty);
    });

    test('getOutingsByDateRange retorna expediciones en el rango', () async {
      final outing = _outingActiva();
      final start = DateTime(2025, 6, 1);
      final end = DateTime(2025, 6, 30);
      when(() => mockPort.getOutingsByDateRange(start, end))
          .thenAnswer((_) async => [outing]);

      final result = await mockPort.getOutingsByDateRange(start, end);

      expect(result, hasLength(1));
      expect(
          !result.first.startDate.isBefore(start) &&
              !result.first.startDate.isAfter(end),
          isTrue);
    });

    test('getOutingsByDateRange retorna vacío si no hay en el rango', () async {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 31);
      when(() => mockPort.getOutingsByDateRange(start, end))
          .thenAnswer((_) async => []);

      expect(await mockPort.getOutingsByDateRange(start, end), isEmpty);
    });

    test('getOutingsByCreator retorna expediciones del usuario', () async {
      final outing = _outingActiva();
      when(() => mockPort.getOutingsByCreator('uid-investigador-001'))
          .thenAnswer((_) async => [outing]);

      final result =
          await mockPort.getOutingsByCreator('uid-investigador-001');

      expect(result, hasLength(1));
      expect(result.first.createdById, 'uid-investigador-001');
    });

    test('getOutingsByParticipant retorna donde el usuario participa',
        () async {
      final outing = _outingActiva();
      when(() => mockPort.getOutingsByParticipant('uid-investigador-002'))
          .thenAnswer((_) async => [outing]);

      final result =
          await mockPort.getOutingsByParticipant('uid-investigador-002');

      expect(result, hasLength(1));
      expect(result.first.participantIds.contains('uid-investigador-002'),
          isTrue);
    });

    // ── Pending users ────────────────────────────────────────────────────────

    test('addPendingUserToOuting agrega usuario pendiente', () async {
      final user = _pendingUser();
      when(() => mockPort.addPendingUserToOuting('outing-test-001', user))
          .thenAnswer((_) async {});

      await mockPort.addPendingUserToOuting('outing-test-001', user);

      verify(() =>
              mockPort.addPendingUserToOuting('outing-test-001', user))
          .called(1);
    });

    test('removePendingUserFromOuting elimina usuario pendiente', () async {
      when(() => mockPort.removePendingUserFromOuting(
              'outing-test-001', 'uid-pendiente-001'))
          .thenAnswer((_) async {});

      await mockPort.removePendingUserFromOuting(
          'outing-test-001', 'uid-pendiente-001');

      verify(() => mockPort.removePendingUserFromOuting(
          'outing-test-001', 'uid-pendiente-001')).called(1);
    });

    test('getPendingUsersByOutingId retorna lista de usuarios pendientes',
        () async {
      final user = _pendingUser();
      when(() => mockPort.getPendingUsersByOutingId('outing-test-001'))
          .thenAnswer((_) async => [user]);

      final result =
          await mockPort.getPendingUsersByOutingId('outing-test-001');

      expect(result, hasLength(1));
      expect(result.first.id, 'uid-pendiente-001');
      expect(result.first.email, 'pendiente@citesa.co');
    });

    test('getPendingUsersByOutingId retorna lista vacía si no hay pendientes',
        () async {
      when(() => mockPort.getPendingUsersByOutingId('outing-sin-pendientes'))
          .thenAnswer((_) async => []);

      expect(
          await mockPort.getPendingUsersByOutingId('outing-sin-pendientes'),
          isEmpty);
    });

    // ── Sincronización ───────────────────────────────────────────────────────

    test('getPendingSyncOutings retorna solo las pendientes', () async {
      final pendiente = _outingPendienteSync();
      when(() => mockPort.getPendingSyncOutings())
          .thenAnswer((_) async => [pendiente]);

      final result = await mockPort.getPendingSyncOutings();

      expect(result, hasLength(1));
      expect(result.first.syncStatus, 'pending');
    });

    test('updateSyncStatus actualiza el estado correctamente', () async {
      when(() => mockPort.updateSyncStatus('outing-test-001', 'synced'))
          .thenAnswer((_) async {});

      await mockPort.updateSyncStatus('outing-test-001', 'synced');

      verify(() => mockPort.updateSyncStatus('outing-test-001', 'synced'))
          .called(1);
    });

    test('updateFirebaseId asigna el id de Firebase al registro local',
        () async {
      when(() => mockPort.updateFirebaseId(1, 'firebase-id-abc'))
          .thenAnswer((_) async {});

      await mockPort.updateFirebaseId(1, 'firebase-id-abc');

      verify(() => mockPort.updateFirebaseId(1, 'firebase-id-abc')).called(1);
    });

    // ── Flujos completos ─────────────────────────────────────────────────────

    test('flujo pending users: add → get → remove → get vacío', () async {
      final user = _pendingUser();
      const outingId = 'outing-test-001';

      when(() => mockPort.addPendingUserToOuting(outingId, user))
          .thenAnswer((_) async {});
      when(() => mockPort.getPendingUsersByOutingId(outingId))
          .thenAnswer((_) async => [user]);
      when(() =>
              mockPort.removePendingUserFromOuting(outingId, user.id))
          .thenAnswer((_) async {});

      await mockPort.addPendingUserToOuting(outingId, user);
      final conUsuario = await mockPort.getPendingUsersByOutingId(outingId);
      expect(conUsuario, hasLength(1));

      await mockPort.removePendingUserFromOuting(outingId, user.id);
      when(() => mockPort.getPendingUsersByOutingId(outingId))
          .thenAnswer((_) async => []);
      expect(await mockPort.getPendingUsersByOutingId(outingId), isEmpty);
    });

    test('flujo offline completo: save → get → sync → update', () async {
      final outing = _outingPendienteSync();

      when(() => mockPort.saveOuting(outing)).thenAnswer((_) async {});
      when(() => mockPort.getOutingById(outing.id))
          .thenAnswer((_) async => outing);
      when(() => mockPort.getPendingSyncOutings())
          .thenAnswer((_) async => [outing]);
      when(() => mockPort.updateSyncStatus(outing.id, 'synced'))
          .thenAnswer((_) async {});
      when(() => mockPort.updateFirebaseId(1, 'firebase-real-id'))
          .thenAnswer((_) async {});

      await mockPort.saveOuting(outing);
      final guardada = await mockPort.getOutingById(outing.id);
      expect(guardada!.syncStatus, 'pending');

      final pendientes = await mockPort.getPendingSyncOutings();
      expect(pendientes, hasLength(1));

      await mockPort.updateSyncStatus(outing.id, 'synced');
      await mockPort.updateFirebaseId(1, 'firebase-real-id');

      verify(() => mockPort.updateSyncStatus(outing.id, 'synced')).called(1);
      verify(() => mockPort.updateFirebaseId(1, 'firebase-real-id')).called(1);
    });

    test('flujo completo: save → get → delete → get null', () async {
      final outing = _outingActiva();

      when(() => mockPort.saveOuting(outing)).thenAnswer((_) async {});
      when(() => mockPort.getOutingById(outing.id))
          .thenAnswer((_) async => outing);
      when(() => mockPort.deleteOuting(outing.id)).thenAnswer((_) async {});

      await mockPort.saveOuting(outing);
      final guardada = await mockPort.getOutingById(outing.id);
      expect(guardada, isNotNull);

      await mockPort.deleteOuting(outing.id);

      when(() => mockPort.getOutingById(outing.id))
          .thenAnswer((_) async => null);
      expect(await mockPort.getOutingById(outing.id), isNull);
    });
  });
}

// ── Fixtures ──────────────────────────────────────────────────────────────────

Outing _outingActiva() => Outing(
      id: 'outing-test-001',
      prefix: 'CIT-ECO',
      name: 'Muestreo de flora — El Cocuy',
      location: 'Serranía El Cocuy',
      zone: 'Páramo',
      reason: 'Inventario de flora vascular en zona glaciar',
       places: const [OutingPlace(id: 'place-001', name: 'El Cocuy', latitude: 6.4076, longitude: -72.3117, altitude: 4200)],
      startDate: DateTime(2025, 6, 10),
      endDate: DateTime(2025, 6, 17),
      createdById: 'uid-investigador-001',
      participantIds: ['uid-investigador-001', 'uid-investigador-002'],
      participants: [
        const OutingMember(
          id: 'uid-investigador-001',
          name: 'Director Test',
          email: 'dir@citesa.co',
        ),
        const OutingMember(
          id: 'uid-investigador-002',
          name: 'Colega Test',
          email: 'colega@citesa.co',
        ),
      ],
      status: 'active',
      syncStatus: 'synced',
    );

Outing _outingCerrada() => Outing(
      id: 'outing-test-002',
      prefix: 'CIT-AGU',
      name: 'Análisis de agua — Lago de Tota',
      location: 'Lago de Tota',
      zone: 'Humedal',
      reason: 'Evaluación fisicoquímica del cuerpo de agua',
       places: const [OutingPlace(id: 'place-002', name: 'Lago de Tota', latitude: 5.5452, longitude: -72.9181, altitude: 3015)],
      startDate: DateTime(2025, 3, 1),
      endDate: DateTime(2025, 3, 3),
      createdById: 'uid-investigador-001',
      participantIds: ['uid-investigador-001'],
      status: 'closed',
      syncStatus: 'synced',
    );

Outing _outingPendienteSync() => Outing(
      id: 'outing-test-003',
      prefix: 'CIT-GEO',
      name: 'Estudio geológico — Cañón del Chicamocha',
      location: 'Santander',
      zone: 'Zona de falla geológica',
      reason: 'Identificación de formaciones rocosas',
       places: const [OutingPlace(id: 'place-003', name: 'Cañón del Chicamocha', latitude: 6.5750, longitude: -72.9083, altitude: 900)],
      startDate: DateTime(2025, 9, 1),
      endDate: DateTime(2025, 9, 5),
      createdById: 'uid-investigador-002',
      participantIds: ['uid-investigador-002'],
      status: 'active',
      syncStatus: 'pending',
    );

PendingUser _pendingUser() => PendingUser(
      id: 'uid-pendiente-001',
      name: 'Estudiante Invitado',
      email: 'pendiente@citesa.co',
    );
