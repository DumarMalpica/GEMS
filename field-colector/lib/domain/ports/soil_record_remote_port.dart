import '../entities/soil_record.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Puerto remoto para la gestión de registros de suelos (SoilRecord).
/// 
/// Interfaz que define las operaciones remotas (CRUD y consultas) sobre los registros de suelos en Firestore.
abstract class SoilRecordRemotePort {
  /// Persiste un nuevo [SoilRecord] en la nube.
  Future<void> saveSoilRecord(SoilRecord item);

  /// Actualiza los atributos de un registro de suelo ([id]) dados en [data].
  Future<void> updateSoilRecord(String id, Map<String, dynamic> data);

  /// Elimina un [SoilRecord] del servidor usando su [id].
  Future<void> deleteSoilRecord(String id);

  /// Obtiene un registro de suelo por su [id]. Retorna null si no existe.
  Future<SoilRecord?> getSoilRecordById(String id);

  /// Recupera una lista paginada de registros de suelos.
  Future<SoilRecordSearchResult> getSoilRecords({int limit = 20, DocumentSnapshot? lastDocument});

  /// Retorna los registros de suelos que coinciden con los filtros para exportar a Excel.
  Future<List<SoilRecord>> getSoilRecordsForExport({String? outingId, String? userId, DateTime? startDate, DateTime? endDate});

  /// Suscripción en tiempo real a los registros de suelos de una expedición ([outingId]).
  Stream<List<SoilRecord>> watchSoilRecordsByOuting(String outingId);
}

/// Envoltorio para resultados paginados de registros de suelos.
class SoilRecordSearchResult {
  /// Registros obtenidos.
  final List<SoilRecord> items;

  /// Documento que sirve de ancla para la próxima solicitud de página.
  final DocumentSnapshot? lastDocument;

  SoilRecordSearchResult({required this.items, this.lastDocument});
}
