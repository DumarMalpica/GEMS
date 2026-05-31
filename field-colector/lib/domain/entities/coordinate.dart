/// Representa una ubicación geográfica capturada por el dispositivo.
/// 
/// Incluye información de latitud, longitud, altitud y la precisión del GPS
/// en el momento de la captura, así como un flag indicando si fue editada manualmente.
class Coordinate {
  /// Latitud en grados decimales.
  final double latitude;

  /// Longitud en grados decimales.
  final double longitude;

  /// Altitud en metros sobre el nivel del mar.
  final double altitude;

  /// Margen de error o precisión del GPS en metros.
  final double gpsAccuracy;

  /// Indica si el usuario ajustó la coordenada manualmente en el mapa.
  final bool manuallyEdited;

  Coordinate({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.gpsAccuracy,
    required this.manuallyEdited,
  });

  /// Indica si las coordenadas son valores finitos y válidos.
  bool get isFinite =>
      latitude.isFinite && longitude.isFinite && altitude.isFinite;
}
