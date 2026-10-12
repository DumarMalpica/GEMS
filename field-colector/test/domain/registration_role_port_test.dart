import 'package:field_colector/adapters/real/event_registration_role_adapter.dart';
import 'package:field_colector/domain/entities/role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final event = EventRegistrationRoleAdapter(
    role: Role.legacy,
    endsAt: DateTime.utc(2026, 10, 11, 5),
  );

  test('event role applies before cutoff and default role after', () {
    expect(
      event.roleForRegistration(DateTime.utc(2026, 10, 10, 23)),
      Role.legacy,
    );
    expect(event.roleForRegistration(DateTime.utc(2026, 10, 11, 5)), Role.user);
  });

  test('role parser preserves special roles without granting permissions', () {
    expect(Role.fromId('unicor'), Role.unicor);
    expect(Role.fromId(' UNICOR '), Role.unicor);
    expect(Role.fromId(' LEGACY '), Role.legacy);
    expect(Role.fromId('legacy'), Role.legacy);
    expect(Role.fromId('legacy').hasPermission('admin'), isFalse);
  });
}
