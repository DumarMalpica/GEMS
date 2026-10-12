import '../../domain/entities/role.dart';
import '../../domain/entities/user.dart';
import '../../domain/ports/auth_port.dart';

/// ⚠️ FAKE ADAPTER — SOLO PARA DESARROLLO
/// Nunca se usa en producción. Se reemplaza por FirebaseAuthAdapter.
///
/// Credenciales de prueba:
///   admin@citesa.co    / Admin2024!  → Administrador
///   usuario@citesa.co  / Field2024!  → Usuario
class FakeAuthAdapter implements AuthPort {
  static final List<_FakeUser> _seed = [
    _FakeUser(
      id: 'fake-uid-001',
      email: 'admin@citesa.co',
      password: 'Admin2024!',
      fullName: 'Administrador Citesa',
      role: Role.admin,
      fieldStudy: 'Administración',
      graduated: true,
    ),
    _FakeUser(
      id: 'fake-uid-002',
      email: 'usuario@citesa.co',
      password: 'Field2024!',
      fullName: 'Ana Investigadora',
      role: Role.user,
      fieldStudy: 'Ecología',
      graduated: false,
    ),
  ];

  final List<_FakeUser> _runtime = [];
  User? _activeUser;

  @override
  Future<User> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 350));

    final normalizedEmail = email.trim().toLowerCase();
    final all = [..._seed, ..._runtime];
    final match = all.where(
      (u) => u.email == normalizedEmail && u.password == password,
    );

    if (match.isEmpty) {
      throw const AuthException(
        message: 'Correo o contraseña incorrectos.',
        type: AuthErrorType.invalidCredentials,
      );
    }

    _activeUser = match.first.toUser(
      token:
          'fake-jwt-${match.first.id}-${DateTime.now().millisecondsSinceEpoch}',
      tokenExpiry: DateTime.now().add(const Duration(hours: 8)),
    );
    return _activeUser!;
  }

  @override
  Future<ExternalAuthResult?> loginWithExternalProvider() async {
    throw const AuthException(
      message: 'Google no está disponible en el modo de desarrollo.',
      type: AuthErrorType.unknown,
    );
  }

  @override
  Future<User> register({
    required String email,
    required String password,
    required String fullName,
    String? fieldStudy,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));

    final normalizedEmail = email.trim().toLowerCase();
    final all = [..._seed, ..._runtime];

    if (all.any((u) => u.email == normalizedEmail)) {
      throw const AuthException(
        message: 'Este correo ya está registrado.',
        type: AuthErrorType.emailAlreadyInUse,
      );
    }

    if (password.length < 6) {
      throw const AuthException(
        message: 'La contraseña debe tener al menos 6 caracteres.',
        type: AuthErrorType.weakPassword,
      );
    }

    final newUser = _FakeUser(
      id: 'fake-uid-rt-${DateTime.now().millisecondsSinceEpoch}',
      email: normalizedEmail,
      password: password,
      fullName: fullName.trim(),
      role: Role.user,
      fieldStudy: fieldStudy,
      graduated: false,
    );

    _runtime.add(newUser);
    _activeUser = newUser.toUser(
      token: 'fake-jwt-${newUser.id}',
      tokenExpiry: DateTime.now().add(const Duration(hours: 8)),
    );
    return _activeUser!;
  }

  @override
  Future<void> updateProfile(User user) async {
    _activeUser = user;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _activeUser = null;
  }

  @override
  Future<User?> getCurrentUser() async => _activeUser;

  @override
  Future<User?> validateOfflineSession() async {
    if (_activeUser == null) return null;
    if (!_activeUser!.hasValidToken) {
      _activeUser = null;
      return null;
    }
    return _activeUser;
  }
}

class _FakeUser {
  final String id;
  final String email;

  /// ⚠️ SOLO PARA TEST — nunca usar texto plano en producción.
  /// Producción usa Firebase Auth que maneja el hashing internamente.
  final String password;
  final String fullName;
  final Role role;
  final String? fieldStudy;
  final bool graduated;

  const _FakeUser({
    required this.id,
    required this.email,
    required this.password,
    required this.fullName,
    required this.role,
    this.fieldStudy,
    this.graduated = false,
  });

  User toUser({String? token, DateTime? tokenExpiry}) => User(
    id: id,
    email: email,
    fullName: fullName,
    role: role,
    fieldStudy: fieldStudy,
    graduated: graduated,
    token: token,
    tokenExpiry: tokenExpiry,
    createdAt: DateTime(2024, 1, 1),
  );
}
