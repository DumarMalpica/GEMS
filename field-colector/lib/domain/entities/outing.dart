/// Perfil embebido de usuario en una expedición (participante o solicitante).
class OutingMember {
  /// ID del usuario.
  final String id;

  /// Nombre completo del usuario.
  final String name;

  /// Correo electrónico del usuario.
  final String email;

  const OutingMember({
    required this.id,
    required this.name,
    required this.email,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
      };

  factory OutingMember.fromMap(Map<String, dynamic> map) => OutingMember(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        email: map['email'] ?? '',
      );
}

/// Solicitud pendiente de unión; misma forma que [OutingMember].
typedef PendingUser = OutingMember;

/// Representa una salida de campo o expedición.
/// 
/// Una expedición agrupa lógicamente múltiples registros biológicos, geológicos
/// y sociales en un marco temporal y espacial específico, controlando qué usuarios
/// pueden participar y aportar datos.
class Outing {
  /// Identificador único de la expedición (UUID).
  final String id;

  /// Prefijo o código corto de identificación (e.g. UPTC-24).
  final String prefix;

  /// Nombre completo de la expedición.
  final String name;

  /// Lugar o ubicación general descrita en texto.
  final String location;

  /// Zona o área específica (e.g., Zona Norte, Bosque Andino).
  final String zone;

  /// Motivo u objetivo de la salida de campo.
  final String reason;

  /// Latitud del punto central o de encuentro.
  final double latitude;

  /// Longitud del punto central o de encuentro.
  final double longitude;

  /// Altitud en metros sobre el nivel del mar.
  final double altitude;

  /// Fecha programada de inicio.
  final DateTime startDate;

  /// Fecha programada de finalización.
  final DateTime endDate;

  /// ID del usuario creador/administrador de la expedición.
  final String createdById;

  /// Lista de IDs de los participantes que han sido aprobados.
  final List<String> participantIds;

  /// Estado de la expedición (e.g., 'active', 'finished').
  final String status;

  /// Estado de sincronización en la base de datos local (e.g., 'synced').
  final String syncStatus;

  /// Lista de perfiles de los participantes aprobados.
  final List<OutingMember> participants;

  /// Lista de usuarios que han solicitado unirse y están pendientes de aprobación.
  final List<PendingUser> pendingUsers;

  Outing({
    required this.id,
    required this.prefix,
    required this.name,
    required this.location,
    required this.zone,
    required this.reason,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.startDate,
    required this.endDate,
    required this.createdById,
    required this.participantIds,
    required this.status,
    required this.syncStatus,
    this.participants = const [],
    this.pendingUsers = const [],
  });

  /// Dueño o participante aceptado; puede registrar en campo.
  bool isMember(String userId) =>
      createdById == userId || participantIds.contains(userId);

  /// Busca y retorna el perfil de un participante utilizando su [id].
  OutingMember? memberById(String id) {
    for (final m in participants) {
      if (m.id == id) return m;
    }
    return null;
  }
}
