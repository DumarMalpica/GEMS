import '../entities/water_record.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Puerto remoto para la gestión de registros hidrológicos/agua (WaterRecord).
/// 
/// Interfaz para las operaciones CRUD y consultas de registros de agua en la base de datos remota.
abstract class WaterRecordRemotePort {
  /// Inserta un nuevo [WaterRecord] en la base de datos de Firestore.
  Future<void> saveWaterRecord(WaterRecord item);

  /// Modifica los campos proporcionados en [data] para un registro de agua específico ([id]).
  Future<void> updateWaterRecord(String id, Map<String, dynamic> data);

  /// Elimina de forma definitiva un registro de agua mediante su [id].
  Future<void> deleteWaterRecord(String id);

  /// Busca un [WaterRecord] por su [id]. Si no se halla, retorna null.
  Future<WaterRecord?> getWaterRecordById(String id);

  /// Realiza una consulta paginada para obtener una lista de registros de agua.
  Future<WaterRecordSearchResult> getWaterRecords({int limit = 20, DocumentSnapshot? lastDocument});

  /// Extrae la lista de registros de agua aplicando filtros opcionales (destinado para exportar a Excel).
  Future<List<WaterRecord>> getWaterRecordsForExport({String? outingId, String? userId, DateTime? startDate, DateTime? endDate});

  /// Suscripción para recibir actualizaciones instantáneas de los registros de agua de una expedición ([outingId]).
  Stream<List<WaterRecord>> watchWaterRecordsByOuting(String outingId);
}

/// Modelo que encapsula los resultados de la paginación de registros de agua.
class WaterRecordSearchResult {
  /// Lote de registros obtenidos.
  final List<WaterRecord> items;

  /// Documento que sirve como referencia para solicitar la siguiente página.
  final DocumentSnapshot? lastDocument;

  WaterRecordSearchResult({required this.items, this.lastDocument});
}
