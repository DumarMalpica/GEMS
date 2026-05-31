import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../domain/entities/user.dart';
import '../../domain/entities/role.dart';
import '../../domain/ports/auth_port.dart';
import '../../domain/ports/user_local_port.dart';

/// Ventana de sesión offline persistida (no cambia TTL del JWT de Firebase).
const Duration _persistedSessionValidity = Duration(days: 30);

/// Adaptador concreto que implementa [AuthPort] utilizando Firebase Authentication.
/// 
/// Esta clase encapsula toda la interacción con el SDK de Firebase Auth, manejando
/// el inicio de sesión, registro, cierre de sesión y la validación de la sesión actual.
class FirebaseAuthAdapter implements AuthPort {
  /// Instancia de FirebaseAuth inyectada para realizar las operaciones.
  final fb.FirebaseAuth _firebaseAuth;

  /// Puerto local inyectado para persistir la información del usuario en el dispositivo.
  final UserLocalPort _userLocalPort;

  /// Crea una nueva instancia de [FirebaseAuthAdapter] con las dependencias requeridas.
  FirebaseAuthAdapter(this._firebaseAuth, this._userLocalPort);

  /// Inicia sesión utilizando un correo electrónico ([email]) y una contraseña ([password]).
  /// 
  /// Si es exitoso, crea un objeto [User] de dominio, lo guarda localmente y lo retorna.
  /// Si falla, lanza un [AuthException] traducido del error original de Firebase.
  @override
  Future<User> login(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fbUser = credential.user;
      if (fbUser == null) {
        throw const AuthException(
          message: 'No se pudo obtener la información del usuario.',
          type: AuthErrorType.unknown,
        );
      }

      final tokenResult = await fbUser.getIdTokenResult();

      final user = User(
        id: fbUser.uid,
        email: fbUser.email ?? email,
        fullName: fbUser.displayName ?? 'Investigador',
        role: Role.user,
        token: tokenResult.token,
        tokenExpiry: DateTime.now().add(_persistedSessionValidity),
        createdAt: fbUser.metadata.creationTime,
      );

      await _userLocalPort.saveUser(user);

      return user;
    } on fb.FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    } catch (e) {
      throw AuthException(
        message: 'Error inesperado: $e',
        type: AuthErrorType.unknown,
      );
    }
  }

  /// Registra un nuevo usuario en Firebase Auth con los datos proporcionados.
  /// 
  /// El [fullName] se establece como el display name en Firebase. Una vez creado,
  /// el usuario se persiste de manera local y se retorna.
  @override
  Future<User> register({
    required String email,
    required String password,
    required String fullName,
    String? fieldStudy,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fbUser = credential.user!;
      await fbUser.updateDisplayName(fullName);

      final tokenResult = await fbUser.getIdTokenResult();

      final user = User(
        id: fbUser.uid,
        email: email,
        fullName: fullName,
        fieldStudy: fieldStudy,
        role: Role.user,
        token: tokenResult.token,
        tokenExpiry: DateTime.now().add(_persistedSessionValidity),
        createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
      );

      await _userLocalPort.saveUser(user);
      return user;
    } on fb.FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    } catch (e) {
      throw AuthException(
        message: 'Error inesperado: $e',
        type: AuthErrorType.unknown,
      );
    }
  }

  /// Cierra la sesión activa en Firebase y limpia los datos locales del usuario.
  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _userLocalPort.clearLocalUser();
  }

  /// Obtiene el usuario actualmente autenticado en Firebase (si lo hay).
  /// 
  /// Si el token aún es válido, renueva la fecha de expiración de la sesión local
  /// y retorna el [User]. Retorna null si no hay sesión activa.
  @override
  Future<User?> getCurrentUser() async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) return null;

    try {
      final tokenResult = await fbUser.getIdTokenResult();
      final user = User(
        id: fbUser.uid,
        email: fbUser.email ?? '',
        fullName: fbUser.displayName ?? 'Investigador',
        role: Role.user,
        token: tokenResult.token,
        tokenExpiry: DateTime.now().add(_persistedSessionValidity),
        createdAt: fbUser.metadata.creationTime,
      );
      await _userLocalPort.saveUser(user);
      return user;
    } catch (_) {
      return null;
    }
  }

  /// Valida si existe una sesión offline válida comprobando el token guardado localmente.
  @override
  Future<User?> validateOfflineSession() async {
    final localUser = await _userLocalPort.getLocalUser();

    if (localUser != null && localUser.hasValidToken) {
      return localUser;
    }
    return null;
  }

  /// Convierte las excepciones específicas de Firebase Auth ([fb.FirebaseAuthException]) 
  /// a excepciones de dominio controladas ([AuthException]).
  AuthException _handleFirebaseError(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return AuthException(
          message: 'Correo o contraseña incorrectos.',
          type: AuthErrorType.invalidCredentials,
        );
      case 'invalid-email':
        return AuthException(
          message: 'El formato del correo no es válido.',
          type: AuthErrorType.invalidEmail,
        );
      case 'weak-password':
        return AuthException(
          message:
              'La contraseña es demasiado débil. Use al menos 6 caracteres y combine letras y números.',
          type: AuthErrorType.weakPassword,
        );
      case 'email-already-in-use':
        return AuthException(
          message: 'El correo electrónico ya está registrado.',
          type: AuthErrorType.emailAlreadyInUse,
        );
      case 'network-request-failed':
        return AuthException(
          message: 'Error de red. Verifique su conexión.',
          type: AuthErrorType.networkError,
        );
      case 'too-many-requests':
        return AuthException(
          message:
              'Demasiados intentos. Espere unos minutos e intente de nuevo.',
          type: AuthErrorType.tooManyRequests,
        );
      case 'operation-not-allowed':
        return AuthException(
          message:
              'Esta operación no está habilitada. Contacte al administrador.',
          type: AuthErrorType.unknown,
        );
      default:
        return AuthException(
          message: e.message ?? 'Ocurrió un error en la autenticación.',
          type: AuthErrorType.unknown,
        );
    }
  }
}