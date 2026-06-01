import 'base_record.dart';
import 'photo.dart';

/// Entidad que representa un registro o encuesta social (etnográfica/demográfica).
/// 
/// Hereda de [BaseRecord] y contiene las respuestas a cuestionarios aplicados a 
/// la comunidad para evaluar el uso del territorio, percepciones de cambio y 
/// acceso a recursos e información ambiental.
class SocialRecord extends BaseRecord {
  /// ID o documento de identidad (opcional o anonimizado) del encuestado.
  final String respondentId;

  /// Nombre del actor social encuestado.
  final String actorName;

  /// Tipo de actor social (e.g. campesino, líder comunitario, funcionario).
  final String actorType;

  /// Edad del encuestado.
  final double age;

  /// Género del encuestado (e.g. Femenino, Masculino, Otro).
  final String gender;

  /// Nivel educativo alcanzado.
  final String educationLevel;

  /// Actividad económica o laboral principal.
  final String mainActivity;

  /// Tiempo que lleva habitando en el territorio (en años).
  final double timeInTerritory;

  /// Municipio de ubicación u origen de la persona.
  final String? locationMunicipality;

  /// Vereda de ubicación u origen.
  final String? locationVillage;

  /// Nivel de dependencia económica de los recursos naturales.
  final String naturalResourceDependency;

  /// Percepción sobre cambios en la cobertura vegetal/uso del suelo.
  final String coverageChangePerception;

  /// Tipos de cambios observados en el entorno (si aplica).
  final String? observedChangeType;

  /// Participación en organizaciones comunitarias o gremiales.
  final String organizationParticipation;

  /// Nombre de la organización a la que pertenece (si aplica).
  final String? organizationName;

  /// Frecuencia de interacción con otros actores clave del territorio.
  final String actorInteractionFrequency;

  /// Actores clave con los que está conectado.
  final String? connectedKeyActors;

  /// Tipo de relación con las instituciones o actores clave (e.g. cooperación, conflicto).
  final String relationshipType;

  /// Nivel de confianza en las instituciones locales.
  final String trustLevel;

  /// Acceso a información de carácter ambiental.
  final String environmentalInfoAccess;

  /// Uso de tecnología para labores productivas o informativas.
  final String? technologyUse;

  /// Percepción sobre la conectividad del territorio (vías, comunicación).
  final String territorialConnectivity;

  /// Percepción sobre la fragmentación del paisaje local.
  final String fragmentationPerception;

  /// Cambios recientes en las prácticas productivas.
  final String productivePracticeChanges;

  /// Tipo de prácticas agropecuarias u otras (e.g. orgánicas, tradicionales).
  final String? practiceType;

  /// Impacto percibido en el paisaje debido a las actividades humanas.
  final String perceivedLandscapeImpact;

  /// Observaciones adicionales y notas abiertas del investigador.
  final String? observations;

  /// Fotografías adjuntas a la encuesta (evidencia, contexto).
  final List<Photo> photos;

  SocialRecord({
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
    required this.respondentId,
    required this.actorName,
    required this.actorType,
    required this.age,
    required this.gender,
    required this.educationLevel,
    required this.mainActivity,
    required this.timeInTerritory,
    this.locationMunicipality,
    this.locationVillage,
    required this.naturalResourceDependency,
    required this.coverageChangePerception,
    this.observedChangeType,
    required this.organizationParticipation,
    this.organizationName,
    required this.actorInteractionFrequency,
    this.connectedKeyActors,
    required this.relationshipType,
    required this.trustLevel,
    required this.environmentalInfoAccess,
    this.technologyUse,
    required this.territorialConnectivity,
    required this.fragmentationPerception,
    required this.productivePracticeChanges,
    this.practiceType,
    required this.perceivedLandscapeImpact,
    this.observations,
    this.photos = const [],
  });
}
