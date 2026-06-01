import '../entities/bird_record.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Puerto remoto para la gestión de registros de aves (BirdRecord).
/// 
/// Define los métodos que deben ser implementados por el adaptador remoto
/// para interactuar con el backend de Firebase Firestore.
abstract class BirdRecordRemotePort {
  /// Guarda un nuevo [BirdRecord] en la base de datos remota.
  Future<void> saveBirdRecord(BirdRecord item);

  /// Actualiza un [BirdRecord] existente identificado por [id] con los datos de [data].
  Future<void> updateBirdRecord(String id, Map<String, dynamic> data);

  /// Elimina un [BirdRecord] de la base de datos remota mediante su [id].
  Future<void> deleteBirdRecord(String id);

  /// Recupera un [BirdRecord] específico utilizando su [id]. Retorna null si no existe.
  Future<BirdRecord?> getBirdRecordById(String id);

  /// Obtiene una lista paginada de registros de aves.
  /// 
  /// Utiliza [limit] para la cantidad de resultados y [lastDocument] como cursor de paginación.
  Future<BirdRecordSearchResult> getBirdRecords({int limit = 20, DocumentSnapshot? lastDocument});

  /// Obtiene todos los registros de aves aplicables para la exportación a Excel.
  /// 
  /// Permite filtrar opcionalmente por [outingId], [userId], y un rango de fechas ([startDate], [endDate]).
  Future<List<BirdRecord>> getBirdRecordsForExport({String? outingId, String? userId, DateTime? startDate, DateTime? endDate});

  /// Escucha en tiempo real (Stream) los registros de una expedición específica ([outingId]).
  /// 
  /// Utilizado principalmente para actualizar marcadores en el mapa en vivo.
  Stream<List<BirdRecord>> watchBirdRecordsByOuting(String outingId);
}

/// Clase auxiliar que envuelve el resultado de una consulta paginada de registros de aves.
/// 
/// Contiene la lista de [items] obtenidos y el [lastDocument] utilizado para la siguiente consulta.
class BirdRecordSearchResult {
  /// Lista de registros obtenidos.
  final List<BirdRecord> items;
  
  /// Documento que marca el final de la página actual para continuar la paginación.
  final DocumentSnapshot? lastDocument;

  BirdRecordSearchResult({required this.items, this.lastDocument});
}
