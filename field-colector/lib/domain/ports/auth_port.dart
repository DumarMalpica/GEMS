import '../entities/user.dart';

/// Puerto de autenticación.
abstract class AuthPort {
  /// Autentica con email y contraseña.
  /// Lanza [AuthException] si las credenciales son incorrectas.
  Future<User> login(String email, String password);

  /// Inicia sesión o crea una cuenta con el proveedor externo configurado.
  /// Retorna null si el usuario cancela el flujo.
  Future<ExternalAuthResult?> loginWithExternalProvider();

  /// Registra un nuevo usuario. [fullName] es obligatorio (autocompleta Observador).
  Future<User> register({
    required String email,
    required String password,
    required String fullName,
    String? fieldStudy,
  });

  /// Cierra sesión y limpia el token local.
  Future<void> logout();

  /// Retorna el usuario activo, o null si no hay sesión.
  Future<User?> getCurrentUser();

  /// Valida sesión offline usando el token guardado (sin internet).
  /// Retorna null si no hay token válido.
  Future<User?> validateOfflineSession();

  /// Persiste los datos de perfil actualizados en la sesión local.
  Future<void> updateProfile(User user);
}

/// Excepción de dominio — aísla la UI de excepciones de Firebase
class AuthException implements Exception {
  final String message;
  final AuthErrorType type;

  const AuthException({required this.message, required this.type});

  @override
  String toString() => 'AuthException(${type.name}): $message';
}

class ExternalAuthResult {
  const ExternalAuthResult({required this.user, required this.isNewUser});

  final User user;
  final bool isNewUser;
}

enum AuthErrorType {
  invalidCredentials,
  invalidEmail,
  emailAlreadyInUse,
  weakPassword,
  networkError,
  sessionExpired,
  tooManyRequests,
  unknown,
}
