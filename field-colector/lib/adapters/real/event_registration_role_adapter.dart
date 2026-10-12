import '../../domain/entities/role.dart';
import '../../domain/ports/registration_role_port.dart';

class EventRegistrationRoleAdapter implements RegistrationRolePort {
  const EventRegistrationRoleAdapter({
    required this.role,
    required this.endsAt,
    this.fallback = Role.user,
  });

  final Role role;
  final DateTime endsAt;
  final Role fallback;

  @override
  Role roleForRegistration(DateTime registeredAt) =>
      registeredAt.isBefore(endsAt) ? role : fallback;
}
