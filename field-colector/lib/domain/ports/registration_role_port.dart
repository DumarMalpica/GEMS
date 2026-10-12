import '../entities/role.dart';

abstract class RegistrationRolePort {
  Role roleForRegistration(DateTime registeredAt);
}
