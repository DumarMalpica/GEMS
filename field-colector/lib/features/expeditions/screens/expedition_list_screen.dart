import 'dart:async';

import 'package:field_colector/core/services/expedition_sync_service.dart';
import 'package:field_colector/core/services/offline_expedition_service.dart';
import 'package:field_colector/domain/entities/offline_pin_progress.dart';
import 'package:field_colector/domain/entities/outing.dart';
import 'package:field_colector/domain/ports/outing_local_port.dart';
import 'package:field_colector/features/auth/providers/auth_provider.dart';
import 'package:field_colector/features/expeditions/providers/field_session_provider.dart';
import 'package:field_colector/features/expeditions/screens/expedition_create_screen.dart';
import 'package:field_colector/features/expeditions/screens/expedition_detail_screen.dart';
import 'package:field_colector/features/map/map_services.dart';
import 'package:latlong2/latlong.dart';
import 'package:field_colector/features/expeditions/widgets/expedition_card.dart';
import 'package:field_colector/features/utilities/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Pantalla principal de expediciones.
///
/// Contiene:
/// - Input de búsqueda
/// - Sección de expediciones disponibles (sin seleccionar)
/// - Sección de expediciones seleccionadas (con check + badge offline)
///
/// Al marcar el checkbox, la expedición se descarga localmente para uso offline.
/// Al tocar una tarjeta (no el check), se abre el detalle en el mismo espacio.
class ExpeditionListScreen extends StatefulWidget {
  const ExpeditionListScreen({super.key, this.onNavigateToLocation});

  final ValueChanged<LatLng>? onNavigateToLocation;

  @override
  State<ExpeditionListScreen> createState() => _ExpeditionListScreenState();
}

