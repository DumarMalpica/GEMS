/// Preferencias de la app persistidas localmente (singleton en Isar).
class AppSettings {
  const AppSettings({
    this.gpsAccuracy = GpsAccuracyLevel.balanced,
    this.locationUpdateIntervalSeconds = 22,
    this.coordinateFormat = CoordinateFormat.decimal,
    this.defaultZoom = 15,
    this.showLocationMarker = true,
    this.mapType = MapDisplayType.standard,
  });

  /// Nivel de precisión del GPS deseado.
  final GpsAccuracyLevel gpsAccuracy;

  /// Intervalo en segundos para la actualización de la ubicación.
  final int locationUpdateIntervalSeconds;

  /// Formato de coordenadas (decimal o grados/minutos/segundos).
  final CoordinateFormat coordinateFormat;

  /// Nivel de zoom por defecto al abrir el mapa.
  final double defaultZoom;

  /// Determina si se debe mostrar el marcador de ubicación actual del usuario.
  final bool showLocationMarker;

  /// Tipo de visualización del mapa (estándar, relieve, satélite).
  final MapDisplayType mapType;

  AppSettings copyWith({
    GpsAccuracyLevel? gpsAccuracy,
    int? locationUpdateIntervalSeconds,
    CoordinateFormat? coordinateFormat,
    double? defaultZoom,
    bool? showLocationMarker,
    MapDisplayType? mapType,
  }) {
    return AppSettings(
      gpsAccuracy: gpsAccuracy ?? this.gpsAccuracy,
      locationUpdateIntervalSeconds:
          locationUpdateIntervalSeconds ?? this.locationUpdateIntervalSeconds,
      coordinateFormat: coordinateFormat ?? this.coordinateFormat,
      defaultZoom: defaultZoom ?? this.defaultZoom,
      showLocationMarker: showLocationMarker ?? this.showLocationMarker,
      mapType: mapType ?? this.mapType,
    );
  }
}

/// Nivel de precisión GPS (tradeoff batería / exactitud).
enum GpsAccuracyLevel {
  high('high', 'Alta'),
  balanced('balanced', 'Equilibrada'),
  low('low', 'Ahorro de batería');

  const GpsAccuracyLevel(this.id, this.label);

  final String id;
  final String label;

  static GpsAccuracyLevel fromId(String id) {
    return GpsAccuracyLevel.values.firstWhere(
      (e) => e.id == id,
      orElse: () => GpsAccuracyLevel.balanced,
    );
  }
}

/// Formato de visualización de coordenadas.
enum CoordinateFormat {
  decimal('decimal', 'Grados decimales'),
  dms('dms', 'Grados, minutos, segundos');

  const CoordinateFormat(this.id, this.label);

  final String id;
  final String label;

  static CoordinateFormat fromId(String id) {
    return CoordinateFormat.values.firstWhere(
      (e) => e.id == id,
      orElse: () => CoordinateFormat.decimal,
    );
  }
}

/// Tipo de capa base del mapa (solo visualización en línea).
enum MapDisplayType {
  standard('standard', 'Estándar (OpenStreetMap)'),
  terrain('terrain', 'Relieve (OpenTopoMap)'),
  satellite('satellite', 'Satélite');

  const MapDisplayType(this.id, this.label);

  final String id;
  final String label;

  static MapDisplayType fromId(String id) {
    return MapDisplayType.values.firstWhere(
      (e) => e.id == id,
      orElse: () => MapDisplayType.standard,
    );
  }

  /// Plantilla URL para [TileLayer.urlTemplate].
  String get urlTemplate {
    switch (this) {
      case MapDisplayType.standard:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapDisplayType.terrain:
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
      case MapDisplayType.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    }
  }

  String get attribution {
    switch (this) {
      case MapDisplayType.standard:
        return 'OpenStreetMap';
      case MapDisplayType.terrain:
        return 'OpenTopoMap · OpenStreetMap';
      case MapDisplayType.satellite:
        return 'Esri World Imagery';
    }
  }
}
