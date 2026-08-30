// domain/usecases/download_map_use_case.dart

import 'package:field_colector/domain/entities/offline_area.dart';
import 'package:field_colector/domain/ports/maps/map_tile_cache.dart';
import 'package:field_colector/domain/ports/maps/offline_area_repository.dart';
import 'package:field_colector/domain/utils/geo_coords.dart';
import 'package:field_colector/domain/utils/offline_area_id.dart';

class DownloadMapUseCase {
  // 1. Recibe los puertos (interfaces), no las implementaciones.
  final OfflineAreaRepository _repository;
  final MapTileCache _tileCache;

  DownloadMapUseCase(this._repository, this._tileCache);

  /// Devuelve el id del área creada para enlazar caché de teselas / UI.
  Future<String> execute({
    required double lat,
    required double lon,
    required double radius,
    required String name,
    String? outingId,
    String? placeId,
  }) async {
    if (!isValidLatLng(lat, lon)) {
      throw ArgumentError('Coordenadas inválidas para descarga de mapa '
          '(lat: $lat, lon: $lon)');
    }

    final newArea = OfflineArea(
      id: generateOfflineAreaId(),
      name: name,
      outingId: outingId,
      placeId: placeId,
      centerLat: lat,
      centerLon: lon,
      radiusInKilometers: radius,
      minZoom: 1, // o el que necesites
      maxZoom: 18,
      status: AreaDownloadStatus.pending,
      createdAt: DateTime.now(),
    );

    // Pasos 4-7: Llama al puerto. El puerto ejecuta el IsarAdapter.
    await _repository.saveAreaMetadata(newArea);

    try {
      // Pasos 8-10: Llama al puerto. El puerto ejecuta el FmtcAdapter.
      await _tileCache.downloadRegion(
        lat: lat,
        lon: lon,
        radius: radius,
        areaId: newArea.id,
        minZoom: newArea.minZoom,
        maxZoom: newArea.maxZoom,
      );
      // Nota: Si usas streams para el progreso, esto sería un listen()

      // Pasos 14-18: Si la descarga termina sin errores, actualiza Isar
      final completedArea = newArea.copyWith(status: AreaDownloadStatus.completed);
      await _repository.saveAreaMetadata(completedArea);
      return completedArea.id;

    } catch (e) {
      // Manejo de error y actualización a estado failed
      final failedArea = newArea.copyWith(status: AreaDownloadStatus.failed);
      await _repository.saveAreaMetadata(failedArea);
      throw Exception('Fallo en la descarga: $e');
    }
  }
}
