import 'base_record.dart';
import 'photo.dart';
import 'plot.dart';

/// Entidad que representa un registro edafológico o de suelos.
/// 
/// Hereda de [BaseRecord] e incluye información técnica sobre las características
/// del suelo (textura, estructura, color), muestras recolectadas y la parcela de medición.
class SoilRecord extends BaseRecord {
  /// Lista de clasificaciones de tipos de suelo identificados.
  final List<String> soilTypes;

  /// Texto libre para tipos de suelo no estandarizados.
  final String? soilTypeFreeText;

  /// Color predominante del suelo (usualmente con tabla Munsell).
  final String dominantColor;

  /// Variabilidad del color u otras manchas en el perfil.
  final String colorVariability;

  /// Descriptores de la textura del suelo (e.g. arcilloso, franco, arenoso).
  final List<String> texture;

  /// Texto libre para descripción de textura.
  final String? textureFreeText;

  /// Estructura de los agregados del suelo (e.g. bloques, granular, prismática).
  final String structure;

  /// Texto libre para descripción de estructura.
  final String? structureFreeText;

  /// Descripción de los horizontes o el perfil del suelo examinado.
  final String soilProfile;

  /// Indica si se recolectó una muestra física de suelo.
  final bool hasSample;

  /// Código o identificador de la muestra física.
  final String? sampleId;

  /// Profundidad a la cual se extrajo la muestra (en cm/m).
  final double? sampleDepth;

  /// Observaciones adicionales sobre la zona o la calicata.
  final String observations;

  /// Información sobre las dimensiones de la parcela (plot) si se utilizó.
  final Plot plot;

  /// Fotografías del terreno, el perfil del suelo o la muestra.
  final List<Photo> photos;

  SoilRecord({
    required super.id,
    required super.outingId,
    required super.userId,
    required super.recordedAt,
    required super.coordinates,
    required super.department,
    required super.municipality,
    required super.village,
    required super.sector,
    required super.syncStatus,
    required this.soilTypes,
    this.soilTypeFreeText,
    required this.dominantColor,
    required this.colorVariability,
    required this.texture,
    this.textureFreeText,
    required this.structure,
    this.structureFreeText,
    required this.soilProfile,
    required this.hasSample,
    this.sampleId,
    this.sampleDepth,
    required this.observations,
    required this.plot,
    required this.photos,
  });
}
