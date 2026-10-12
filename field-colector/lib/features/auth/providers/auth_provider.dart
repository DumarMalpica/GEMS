import 'package:field_colector/core/services/session_validation_service.dart';
import 'package:field_colector/domain/entities/session_status.dart';
import 'package:field_colector/domain/entities/user.dart';
import 'package:field_colector/domain/mappers/login_user.dart';
import 'package:field_colector/domain/mappers/register_user_dto_builder.dart';
import 'package:field_colector/domain/ports/auth_port.dart';
import 'package:field_colector/domain/ports/registration_role_port.dart';
import 'package:field_colector/domain/ports/user_remote_port.dart';
import 'package:flutter/material.dart';

/// Estado de autenticación de la app: orquesta [AuthPort] (login, sesión, cierre).
///
/// **Responsabilidad:** mantener [user] y notificar a la UI. [register]
/// delega en [AuthPort.register]. Persistencia de token
/// y validación offline quedan en el **adaptador** inyectado, no en este
/// provider.
///
/// **Flujo de arranque:** [HomeScreen] llama [restoreSession] en `initState`;
/// mientras [isLoading] es true, no asumir autenticado. [isAuthenticated] exige
/// [User.hasValidToken] (token + `tokenExpiry` no vencido).
class Authprovider extends ChangeNotifier {
  Authprovider({
    required AuthPort authPort,
    required RegistrationRolePort registrationRole,
    required UserRemotePort userRemote,
    required SessionValidationService sessionValidation,
  }) : _authPort = authPort,
       _registrationRole = registrationRole,
       _userRemote = userRemote,
       _sessionValidation = sessionValidation;

  final AuthPort _authPort;
  final RegistrationRolePort _registrationRole;
  final UserRemotePort _userRemote;
  final SessionValidationService _sessionValidation;

  User? _user;

  bool _isLoading = true;
  String? _errorMessage;
  AuthErrorType? _lastAuthError;
  SessionStatus? _lastSessionStatus;
  // ponytail: counter resets after process restart; persist it if cross-restart limits matter.
  int _profileReads = 0;

  bool get isLoading => _isLoading;

  User? get user => _user;

  String? get token => _user?.token;

  /// Mensaje tras fallo en [login] / [register]. Null si no hubo error reciente de auth.
  String? get errorMessage => _errorMessage;

  /// Tipo del último [AuthException] en [login] / [register]. Null si no hubo fallo reciente.
  AuthErrorType? get lastAuthError => _lastAuthError;

  /// Último resultado de [restoreSession] (validación local). Null hasta primer restore.
  SessionStatus? get lastSessionStatus => _lastSessionStatus;

  bool get canReadRemoteProfile => _profileReads < 2;
  bool get hasReadRemoteProfile => _profileReads > 0;

  void _setUser(User user) {
    if (_user?.id != user.id) {
      _profileReads = 0;
    }
    _user = user;
  }

  Future<User?> readRemoteProfile() async {
    final current = _user;
    if (current == null || !canReadRemoteProfile) return null;
    _profileReads++;
    return _userRemote.getUserById(current.id);
  }

  void _setAuthFailure(AuthException e) {
    _errorMessage = e.message;
    _lastAuthError = e.type;
    notifyListeners();
  }

  /// Limpia [errorMessage] / [lastAuthError] tras edición en formularios (evita mensaje obsoleto).
  void clearAuthFormError() {
    if (_errorMessage == null && _lastAuthError == null) return;
    _errorMessage = null;
    _lastAuthError = null;
    notifyListeners();
  }

  /// Aplica usuario restaurado desde el puerto (token válido) o limpia sesión.
  void _applySessionUser(User? restored) {
    if (restored != null && restored.hasValidToken) {
      _setUser(restored);
      _errorMessage = null;
      _lastAuthError = null;
    } else {
      _user = null;
    }
  }

  /// Prioridad: primero sesión offline válida ([AuthPort.validateOfflineSession]),
  /// si no hay, usuario activo ([AuthPort.getCurrentUser]).
  Future<void> _loadSessionFromPort() async {
    User? restored = await _authPort.validateOfflineSession();
    restored ??= await _authPort.getCurrentUser();
    _applySessionUser(restored);
  }

  Future<void> logout() async {
    await _authPort.logout();
    _user = null;
    _lastSessionStatus = null;
    _errorMessage = null;
    _lastAuthError = null;
    _profileReads = 0;
    notifyListeners();
  }

  Future<void> login(LoginUser credentials) async {
    try {
      var domainUser = await _authPort.login(
        credentials.email,
        credentials.password,
      );
      _setUser(domainUser);
      try {
        final remote = await readRemoteProfile();
        if (remote != null) {
          domainUser = remote.copyWith(
            token: domainUser.token,
            tokenExpiry: domainUser.tokenExpiry,
          );
          await _authPort.updateProfile(domainUser);
        }
      } catch (_) {
        // Correo y contraseña mantienen acceso offline si Firestore no responde.
      }
      _setUser(domainUser);
      _lastSessionStatus = null;
      _errorMessage = null;
      _lastAuthError = null;
      notifyListeners();
    } on AuthException catch (e) {
      _user = null;
      _setAuthFailure(e);
    } catch (_) {
      _user = null;
      _setAuthFailure(
        const AuthException(
          message: 'No se pudo cargar tu perfil. Intenta de nuevo.',
          type: AuthErrorType.networkError,
        ),
      );
    }
  }

