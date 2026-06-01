import 'base_record.dart';
import 'photo.dart';

/// Entidad que representa un registro de observación de aves.
/// 
/// Hereda de [BaseRecord] e incluye todos los atributos específicos requeridos
/// para el muestreo biológico de especies aviares.
class BirdRecord extends BaseRecord {
  /// Época del año o temporada en la que se realizó la observación.
  final String season;

  /// Descripción del lugar o hábitat inmediato donde se encontró el ave.
  final String place;

  /// Identificador de la especie observada (si está catalogada).
  final String speciesId;

  /// Tipo de ave según clasificación local o de estudio.
  final String birdType;

  /// Estado migratorio del ave (e.g., residente, migratoria).
  final String migratorStatus;

  /// Número de individuos contados en la observación.
  final int individualCount;

  /// Comportamiento observado del ave al momento del registro.
  final String behavior;

  /// Actividad principal que estaba realizando el ave.
  final String activity;

  /// Lista de tipos de hábitat donde se observó el ave.
  final List<String> habitat;

  /// Estrategia de forrajeo observada.
  final List<String> foragingType;

  /// Posibles amenazas observadas en el área para esta especie.
  final List<String> observedThreats;

  /// Fotos tomadas durante la observación.
  final List<Photo> photos;

  BirdRecord({
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
    required this.season,
    required this.place,
    required this.speciesId,
    required this.birdType,
    required this.migratorStatus,
    required this.individualCount,
    required this.behavior,
    required this.activity,
    required this.habitat,
    required this.foragingType,
    required this.observedThreats,
    required this.photos,
  });
}
