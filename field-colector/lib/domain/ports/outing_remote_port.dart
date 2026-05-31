import '../entities/outing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Puerto remoto para la gestión de Expediciones (Outing).
/// 
/// Define el contrato para la sincronización de salidas de campo con el backend remoto.
abstract class OutingRemotePort {
  /// Guarda una nueva expedición ([Outing]) en la base de datos remota.
  Future<void> saveOuting(Outing item);

  /// Actualiza una expedición existente utilizando su [id] y un mapa de [data].
  Future<void> updateOuting(String id, Map<String, dynamic> data);

  /// Elimina de forma permanente una expedición ([id]) del servidor remoto.
  Future<void> deleteOuting(String id);

  /// Recupera una expedición específica según su [id].
  Future<Outing?> getOutingById(String id);

  /// Obtiene una lista paginada de todas las expediciones disponibles.
  Future<OutingSearchResult> getOutings({int limit = 20, DocumentSnapshot? lastDocument});

  /// Consulta expediciones creadas por un usuario en específico ([userId]).
  Future<OutingSearchResult> getOutingsByCreatorId(String userId, {int limit = 20, DocumentSnapshot? lastDocument});

  /// Consulta expediciones donde el [userId] sea participante activo o invitado.
  Future<OutingSearchResult> getOutingsByParticipantId(String userId, {int limit = 20, DocumentSnapshot? lastDocument});

  /// Agrega un usuario pendiente ([PendingUser]) a una expedición (invitación).
  Future<void> addPendingUserToOuting(String outingId, PendingUser user);

  /// Elimina a un usuario de la lista de pendientes (cancelar o declinar invitación).
  Future<void> removePendingUserFromOuting(String outingId, String userId);

  /// Obtiene la lista de usuarios que aún no han aceptado la invitación a la expedición.
  Future<List<PendingUser>> getPendingUsersByOutingId(String outingId);
}

/// Clase auxiliar para encapsular los resultados paginados de expediciones.
class OutingSearchResult {
  /// Lista de expediciones obtenidas.
  final List<Outing> items;

  /// Documento que marca el final de la página actual para futuras consultas.
  final DocumentSnapshot? lastDocument;

  OutingSearchResult({required this.items, this.lastDocument});
}
