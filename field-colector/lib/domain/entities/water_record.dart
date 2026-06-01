import 'base_record.dart';
import 'photo.dart';

/// Entidad que representa un registro hidrológico o de agua.
/// 
/// Hereda de [BaseRecord] y agrupa mediciones in situ de calidad del agua, 
/// estado de la fuente hídrica y detalles sobre muestras físicas recolectadas.
class WaterRecord extends BaseRecord {
  /// Condiciones climáticas en el momento del muestreo.
  final String weatherConditions;

  /// Nivel de visibilidad o claridad del agua visualmente.
  final String visibility;

  /// Facilidad o tipo de acceso a la fuente hídrica.
  final String access;

  /// Texto libre para describir vías o modos de acceso particulares.
  final String? accessFreeText;

  /// Profundidad (en metros) a la que se toma la muestra o se hacen las mediciones.
  final String samplingDepth;

  /// Potencial de hidrógeno medido in situ.
  final double? ph;

  /// Temperatura del agua en grados Celsius medidos in situ.
  final double? temperature;

  /// Conductividad eléctrica medida in situ.
  final double? conductivity;

  /// Oxígeno disuelto medido in situ (mg/L o porcentaje).
  final double? dissolvedOxygen;

  /// Nivel de turbidez medido in situ.
  final double? turbidity;

  /// Color aparente del agua por inspección visual.
  final String apparentColor;

  /// Presencia y tipo de olor emitido por la fuente hídrica.
  final String odor;

  /// Indica si se recolectó una muestra física de agua para laboratorio.
  final bool hasSample;

  /// Código o identificador de la muestra recolectada.
  final String? sampleId;

  /// Tipo de muestra obtenida (e.g. simple, compuesta).
  final String? sampleType;

  /// Tipo de recipiente utilizado para almacenar la muestra.
  final String? container;

  /// Propósito principal o análisis requerido para la muestra física.
  final String? samplingGoal;

  /// Fotografías del cuerpo de agua, el entorno o la muestra.
  final List<Photo> photos;

  WaterRecord({
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
    required this.weatherConditions,
    required this.visibility,
    required this.access,
    this.accessFreeText,
    required this.samplingDepth,
    this.ph,
    this.temperature,
    this.conductivity,
    this.dissolvedOxygen,
    this.turbidity,
    required this.apparentColor,
    required this.odor,
    required this.hasSample,
    this.sampleId,
    this.sampleType,
    this.container,
    this.samplingGoal,
    required this.photos,
  });
}