class _ExpeditionListScreenState extends State<ExpeditionListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Outing> _outings = [];
  bool _loading = true;
  String? _loadError;
  bool _isOffline = false;

  /// IDs que están actualmente descargándose.
  final Set<String> _downloadingIds = {};

  /// Cuando no es null, se muestra el detalle de esta expedición.
  Outing? _detailOuting;

  /// Cuando es true, se muestra la pantalla de creación.
  bool _showCreate = false;

  FieldSessionProvider? _fieldSessionListened;
  int _seenEnterFieldEpoch = 0;
  StreamSubscription<OfflinePinProgress>? _progressSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenProgress();
      _loadOutings();
    });
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _fieldSessionListened?.removeListener(_onFieldSessionChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final field = context.read<FieldSessionProvider>();
    if (!identical(_fieldSessionListened, field)) {
      _fieldSessionListened?.removeListener(_onFieldSessionChanged);
      _fieldSessionListened = field;
      _seenEnterFieldEpoch = field.enterFieldEpoch;
      _fieldSessionListened!.addListener(_onFieldSessionChanged);
    }
  }

  void _onFieldSessionChanged() {
    final field = _fieldSessionListened!;
    if (field.enterFieldEpoch <= _seenEnterFieldEpoch) return;
    setState(() {
      _seenEnterFieldEpoch = field.enterFieldEpoch;
      _detailOuting = null;
      _showCreate = false;
    });
  }

  void _listenProgress() {
    final offlineService = context.read<OfflineExpeditionService>();
    _progressSub = offlineService.progress.listen((event) {
      if (!mounted) return;
      setState(() {
        if (event.state == OfflinePinState.downloading) {
          _downloadingIds.add(event.outingId);
        } else {
          _downloadingIds.remove(event.outingId);
        }
      });

      // Mostrar feedback al usuario
      if (event.state == OfflinePinState.done) {
        _showSnack('📌 ${event.message ?? "Expedición disponible offline"}');
      } else if (event.state == OfflinePinState.error) {
        _showSnack('⚠️ ${event.message ?? "Error al descargar"}');
      }
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadOutings({bool forceRemoteSync = false}) async {
    setState(() {
      if (!forceRemoteSync) _loading = true;
      _loadError = null;
    });

    try {
      final reachability = context.read<MapServices>().reachability;
      final hasNet = await reachability.hasConnectivityNow();
      _isOffline = !hasNet;

      // 1. Mostrar lo local de inmediato para que la UI no quede bloqueada
      await _fetchAndShowLocalOutings();

      // 2. Si hay red, sincronizar remotamente en background
      if (hasNet) {
        final auth = context.read<Authprovider>();
        final userId = auth.user?.id;
        if (userId != null && userId.isNotEmpty) {
          final syncFuture = context
              .read<ExpeditionSyncService>()
              .syncExpeditionsForUser(userId)
              .then((_) => _fetchAndShowLocalOutings())
              .catchError((_) {}); // Evitar crashes si falla la red en background

          // Si el usuario forzó la recarga con swipe down, esperamos a que termine
          if (forceRemoteSync) {
            await syncFuture;
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _fetchAndShowLocalOutings() async {
    final allOutings = await context.read<OutingLocalPort>().getAllOutings();
    final pinnedIds = context.read<OfflineExpeditionService>().pinnedIds;

    if (!mounted) return;
    setState(() {
      if (_isOffline) {
        // Offline: solo mostrar las pinned que están en Isar
        _outings = allOutings.where((o) => pinnedIds.contains(o.id)).toList();
      } else {
        // Online: mostrar todas
        _outings = allOutings;
      }
      _loading = false;
    });
  }

  Set<String> get _pinnedIds =>
      context.read<OfflineExpeditionService>().pinnedIds;

  List<Outing> get _filtered {
    if (_searchQuery.isEmpty) return _outings;
    final q = _searchQuery.toLowerCase();
    return _outings.where((o) {
      return o.name.toLowerCase().contains(q) ||
          o.prefix.toLowerCase().contains(q) ||
          o.location.toLowerCase().contains(q) ||
          o.zone.toLowerCase().contains(q);
    }).toList();
  }

  List<Outing> get _unselected =>
      _filtered.where((o) => !_pinnedIds.contains(o.id)).toList();

  List<Outing> get _selected =>
      _filtered.where((o) => _pinnedIds.contains(o.id)).toList();

  Future<void> _onCheckChanged(Outing outing, bool checked) async {
    final offlineService = context.read<OfflineExpeditionService>();

    if (checked) {
      // Pin: descargar para offline
      await offlineService.pinExpedition(outing.id);
      if (mounted) setState(() {});
    } else {
      // Unpin: confirmar antes de borrar datos locales
      final confirmed = await _showUnpinDialog(outing.name);
      if (confirmed == true) {
        await offlineService.unpinExpedition(outing.id);
        if (mounted) {
          setState(() {});
          _showSnack('Expedición desmarcada de offline');
        }
      }
    }
  }

  Future<bool?> _showUnpinDialog(String name) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitar de offline'),
        content: Text(
          '¿Desmarcar "$name" del modo offline?\n\n'
          'Los registros sincronizados de esta expedición se borrarán '
          'del almacenamiento local. Los registros pendientes de subir '
          'se conservarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Desmarcar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Create mode ──
    if (_showCreate) {
      return ExpeditionCreateScreen(
        onBack: () {
          setState(() => _showCreate = false);
          _loadOutings();
        },
      );
    }

    // ── Detail mode ──
    if (_detailOuting != null) {
      return ExpeditionDetailScreen(
        outing: _detailOuting!,
        onBack: () {
          setState(() => _detailOuting = null);
          _loadOutings();
        },
        onNavigateToLocation: widget.onNavigateToLocation,
      );
    }

    // ── List mode ──
    return Column(
      children: [
        // ── Offline banner ──
        if (_isOffline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.accent.withValues(alpha: 0.15),
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_off,
                  size: 16,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Sin conexión – Mostrando expediciones guardadas',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ── Search bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar expedición...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () => setState(() => _showCreate = true),
                icon: const Icon(Icons.add, size: 22),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                ),
                tooltip: 'Nueva expedición',
              ),
            ],
          ),
        ),

        // ── Scrollable list ──
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  : (_unselected.isEmpty && _selected.isEmpty)
                      ? Center(
                          child: Text(
                            _isOffline
                                ? 'No hay expediciones guardadas offline'
                                : 'Sin resultados',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () =>
                              _loadOutings(forceRemoteSync: true),
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                            if (_unselected.isNotEmpty) ...[
                              _SectionHeader(
                                title: 'Expediciones disponibles',
                                count: _unselected.length,
                              ),
                              ..._unselected.map(
                                (o) => ExpeditionCard(
                                  outing: o,
                                  isSelected: false,
                                  isDownloading: _downloadingIds.contains(o.id),
                                  onCheckChanged: (_) =>
                                      _onCheckChanged(o, true),
                                  onTap: () =>
                                      setState(() => _detailOuting = o),
                                ),
                              ),
                            ],
                            if (_selected.isNotEmpty) ...[
                              _SectionHeader(
                                title: 'Disponibles offline',
                                count: _selected.length,
                              ),
                              ..._selected.map(
                                (o) => ExpeditionCard(
                                  outing: o,
                                  isSelected: true,
                                  isDownloading: _downloadingIds.contains(o.id),
                                  onCheckChanged: (_) =>
                                      _onCheckChanged(o, false),
                                  onTap: () =>
                                      setState(() => _detailOuting = o),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                          ],
                          ),
                        ),
        ),
      ],
    );
  }
}

// ── Section header ──────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
