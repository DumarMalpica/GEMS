import '../entities/vegetation_record.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Puerto remoto para la gestión de registros de vegetación (VegetationRecord).
/// 
/// Interfaz que establece cómo interactúa el dominio con la base de datos remota para registros de flora.
abstract class VegetationRecordRemotePort {
  /// Guarda un nuevo [VegetationRecord] en la base de datos en la nube.
  Future<void> saveVegetationRecord(VegetationRecord item);

  /// Actualiza los atributos específicos en [data] para un registro de vegetación identificado por [id].
  Future<void> updateVegetationRecord(String id, Map<String, dynamic> data);

  /// Elimina un [VegetationRecord] del backend mediante su [id].
  Future<void> deleteVegetationRecord(String id);

  /// Recupera un registro de vegetación mediante su [id]. Retorna null si no se encuentra.
  Future<VegetationRecord?> getVegetationRecordById(String id);

  /// Obtiene registros de vegetación de manera paginada.
  Future<VegetationRecordSearchResult> getVegetationRecords({int limit = 20, DocumentSnapshot? lastDocument});

  /// Descarga los registros de vegetación filtrados por expedición, usuario y rango de fechas (para exportación a Excel).
  Future<List<VegetationRecord>> getVegetationRecordsForExport({String? outingId, String? userId, DateTime? startDate, DateTime? endDate});

  /// Crea un flujo de datos en tiempo real (Stream) de los registros de vegetación vinculados a una [outingId].
  Stream<List<VegetationRecord>> watchVegetationRecordsByOuting(String outingId);
}

/// Estructura de resultados de paginación para registros de vegetación.
class VegetationRecordSearchResult {
  /// Registros de vegetación obtenidos en el lote actual.
  final List<VegetationRecord> items;

  /// Documento que marca el final de este lote para pedir el siguiente.
  final DocumentSnapshot? lastDocument;

  VegetationRecordSearchResult({required this.items, this.lastDocument});
}
