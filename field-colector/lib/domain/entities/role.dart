/// Entidad pura de dominio — perfil de acceso dentro del sistema.
/// Sin anotaciones de Isar ni dependencias de Flutter.
///
/// El sistema maneja dos roles:
///   - [admin]: acceso total al sistema, puede crear/cerrar expediciones y exportar.
///   - [user]: usuario base. Sus permisos de registro dependen de su
///     membresía a una expedición, no de este rol.
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

  /// Retorna un Role por su id. Si no existe retorna [user] por defecto.
  static Role fromId(String id) {
    switch (id) {
      case 'admin':
        return admin;
      default:
        return user;
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