// lib/core/map_downloader/domain/entities/offline_area.dart

/// Estado actual del proceso de descarga de un área para uso offline.
enum AreaDownloadStatus { pending, downloading, completed, failed }

/// Representa una zona del mapa descargada para su uso sin conexión a internet.
class OfflineArea {
  /// Identificador único del área descargada.
  final String id;

  /// Nombre legible asignado al área (Ej: "Transecto Biológico Zona A").
  final String name;

  /// Latitud central del área de descarga.
  final double centerLat;

  /// Longitud central del área de descarga.
  final double centerLon;

  /// Radio en kilómetros que abarca el área descargada desde el centro.
  final double radiusInKilometers;

  /// Nivel de zoom mínimo guardado.
  final int minZoom;

  /// Nivel de zoom máximo guardado.
  final int maxZoom;

  /// Estado de la descarga de los mapas.
  final AreaDownloadStatus status;

  /// Fecha de creación o de inicio de descarga.
  final DateTime createdAt;

  /// Tamaño estimado o real de los datos descargados (en bytes).
  final int estimatedSizeInBytes;

  const OfflineArea({
    required this.id,
    required this.name,
    required this.centerLat,
    required this.centerLon,
    required this.radiusInKilometers,
    required this.minZoom,
    required this.maxZoom,
    required this.status,
    required this.createdAt,
    this.estimatedSizeInBytes = 0,
  });

  // copyWith permite generar nuevas instancias actualizadas (ej. cambiar el status)
  // sin mutar el objeto original, respetando el diseño del dominio.
  OfflineArea copyWith({
    String? id,
    String? name,
    double? centerLat,
    double? centerLon,
    double? radiusInKilometers,
    int? minZoom,
    int? maxZoom,
    AreaDownloadStatus? status,
    DateTime? createdAt,
    int? estimatedSizeInBytes,
  }) {
    return OfflineArea(
      id: id ?? this.id,
      name: name ?? this.name,
      centerLat: centerLat ?? this.centerLat,
      centerLon: centerLon ?? this.centerLon,
      radiusInKilometers: radiusInKilometers ?? this.radiusInKilometers,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      estimatedSizeInBytes: estimatedSizeInBytes ?? this.estimatedSizeInBytes,
    );
  }
}
