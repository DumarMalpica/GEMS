import 'role.dart';

/// Entidad pura de dominio que representa a un usuario del sistema.
/// Sin anotaciones de Isar ni dependencias de Flutter.
///
/// El [token] y [tokenExpiry] permiten validar sesión offline sin internet.
/// El [fullName] autocompleta el campo "Observador" en todos los formularios.
class User {
  /// Firebase UID (Identificador único).
  final String id;

  /// Correo electrónico asociado a la cuenta.
  final String email;

  /// Nombre completo del usuario.
  final String fullName;

  /// Campo de estudio o disciplina (e.g. 'Biología', 'Geología').
  final String? fieldStudy;

  /// Indica si el usuario es graduado (profesional) o estudiante.
  final bool graduated;

  /// Rol asignado dentro del sistema que dicta sus permisos generales.
  final Role role;

  /// JWT retornado por Firebase Auth. Guardado en Isar para validación offline.
  final String? token;

  /// Fin de ventana de sesión offline (app); JWT de Firebase sigue siendo corto.
  final DateTime? tokenExpiry;

  /// Indica si el usuario está activo en la plataforma o fue deshabilitado.
  final bool isActive;

  /// Fecha de registro de la cuenta en el sistema.
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.fieldStudy,
    this.graduated = false,
    this.token,
    this.tokenExpiry,
    this.isActive = true,
    this.createdAt,
  });

  /// Alias para compatibilidad con código existente que use .userName
  String get userName => fullName;

  /// Retorna true si el token existe y no ha expirado.
  bool get hasValidToken {
    if (token == null || tokenExpiry == null) return false;
    return DateTime.now().isBefore(tokenExpiry!);
  }

  bool hasPermission(String permission) => role.hasPermission(permission);

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? fieldStudy,
    bool? graduated,
    Role? role,
    String? token,
    DateTime? tokenExpiry,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      fieldStudy: fieldStudy ?? this.fieldStudy,
      graduated: graduated ?? this.graduated,
      role: role ?? this.role,
      token: token ?? this.token,
      tokenExpiry: tokenExpiry ?? this.tokenExpiry,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is User && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'User(id: $id, email: $email, role: ${role.id})';
}