import 'package:field_colector/core/services/session_validation_service.dart';
import 'package:field_colector/adapters/real/event_registration_role_adapter.dart';
import 'package:field_colector/domain/entities/role.dart';
import 'package:field_colector/domain/entities/user.dart';
import 'package:field_colector/domain/ports/auth_port.dart';
import 'package:field_colector/domain/ports/user_local_port.dart';
import 'package:field_colector/domain/ports/user_remote_port.dart';
import 'package:field_colector/domain/ports/registration_role_port.dart';
import 'package:field_colector/domain/mappers/register_user_dto_builder.dart';
import 'package:field_colector/features/auth/providers/auth_provider.dart';
import 'package:field_colector/features/profile/providers/profile_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthPort extends Mock implements AuthPort {}

class MockUserLocalPort extends Mock implements UserLocalPort {}

class MockUserRemotePort extends Mock implements UserRemotePort {}

class MockRegistrationRolePort extends Mock implements RegistrationRolePort {}

class FakeUser extends Fake implements User {}

void main() {
  setUpAll(() => registerFallbackValue(FakeUser()));

  test('registration applies event role to local and remote profile', () async {
    final authPort = MockAuthPort();
    final localPort = MockUserLocalPort();
    final userRemote = MockUserRemotePort();
    final user = User(
      id: 'new-user',
      email: 'new@example.com',
      fullName: 'New User',
      role: Role.user,
      token: 'token',
      tokenExpiry: DateTime.now().add(const Duration(hours: 1)),
    );
    when(
      () => authPort.register(
        email: 'new@example.com',
        password: 'password',
        fullName: 'New User',
        fieldStudy: 'Ecology',
      ),
    ).thenAnswer((_) async => user);
    when(() => authPort.updateProfile(any())).thenAnswer((_) async {});
    when(() => userRemote.saveUser(any())).thenAnswer((_) async {});
    when(() => localPort.getRawLocalUser()).thenAnswer((_) async => null);

    final auth = Authprovider(
      authPort: authPort,
      registrationRole: EventRegistrationRoleAdapter(
        role: Role.legacy,
        endsAt: DateTime.now().add(const Duration(days: 1)),
      ),
      userRemote: userRemote,
      sessionValidation: SessionValidationService(localPort),
    );
    await auth.register(
      RegisterUserDto(
        email: user.email,
        password: 'password',
        fullName: user.fullName,
        fieldOfStudy: 'Ecology',
        graduated: false,
        userRoleId: 1,
        otherCareer: '',
      ),
    );

    expect(auth.user?.role, Role.legacy);
    verify(
      () => authPort.updateProfile(
        any(that: isA<User>().having((u) => u.role, 'role', Role.legacy)),
      ),
    ).called(1);
    verify(
      () => userRemote.saveUser(
        any(that: isA<User>().having((u) => u.role, 'role', Role.legacy)),
      ),
    ).called(1);
    auth.dispose();
  });

  test('profile reads stop after two requests in one session', () async {
    final authPort = MockAuthPort();
    final localPort = MockUserLocalPort();
    final userRemote = MockUserRemotePort();
    final user = User(
      id: 'user-1',
      email: 'user@example.com',
      fullName: 'Example User',
      role: Role.user,
      token: 'token',
      tokenExpiry: DateTime.now().add(const Duration(hours: 1)),
    );
    when(() => localPort.getRawLocalUser()).thenAnswer((_) async => user);
    when(() => userRemote.getUserById(user.id)).thenAnswer((_) async => user);

    final auth = Authprovider(
      authPort: authPort,
      registrationRole: MockRegistrationRolePort(),
      userRemote: userRemote,
      sessionValidation: SessionValidationService(localPort),
    );
    await auth.restoreSession();
    final profile = ProfileProvider(auth: auth);

    await profile.loadProfile();
    await profile.refresh();
    await profile.refresh();

    verify(() => userRemote.getUserById(user.id)).called(2);
    expect(profile.canRefresh, isFalse);

    profile.dispose();
    auth.dispose();
  });
}
