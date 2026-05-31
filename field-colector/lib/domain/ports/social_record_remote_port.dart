import '../entities/social_record.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Puerto remoto para la gestión de encuestas/registros sociales (SocialRecord).
/// 
/// Define la interfaz con la base de datos remota para crear, actualizar y consultar encuestas de campo.
abstract class SocialRecordRemotePort {
  /// Guarda un nuevo [SocialRecord] remotamente.
  Future<void> saveSocialRecord(SocialRecord item);

  /// Aplica los cambios en [data] al registro social identificado por [id].
  Future<void> updateSocialRecord(String id, Map<String, dynamic> data);

  /// Elimina un [SocialRecord] de Firestore.
  Future<void> deleteSocialRecord(String id);

  /// Retorna un [SocialRecord] específico si existe, o null si no.
  Future<SocialRecord?> getSocialRecordById(String id);

  /// Obtiene registros sociales de forma paginada utilizando un límite y un cursor de documento.
  Future<SocialRecordSearchResult> getSocialRecords({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  });

  /// Descarga los registros sociales disponibles filtrados por usuario, expedición y fechas para exportar a Excel.
  Future<List<SocialRecord>> getSocialRecordsForExport({
    String? outingId,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Devuelve un flujo continuo (Stream) de registros sociales vinculados a una salida de campo ([outingId]).
  Stream<List<SocialRecord>> watchSocialRecordsByOuting(String outingId);
}

/// Respuesta paginada de una consulta de registros sociales.
class SocialRecordSearchResult {
  /// Lista de registros obtenidos en esta página.
  final List<SocialRecord> items;

  /// Último documento obtenido, útil para continuar la paginación.
  final DocumentSnapshot? lastDocument;

  SocialRecordSearchResult({required this.items, this.lastDocument});
}
