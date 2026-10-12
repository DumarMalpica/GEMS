/// Entidad pura de dominio — perfil de acceso dentro del sistema.
/// Sin anotaciones de Isar ni dependencias de Flutter.
///
/// Roles de acceso y distintivos de usuario:
///   - [admin]: acceso total al sistema, puede crear/cerrar expediciones y exportar.
///   - [user]: usuario base. Sus permisos de registro dependen de su
///     membresía a una expedición, no de este rol.
///   - [unicor] y [legacy]: distintivos sin permisos adicionales.
class Role {
  /// Identificador único del rol (e.g. 'admin', 'user').
  final String id;

  /// Nombre descriptivo del rol (e.g. 'Administrador', 'Usuario').
  final String name;

  /// Lista de claves de permisos específicos asignados a este rol.
  final List<String> permissions;

  /// Cuando true, el usuario tiene acceso irrestricto sin importar permissions.
  final bool isAdmin;

  const Role({
    required this.id,
    required this.name,
    required this.permissions,
    this.isAdmin = false,
  });

  /// Verifica si este rol tiene un permiso específico.
  /// Si isAdmin es true, siempre retorna true.
  bool hasPermission(String permission) {
    if (isAdmin) return true;
    return permissions.contains(permission);
  }

  // ── Roles predefinidos del sistema ──────────────────────────────────────────

  /// Administrador — acceso total al sistema.
  static const Role admin = Role(
    id: 'admin',
    name: 'Administrador',
    permissions: [],
    isAdmin: true,
  );

  /// Usuario base — sus permisos de registro dependen de su membresía
  /// a una expedición, no de este rol.
  static const Role user = Role(
    id: 'user',
    name: 'Usuario',
    permissions: [],
    isAdmin: false,
  );

  static const Role unicor = Role(
    id: 'unicor',
    name: 'Unicor',
    permissions: [],
  );

  static const Role legacy = Role(
    id: 'legacy',
    name: 'Legacy',
    permissions: [],
  );

  /// Retorna rol conocido o conserva identificador desconocido sin permisos.
  static Role fromId(String id) {
    final normalizedId = id.trim().toLowerCase();
    switch (normalizedId) {
      case 'admin':
        return admin;
      case 'unicor':
        return unicor;
      case 'legacy':
        return legacy;
      case 'user':
        return user;
      default:
        return Role(
          id: normalizedId,
          name: normalizedId,
          permissions: const [],
        );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Role && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Role($id)';
}
