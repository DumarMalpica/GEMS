import '../entities/species.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Puerto remoto para la gestión de Especies maestras (Species).
/// 
/// Expone las operaciones para administrar la lista de especies (aves, plantas) en Firestore.
abstract class SpeciesRemotePort {
  /// Almacena un nuevo registro de especie [item] en la base de datos remota.
  Future<void> saveSpecies(Species item);

  /// Modifica los campos dados en [data] para la especie identificada por [id].
  Future<void> updateSpecies(String id, Map<String, dynamic> data);

  /// Borra un registro de especie de Firestore mediante su [id].
  Future<void> deleteSpecies(String id);

  /// Consulta una especie específica por su [id].
  Future<Species?> getSpeciesById(String id);

  /// Devuelve una lista paginada de todas las especies registradas.
  Future<SpeciesSearchResult> getSpeciess({int limit = 20, DocumentSnapshot? lastDocument});
}

/// Contenedor de respuesta para las consultas paginadas de especies.
class SpeciesSearchResult {
  /// Lista de especies resultado de la consulta.
  final List<Species> items;

  /// Cursor para continuar obteniendo el resto de la lista.
  final DocumentSnapshot? lastDocument;

  SpeciesSearchResult({required this.items, this.lastDocument});
}
