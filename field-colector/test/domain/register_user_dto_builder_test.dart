import 'package:field_colector/domain/mappers/register_user_dto_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('external-provider profile needs no email or password', () {
    final dto = buildRegisterUserDto(
      firstName: 'Ana',
      lastName: 'García',
      email: '',
      password: '',
      confirmPassword: '',
      userType: 0,
      studyArea: 'Ecología',
      otherCareer: null,
      externalProvider: true,
    );

    expect(dto, isNotNull);
    expect(dto!.fullName, 'Ana García');
    expect(dto.email, isEmpty);
    expect(dto.password, isEmpty);
    expect(dto.fieldOfStudy, 'Ecología');
  });
}
