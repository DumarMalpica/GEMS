/// Estado de la descarga offline de una expedición.
enum OfflinePinState {
  /// Descargando datos (outing + registros).
  downloading,

  /// Descarga completada con éxito.
  done,

  /// Error durante la descarga.
  error,
}

/// Progreso de pin/unpin de una expedición para uso offline.
class OfflinePinProgress {
  const OfflinePinProgress({
    required this.outingId,
    required this.state,
    this.message,
  });

  /// Identificador de la expedición que se está anclando para uso offline.
  final String outingId;

  /// Estado actual del proceso de anclaje (descarga).
  final OfflinePinState state;

  /// Mensaje descriptivo (opcional), usualmente utilizado para mostrar errores o detalles de progreso.
  final String? message;
}
