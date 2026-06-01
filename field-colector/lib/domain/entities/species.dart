/// Entidad que representa una especie catalogada (flora o fauna).
/// 
/// Utilizada como diccionario maestro o base de datos de referencia para
/// asociar las observaciones de campo con especies taxonómicamente válidas.
class Species {
  /// Identificador único de la especie.
  final String id;

  /// Nombre científico oficial.
  final String scientificName;

  /// Nombre común o vernáculo.
  final String commonName;

  /// Rama biológica (e.g. 'Aves', 'Plantas', 'Insectos').
  final String branch;

  /// Fuente de la información (e.g. GBIF, Catálogo local).
  final String source;

  /// ID del usuario que registró esta especie en la base de datos (si fue agregada manualmente).
  final String createdById;

  Species({
    required this.id,
    required this.scientificName,
    required this.commonName,
    required this.branch,
    required this.source,
    required this.createdById,
  });
}
