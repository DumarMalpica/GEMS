import 'package:field_colector/domain/utils/geo_coords.dart';
import 'package:field_colector/features/map/map_services.dart';
import 'package:field_colector/features/utilities/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

/// Datos de ubicación seleccionados por el usuario.
class PickedLocation {
  final double latitude;
  final double longitude;
  final double altitude;

  const PickedLocation({
    required this.latitude,
    required this.longitude,
    required this.altitude,
  });
}

/// Widget reutilizable para seleccionar ubicación en mapa.
///
/// Flujo: buscar ciudad → mapa se centra → tap en mapa → lat/lon/alt rellenados.
/// Altitud es campo manual (geocoding / flutter_map no la dan).
///
/// Ligero: no arranca GPS timer, no lifecycle observer. Solo tiles + tap.
class LocationPickerWidget extends StatefulWidget {
  const LocationPickerWidget({
    super.key,
    this.initialLocation,
    required this.onLocationPicked,
  });

  /// Coordenada inicial (edición futura).
  final PickedLocation? initialLocation;

  /// Callback cuando usuario selecciona punto o cambia altitud.
  final ValueChanged<PickedLocation> onLocationPicked;

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  static const LatLng _defaultCenter = LatLng(5.5353, -73.3678); // Colombia
  static const String _storeId = 'field_preview';

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _altitudeController = TextEditingController();

  LatLng? _selectedPoint;
  bool _searching = false;
  String? _searchError;
  Future<void>? _ensureStoreFuture;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedPoint = tryLatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
      if (_selectedPoint != null) {
        _altitudeController.text =
            widget.initialLocation!.altitude.toStringAsFixed(0);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final services = context.read<MapServices>();
    _ensureStoreFuture ??= services.tileCache.ensureStoreExists(_storeId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _altitudeController.dispose();
    super.dispose();
  }

  void _emitLocation() {
    if (_selectedPoint == null) return;
    final alt = double.tryParse(_altitudeController.text) ?? 0;
    widget.onLocationPicked(
      PickedLocation(
        latitude: _selectedPoint!.latitude,
        longitude: _selectedPoint!.longitude,
        altitude: alt,
      ),
    );
  }

  void _onMapTap(TapPosition tapPos, LatLng point) {
    if (!isValidLatLng(point.latitude, point.longitude)) return;
    setState(() {
      _selectedPoint = point;
      _searchError = null;
    });
    _emitLocation();
  }

  Future<void> _searchCity() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _searching = true;
      _searchError = null;
    });

    try {
      final locations = await geo.Geocoding().locationFromAddress(query);
      if (locations.isEmpty) {
        setState(
          () => _searchError = 'Lugar no encontrado. Intenta otra búsqueda.',
        );
        return;
      }
      final loc = locations.first;
      final point = tryLatLng(loc.latitude, loc.longitude);
      if (point == null) {
        setState(
          () => _searchError = 'Lugar no encontrado. Intenta otra búsqueda.',
        );
        return;
      }

      setState(() {
        _selectedPoint = point;
        _searchError = null;
      });

      _mapController.move(point, 13);
      _emitLocation();
    } catch (_) {
      setState(
        () => _searchError = 'Lugar no encontrado. Intenta otra búsqueda.',
      );
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<MapServices>();
    final initialCenter = _selectedPoint ?? _defaultCenter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Search bar ──
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar ciudad o lugar...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchCity(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: _searching ? null : _searchCity,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: _searching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Buscar'),
              ),
            ),
          ],
        ),

        if (_searchError != null) ...[
          const SizedBox(height: 4),
          Text(
            _searchError!,
            style: const TextStyle(fontSize: 12, color: AppColors.error),
          ),
        ],

        const SizedBox(height: 12),

        // ── Map ──
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 260,
            child: FutureBuilder<void>(
              future: _ensureStoreFuture,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: 12,
                    minZoom: 3,
                    maxZoom: 19,
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: services.tileCache.rasterUrlTemplate,
                      userAgentPackageName: 'com.citesa.field_colector',
                      tileProvider: services.tileCache.getTileProvider(
                        _storeId,
                        offlineOnly: false,
                      ),
                    ),
                    if (_selectedPoint != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPoint!,
                            width: 36,
                            height: 36,
                            child: const Icon(
                              Icons.location_pin,
                              color: AppColors.error,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    SimpleAttributionWidget(
                      source: const Text('OpenStreetMap'),
                      onTap: () {},
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── Hint ──
        Text(
          _selectedPoint != null
              ? 'Toca el mapa para cambiar ubicación'
              : 'Toca el mapa para seleccionar ubicación',
          style: const TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 12),

        // ── Coordinate display + altitude ──
        if (_selectedPoint != null) ...[
          Row(
            children: [
              Expanded(
                child: _CoordChip(
                  label: 'Lat',
                  value: _selectedPoint!.latitude.toStringAsFixed(6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CoordChip(
                  label: 'Lon',
                  value: _selectedPoint!.longitude.toStringAsFixed(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _altitudeController,
            decoration: const InputDecoration(
              labelText: 'Altitud (m)',
              prefixIcon: Icon(Icons.terrain, size: 20),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            onChanged: (_) => _emitLocation(),
          ),
        ],
      ],
    );
  }
}

/// Chip que muestra una coordenada con etiqueta.
class _CoordChip extends StatelessWidget {
  const _CoordChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
