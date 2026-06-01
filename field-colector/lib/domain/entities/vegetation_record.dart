import 'base_record.dart';
import 'plot.dart';
import 'photo.dart';

/// Entidad que representa un registro botánico o de vegetación.
/// 
/// Hereda de [BaseRecord] e incluye información técnica y dasométrica 
/// sobre las características de especímenes o parcelas de flora.
class VegetationRecord extends BaseRecord {
  /// Identificador de la especie vegetal en el catálogo.
  final String speciesId;

  /// Nombre científico introducido manualmente si no está en el catálogo.
  final String speciesFreeText;

  /// Nombre común o local con el que se conoce a la planta.
  final String commonName;

  /// Origen de la especie (e.g. nativa, endémica, exótica).
  final String origin;

  /// Hábito o tipo de vegetación (e.g. árbol, arbusto, herbácea).
  final String vegetationType;

  /// Altura total estimada o medida del individuo (en metros).
  final double? height;

  /// Diámetro medido del tronco o tallo.
  final double? diameter;

  /// Tipo de medición del diámetro (e.g. CAP, DAP).
  final String? diameterType;

  /// Longitud o amplitud de la copa del árbol (en metros).
  final double? canopyLength;

  /// Fisonomía o apariencia general de la formación vegetal.
  final String physiognomy;

  /// Porcentaje estimado de cobertura vegetal en la parcela (0-100).
  final int? coveragePercent;

  /// Patrón de distribución de la cobertura (e.g. homogénea, parcheada).
  final String? coverageDistribution;

  /// Estado fitosanitario o condición física del individuo.
  final String physicalCondition;

  /// Indica si hay evidencia de acción del fuego (pirogenia).
  final bool hasPyrogeny;

  /// Descripción detallada de las marcas o impactos por fuego.
  final String? pyrogenyDescription;

  /// Tipo o estado de la cobertura del suelo bajo el dosel.
  final String groundCover;

  /// Parcela de muestreo asociada a este registro de vegetación.
  final Plot plot;

  /// Fotografías del espécimen, hojas, flores o parcela.
  final List<Photo> photos;

  VegetationRecord({
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
    required this.speciesId,
    required this.speciesFreeText,
    required this.commonName,
    required this.origin,
    required this.vegetationType,
    this.height,
    this.diameter,
    this.diameterType,
    this.canopyLength,
    required this.physiognomy,
    this.coveragePercent,
    this.coverageDistribution,
    required this.physicalCondition,
    required this.hasPyrogeny,
    this.pyrogenyDescription,
    required this.groundCover,
    required this.plot,
    required this.photos,
  });
}
