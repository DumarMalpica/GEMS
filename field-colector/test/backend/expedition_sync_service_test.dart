import 'package:field_colector/core/services/expedition_sync_service.dart';
import 'package:field_colector/domain/entities/outing.dart';
import 'package:field_colector/domain/ports/network_reachability.dart';
import 'package:field_colector/domain/ports/outing_local_port.dart';
import 'package:field_colector/domain/ports/outing_remote_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOutingLocalPort extends Mock implements OutingLocalPort {}

class _MockOutingRemotePort extends Mock implements OutingRemotePort {}

class _MockNetworkReachability extends Mock implements NetworkReachability {}

void main() {
  setUpAll(
    () => registerFallbackValue(
      _outing(
        PendingUser(
          id: 'fallback',
          name: 'Fallback',
          email: 'fallback@example.com',
        ),
      ),
    ),
  );

  test(
    'sync replaces pending users when the list length is unchanged',
    () async {
      final local = _MockOutingLocalPort();
      final remote = _MockOutingRemotePort();
      final reachability = _MockNetworkReachability();
      final localOuting = _outing(
        PendingUser(id: 'old-user', name: 'Old', email: 'old@example.com'),
      );
      final remoteOuting = _outing(
        PendingUser(id: 'new-user', name: 'New', email: 'new@example.com'),
      );

      when(
        () => reachability.hasConnectivityNow(),
      ).thenAnswer((_) async => true);
      when(
        () => remote.getOutingById('outing-1'),
      ).thenAnswer((_) async => remoteOuting);
      when(
        () => local.getOutingById('outing-1'),
      ).thenAnswer((_) async => localOuting);
      when(() => local.saveOuting(any())).thenAnswer((_) async {});

      final sync = ExpeditionSyncService(
        outingLocal: local,
        outingRemote: remote,
        reachability: reachability,
      );

      expect(await sync.syncOutingById('outing-1'), isTrue);
      verify(() => local.saveOuting(any())).called(1);
    },
  );
}

Outing _outing(PendingUser pendingUser) => Outing(
  id: 'outing-1',
  prefix: 'EXP',
  name: 'Expedition',
  location: 'Location',
  zone: 'Zone',
  reason: 'Research',
  places: const [],
  startDate: DateTime.utc(2026),
  endDate: DateTime.utc(2026, 1, 2),
  createdById: 'owner',
  participantIds: const ['owner'],
  status: 'active',
  syncStatus: 'synced',
  pendingUsers: [pendingUser],
);
