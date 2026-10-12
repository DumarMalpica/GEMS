const String _otherCareerSentinel = 'Otra';

/// Payload for a future Firebase (or API) sign-up call.
class RegisterUserDto {
  static const int defaultRegistrationRoleId = 1;

  final String fullName;
  final String email;
  final String fieldOfStudy;
  final bool graduated;
  final int userRoleId;
  final String password;
  final String otherCareer;

  RegisterUserDto({
    required this.fullName,
    required this.email,
    required this.fieldOfStudy,
    required this.graduated,
    required this.userRoleId,
    required this.password,
    required this.otherCareer,
  });
}

/// Returns `null` if validation fails (empty fields, password mismatch, etc.).
RegisterUserDto? buildRegisterUserDto({
  required String firstName,
  required String lastName,
  required String email,
  required String password,
  required String confirmPassword,
  required int? userType,
  required String? studyArea,
  required String? otherCareer,
  bool externalProvider = false,
  int userRoleId = RegisterUserDto.defaultRegistrationRoleId,
}) {
  final first = firstName.trim();
  final last = lastName.trim();
  final mail = email.trim();
  final area = studyArea?.trim();
  final other = otherCareer?.trim() ?? '';

  if (first.isEmpty || last.isEmpty) return null;
  if (!externalProvider && (mail.isEmpty || password != confirmPassword)) {
    return null;
  }
  if (userType == null) return null;
  if (area == null || area.isEmpty) return null;
  if (area == _otherCareerSentinel && other.isEmpty) return null;

  final resolvedField = area == _otherCareerSentinel ? other : area;

  return RegisterUserDto(
    fullName: '$first $last'.trim(),
    email: externalProvider ? '' : mail,
    fieldOfStudy: resolvedField,
    graduated: userType == 1,
    userRoleId: userRoleId,
    password: password,
    otherCareer: area == _otherCareerSentinel ? other : '',
  );
}
