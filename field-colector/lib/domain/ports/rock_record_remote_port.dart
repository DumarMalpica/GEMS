import '../entities/rock_record.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Puerto remoto para la gestión de registros geológicos (RockRecord).
/// 
/// Define los métodos para guardar, actualizar, consultar y escuchar registros de rocas en Firestore.
abstract class RockRecordRemotePort {
  /// Guarda un nuevo [RockRecord] en el servidor.
  Future<void> saveRockRecord(RockRecord item);

  /// Actualiza los campos especificados en [data] para un registro de roca dado su [id].
  Future<void> updateRockRecord(String id, Map<String, dynamic> data);

  /// Elimina permanentemente un registro de roca ([id]).
  Future<void> deleteRockRecord(String id);

  /// Recupera un registro de roca por su [id].
  Future<RockRecord?> getRockRecordById(String id);

  /// Obtiene de forma paginada un listado de registros de rocas.
  Future<RockRecordSearchResult> getRockRecords({int limit = 20, DocumentSnapshot? lastDocument});

  /// Consulta todos los registros de rocas filtrables para exportación a Excel.
  Future<List<RockRecord>> getRockRecordsForExport({String? outingId, String? userId, DateTime? startDate, DateTime? endDate});

  /// Stream para observar en tiempo real los registros de rocas correspondientes a una expedición ([outingId]).
  Stream<List<RockRecord>> watchRockRecordsByOuting(String outingId);
}

/// Encapsula una lista paginada de registros de rocas.
class RockRecordSearchResult {
  /// Registros resultantes.
  final List<RockRecord> items;

  /// Cursor de paginación para la siguiente consulta.
  final DocumentSnapshot? lastDocument;

  RockRecordSearchResult({required this.items, this.lastDocument});
}
