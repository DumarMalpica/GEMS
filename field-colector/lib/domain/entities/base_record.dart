import 'coordinate.dart';

/// Entidad base que encapsula las propiedades comunes de cualquier registro de campo.
/// 
/// Todos los registros específicos (aves, rocas, etc.) extienden esta clase para
/// compartir la misma estructura básica de identificación y geolocalización.
abstract class BaseRecord {
  /// Identificador único del registro (UUID).
  final String id;

  /// Identificador de la expedición a la que pertenece el registro.
  final String outingId;

  /// Identificador del usuario que creó el registro.
  final String userId;

  /// Fecha y hora exacta de la toma de datos.
  final DateTime recordedAt;

  /// Coordenadas geográficas y altitud asociadas al registro.
  final Coordinate coordinates;

  /// Departamento de ubicación administrativa.
  final String department;

  /// Municipio de ubicación administrativa.
  final String municipality;

  /// Vereda u organización territorial local.
  final String village;

  /// Sector específico dentro de la vereda o municipio.
  final String sector;

  /// Estado de sincronización (e.g., 'pending', 'synced').
  final String syncStatus;

  BaseRecord({
    required this.id,
    required this.outingId,
    required this.userId,
    required this.recordedAt,
    required this.coordinates,
    required this.department,
    required this.municipality,
    required this.village,
    required this.sector,
    required this.syncStatus,
  });
}
