import 'package:field_colector/domain/entities/user.dart';
import 'package:field_colector/features/auth/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';

/// Perfil enriquecido desde Firestore con caché en memoria (sin Isar).
///
/// [logout] limpia caché y delega en [Authprovider.logout].
class ProfileProvider extends ChangeNotifier {
  ProfileProvider({required Authprovider auth}) : _auth = auth {
    _auth.addListener(_onAuthChanged);
  }

  final Authprovider _auth;

  User? _cachedProfile;
  bool _isLoading = false;
  String? _errorMessage;
  bool get isLoading => _isLoading;

  bool get canRefresh => _auth.canReadRemoteProfile;

  String? get errorMessage => _errorMessage;

  /// Usuario mostrado: caché tras fetch, o sesión auth mientras carga / si no hay doc remoto.
  User? get profileUser {
    final authUser = _auth.user;
    if (authUser == null) return null;
    return _cachedProfile ?? authUser;
  }

  void _onAuthChanged() {
    final authUser = _auth.user;
    if (authUser == null) {
      _cachedProfile = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    if (_cachedProfile != null && _cachedProfile!.id != authUser.id) {
      _cachedProfile = null;
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Carga perfil remoto una vez por sesión de caché; [force] ignora caché.
  Future<void> loadProfile({bool force = false}) async {
    final authUser = _auth.user;
    if (authUser == null) {
      _cachedProfile = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (!force && _cachedProfile != null && _cachedProfile!.id == authUser.id) {
      return;
    }

    if (!force && _auth.hasReadRemoteProfile) {
      _cachedProfile = authUser;
      return;
    }

    if (_isLoading || !canRefresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final remote = await _auth.readRemoteProfile();
      if (remote != null) {
        _cachedProfile = _mergeRemoteWithAuthSession(remote, authUser);
      } else {
        _cachedProfile = authUser;
      }
      _errorMessage = null;
    } catch (_) {
      _errorMessage =
          'No se pudo sincronizar el perfil. Mostrando datos locales.';
      _cachedProfile = authUser;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  User _mergeRemoteWithAuthSession(User remote, User auth) {
    return remote.copyWith(
      token: auth.token,
      tokenExpiry: auth.tokenExpiry,
      fieldStudy: remote.fieldStudy ?? auth.fieldStudy,
      email: remote.email.isNotEmpty ? remote.email : auth.email,
      fullName: remote.fullName.isNotEmpty ? remote.fullName : auth.fullName,
      createdAt: remote.createdAt ?? auth.createdAt,
    );
  }

  Future<void> refresh() async {
    await loadProfile(force: true);
  }

  Future<void> logout() async {
    _cachedProfile = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
    await _auth.logout();
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
