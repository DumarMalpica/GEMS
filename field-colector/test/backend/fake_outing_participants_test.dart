import 'package:field_colector/adapters/fake/fake_outing_adapter.dart';
import 'package:field_colector/domain/entities/outing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeOutingAdapter — participants persistence', () {
    late FakeOutingAdapter adapter;

    setUp(() => adapter = FakeOutingAdapter());

    test('save and load round-trips participants', () async {
      const outingId = 'outing-participants-rt';
      final outing = Outing(
        id: outingId,
        prefix: 'CIT-RT',
        name: 'Round trip',
        location: 'Test',
        zone: 'Zona',
        reason: 'Test',
         places: const [OutingPlace(id: 'place-rt', name: 'Test', latitude: 1, longitude: 2, altitude: 3)],
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 2),
        createdById: 'uid-a',
        participantIds: ['uid-a', 'uid-b'],
        participants: const [
          OutingMember(id: 'uid-a', name: 'Alice', email: 'a@test.com'),
          OutingMember(id: 'uid-b', name: 'Bob', email: 'b@test.com'),
        ],
        status: 'active',
        syncStatus: 'synced',
      );

      await adapter.saveOuting(outing);
      final loaded = await adapter.getOutingById(outingId);

      expect(loaded, isNotNull);
      expect(loaded!.participants, hasLength(2));
      expect(loaded.participants.first.name, 'Alice');
      expect(loaded.participants.last.email, 'b@test.com');
    });

    test('updateOuting persists participants array', () async {
      const outingId = 'fake-outing-001';
      final newParticipants = [
        const OutingMember(
          id: 'fake-uid-001',
          name: 'Updated Name',
          email: 'updated@test.com',
        ),
      ];

      await adapter.updateOuting(outingId, {
        'participants': newParticipants,
      });

      final loaded = await adapter.getOutingById(outingId);
      expect(loaded?.participants.single.name, 'Updated Name');
    });
  });
}