  Future<bool> loginWithExternalProvider() async {
    try {
      final result = await _authPort.loginWithExternalProvider();
      if (result == null) return false;

      var user = result.user;
      _setUser(user);
      final remote = await readRemoteProfile();
      final isNewProfile = result.isNewUser || remote == null;
      if (isNewProfile) {
        user = user.copyWith(
          profileComplete: false,
          role: _registrationRole.roleForRegistration(DateTime.now().toUtc()),
        );
        try {
          await _userRemote.saveUser(user);
        } catch (_) {
          try {
            await _authPort.updateProfile(user);
          } catch (_) {}
          rethrow;
        }
      } else {
        user = remote.copyWith(
          token: user.token,
          tokenExpiry: user.tokenExpiry,
          profileComplete: remote.profileComplete,
        );
        await _authPort.updateProfile(user);
      }

      _setUser(user);
      _lastSessionStatus = null;
      _errorMessage = null;
      _lastAuthError = null;
      notifyListeners();
      return isNewProfile;
    } on AuthException catch (e) {
      _user = null;
      _setAuthFailure(e);
      return false;
    } catch (_) {
      _user = null;
      _setAuthFailure(
        AuthException(
          message: 'No se pudo cargar tu perfil. Intenta de nuevo.',
          type: AuthErrorType.networkError,
        ),
      );
      return false;
    }
  }

  /// Registro vía [AuthPort]; en éxito deja sesión como [login].
  Future<void> register(RegisterUserDto dto) async {
    try {
      final domainUser = await _authPort.register(
        email: dto.email,
        password: dto.password,
        fullName: dto.fullName,
        fieldStudy: dto.fieldOfStudy,
      );
      final registered = domainUser.copyWith(
        role: _registrationRole.roleForRegistration(DateTime.now().toUtc()),
      );
      await _userRemote.saveUser(registered);
      await _authPort.updateProfile(registered);
      _setUser(registered);
      _lastSessionStatus = null;
      _errorMessage = null;
      _lastAuthError = null;
      notifyListeners();
    } on AuthException catch (e) {
      _user = null;
      _setAuthFailure(e);
    }
  }

  Future<void> completeExternalProfile(RegisterUserDto dto) async {
    final current = _user;
    if (current == null) return;

    try {
      final completed = current.copyWith(
        fullName: dto.fullName,
        fieldStudy: dto.fieldOfStudy,
        graduated: dto.graduated,
        profileComplete: true,
      );
      if (completed.fullName.trim().split(RegExp(r'\s+')).length < 2 ||
          (completed.fieldStudy?.trim().isEmpty ?? true)) {
        throw const AuthException(
          message: 'Completa tu nombre, apellido y área de estudio.',
          type: AuthErrorType.unknown,
        );
      }
      await _userRemote.saveUser(completed);
      await _authPort.updateProfile(completed);
      _user = completed;
      _errorMessage = null;
      _lastAuthError = null;
      notifyListeners();
    } on AuthException catch (e) {
      _setAuthFailure(e);
    } catch (_) {
      _setAuthFailure(
        const AuthException(
          message: 'No se pudo guardar tu perfil. Intenta de nuevo.',
          type: AuthErrorType.networkError,
        ),
      );
    }
  }

  /// Vuelve a leer sesión desde el puerto sin overlay de carga.
  ///
  /// [AuthPort] no define renovación JWT explícita aún; esto solo re-hidrata.
  // TODO: cuando exista renovación real (Firebase / refresh endpoint), llamarla
  // desde aquí o desde el adaptador y luego actualizar [_user].
  Future<void> refreshToken() async {
    await _loadSessionFromPort();
    notifyListeners();
  }

  /// Arranque en frío: validación local con códigos; si token vencido, intenta refresco vía red.
  Future<void> restoreSession() async {
    _isLoading = true;
    notifyListeners();
    try {
      final session = await _sessionValidation.validate();
      _lastSessionStatus = session.status;

      switch (session.status) {
        case SessionStatus.valid:
          if (session.user != null) {
            _setUser(session.user!);
            _errorMessage = null;
            _lastAuthError = null;
          } else {
            _user = null;
          }
          break;
        case SessionStatus.expired:
          final refreshed = await _authPort.getCurrentUser();
          _applySessionUser(refreshed);
          if (_user == null) {
            _errorMessage = 'Sesión expirada. Inicie sesión de nuevo.';
            _lastAuthError = null;
          }
          break;
        case SessionStatus.notFound:
        case SessionStatus.corrupted:
          _user = null;
          _errorMessage = null;
          _lastAuthError = null;
          break;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool get isAuthenticated => _user?.hasValidToken ?? false;
}
