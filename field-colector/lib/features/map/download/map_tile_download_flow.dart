import 'package:flutter/material.dart';

/// Orquestación de **descarga de teselas** (diálogo + [DownloadMapUseCase]).
///
/// No pertenece al widget de mapa: la vista solo **previsualiza** y muestra
/// pins; la descarga se decide en contexto de **expedición** (lugar
/// seleccionado, estado activo, etc.).
///
/// TODO(expedición): llamar desde la UI de expedición — botón "Descargar mapas".
/// TODO(expedición): si negocio exige descarga automática al activar expedición,
///    invocar aquí (o vía caso de uso) con lat/lon/radio del lugar seleccionado.
/// TODO(expedición): reemplazar diálogo genérico por flujo alineado a diseño.
class MapTileDownloadFlow {
  MapTileDownloadFlow._();

  /// Muestra diálogo (nombre + radio) para un lugar seleccionado.
  ///
  /// Retorna `(nombre, radio)` si OK; `null` si usuario cancela.
  static Future<(String, double)?> showDownloadDialog({
    required BuildContext context,
    double initialRadiusKm = 5,
    String initialName = 'Zona campo',
  }) async {
    final nameController = TextEditingController(text: initialName);
    var dialogRadius = initialRadiusKm;

    final picked = await showDialog<(String name, double radiusKm)?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Descargar mapa'),
          content: StatefulBuilder(
            builder: (context, setLocal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  const SizedBox(height: 12),
                  Text('Radio: ${dialogRadius.toStringAsFixed(1)} km'),
                  Slider(
                    value: dialogRadius,
                    min: 2,
                    max: 20,
                    divisions: 36,
                    label: '${dialogRadius.toStringAsFixed(1)} km',
                    onChanged: (v) => setLocal(() => dialogRadius = v),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final n = nameController.text.trim();
                Navigator.pop(ctx, (n.isEmpty ? 'Zona' : n, dialogRadius));
              },
              child: const Text('Descargar'),
            ),
          ],
        );
      },
    );

    return picked;
  }
}
