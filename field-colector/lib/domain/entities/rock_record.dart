import 'base_record.dart';
import 'photo.dart';

/// Entidad que representa un registro geológico o de roca.
/// 
/// Hereda de [BaseRecord] e incluye todos los atributos específicos para 
/// el muestreo y clasificación de rocas y minerales.
class RockRecord extends BaseRecord {
  /// Clasificación principal de la roca (e.g. ígnea, metamórfica, sedimentaria).
  final String rockType;

  /// Texto libre para especificar un tipo de roca no listado.
  final String? rockTypeFreeText;

  /// Color predominante de la muestra rocosa.
  final String dominantColor;

  /// Descriptores de la textura de la roca (e.g. afanítica, fanerítica).
  final List<String> texture;

  /// Estructura geológica de la roca (e.g. masiva, foliada).
  final String structure;

  /// Dureza estimada en la escala de Mohs u otra escala referencial.
  final String hardness;

  /// Minerales visibles o predominantes en la composición.
  final String minerals;

  /// Indica si se tomó una muestra física para laboratorio.
  final bool hasSample;

  /// Identificador alfanumérico o código de la muestra física.
  final String? sampleId;

  /// Profundidad a la que se tomó la muestra (en metros/centímetros).
  final double? sampleDepth;

  /// Notas u observaciones adicionales sobre la roca o el entorno geológico.
  final String observations;

  /// Fotos tomadas durante el registro.
  final List<Photo> photos;

  RockRecord({
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
    required this.rockType,
    this.rockTypeFreeText,
    required this.dominantColor,
    required this.texture,
    required this.structure,
    required this.hardness,
    required this.minerals,
    required this.hasSample,
    this.sampleId,
    this.sampleDepth,
    required this.observations,
    required this.photos,
  });
}
