/// Entidad que representa la parcela o área delimitada de muestreo de suelo o vegetación.
class Plot {
  /// Indica si se estableció una parcela para la medición.
  final bool hasPlot;

  /// Altura o largo de la parcela (en metros).
  final double? height;

  /// Ancho de la parcela (en metros).
  final double? width;

  Plot({
    required this.hasPlot,
    this.height,
    this.width,
  });
}
