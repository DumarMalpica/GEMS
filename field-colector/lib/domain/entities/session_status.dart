import 'user.dart';

/// Resultado de validar sesión local (offline).
enum SessionStatus {
  /// Token presente y vigente.
  valid,

  /// Token presente pero vencido.
  expired,

  /// No hay usuario local activo.
  notFound,

  /// Usuario local pero token o expiración ausentes o inconsistentes.
  corrupted,
}

/// Estructura que encapsula el resultado de la validación de sesión.
class SessionResult {
  const SessionResult({required this.status, this.user});

  /// Estado de la sesión resultante.
  final SessionStatus status;

  /// Usuario recuperado (solo presente si el status es valid o expired).
  final User? user;
}
