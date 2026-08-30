import 'package:field_colector/core/services/expedition_sync_service.dart';
import 'package:field_colector/core/services/user_cache_service.dart';
import 'package:field_colector/domain/entities/outing.dart';
import 'package:field_colector/domain/entities/user.dart';
import 'package:field_colector/domain/outing_member_display.dart';
import 'package:field_colector/domain/ports/outing_local_port.dart';
import 'package:field_colector/domain/ports/outing_remote_port.dart';
import 'package:field_colector/features/records/screens/record_list_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:field_colector/features/map/download/map_tile_download_flow.dart';
import 'package:field_colector/features/map/map_services.dart';
import 'package:field_colector/features/utilities/theme/app_colors.dart';
import 'package:field_colector/features/utilities/widgets/detail_field.dart';
import 'package:field_colector/features/utilities/widgets/detail_section_title.dart';
import 'package:field_colector/features/auth/providers/auth_provider.dart';
import 'package:field_colector/features/export/providers/export_provider.dart';
import 'package:field_colector/features/expeditions/providers/field_session_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Pantalla de detalle de una expedición.
///
/// Muestra todos los campos del [Outing], nombre del director (resuelto por
/// `createdById`), listas de participantes y solicitantes, y botones de
/// acción en la parte inferior.
class ExpeditionDetailScreen extends StatefulWidget {
  const ExpeditionDetailScreen({
    super.key,
    required this.outing,
    required this.onBack,
    this.onNavigateToLocation,
  });

  final Outing outing;
  final VoidCallback onBack;
  final ValueChanged<LatLng>? onNavigateToLocation;

  @override
  State<ExpeditionDetailScreen> createState() => _ExpeditionDetailScreenState();
}

class _ExpeditionDetailScreenState extends State<ExpeditionDetailScreen> {
  late Outing _outing;
  Map<String, User> _userMap = {};
  bool _showRecordList = false;
  bool _isDownloadingMap = false;
  bool _isJoining = false;
  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();
    _outing = widget.outing;
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshOuting());
  }

  Future<void> _refreshOuting({bool forceRemoteSync = false}) async {
    if (forceRemoteSync) {
      try {
        await context
            .read<ExpeditionSyncService>()
            .syncOutingById(_outing.id);
      } catch (_) {}
    }

    final fresh =
        await context.read<OutingLocalPort>().getOutingById(_outing.id);
    if (fresh == null || !mounted) return;

    final sessionUser = context.read<Authprovider>().user;
    final ids = {
      fresh.createdById,
      ...fresh.participantIds,
    };
    final users = await context.read<UserCacheService>().resolveUsers(
          ids,
          sessionUser: sessionUser,
        );

    await _backfillParticipantProfiles(fresh, users);

    if (!mounted) return;
    final updated =
        await context.read<OutingLocalPort>().getOutingById(_outing.id);
    setState(() {
      _outing = updated ?? fresh;
      _userMap = users;
    });
  }

  /// Añade perfiles embebidos para IDs legacy sin entrada en [participants].
  Future<void> _backfillParticipantProfiles(
    Outing outing,
    Map<String, User> resolved,
  ) async {
    final knownIds = outing.participants.map((m) => m.id).toSet();
    final toAdd = <OutingMember>[];

    final idsToFill = {
      ...outing.participantIds,
      if (outing.createdById.isNotEmpty) outing.createdById,
    };
    for (final id in idsToFill) {
      if (knownIds.contains(id)) continue;
      final user = resolved[id];
      if (user == null) continue;
      toAdd.add(OutingMember(
        id: id,
        name: user.fullName,
        email: user.email,
      ));
    }

    if (toAdd.isEmpty) return;

    final newParticipants = [...outing.participants, ...toAdd];
    final local = context.read<OutingLocalPort>();
    final remote = context.read<OutingRemotePort>();
    final payload = {
      'participants': newParticipants.map((m) => m.toMap()).toList(),
    };
    await local.updateOuting(outing.id, payload);
    try {
      await remote.updateOuting(outing.id, payload);
    } catch (_) {}
  }

  User? _userById(String id) => _userMap[id];

  String _memberLabel(String id, {OutingMember? member}) => memberDisplayLabel(
        id: id,
        member: member ?? _outing.memberById(id),
        resolved: _userById(id),
      );

  String? _memberSubtitle(String id, String label, {OutingMember? member}) =>
      memberDisplaySubtitle(
        id: id,
        member: member ?? _outing.memberById(id),
        resolved: _userById(id),
        label: label,
      );

  String _outingStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Activa';
      case 'closed':
        return 'Cerrada';
      default:
        return status;
    }
  }

  String _syncStatusLabel(String syncStatus) {
    switch (syncStatus) {
      case 'synced':
        return 'Sincronizada';
      case 'pending':
        return 'Pendiente';
      case 'error':
        return 'Error';
      default:
        return syncStatus;
    }
  }

  bool _isOwner(String currentUserId) => _outing.createdById == currentUserId;

  bool _alreadyPending(String currentUserId) =>
      _outing.pendingUsers.any((u) => u.id == currentUserId);

  bool _canEnterField(String currentUserId) => _outing.isMember(currentUserId);

  Future<void> _requestJoin(User? currentUser) async {
    if (currentUser == null || _isJoining) return;

    final pending = PendingUser(
      id: currentUser.id,
      name: currentUser.fullName,
      email: currentUser.email,
    );

    setState(() => _isJoining = true);
    try {
      final local = context.read<OutingLocalPort>();
      final remote = context.read<OutingRemotePort>();
      await local.addPendingUserToOuting(_outing.id, pending);
      try {
        await remote.addPendingUserToOuting(_outing.id, pending);
      } catch (_) {
        // Offline: queda en local; sync_service puede reintentar.
      }
      await _refreshOuting();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud enviada'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al solicitar: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  Future<void> _acceptUser(PendingUser pu) async {
    if (_isAccepting) return;

    final newParticipantIds = [..._outing.participantIds, pu.id];
    final newParticipants = [
      ..._outing.participants,
      OutingMember(id: pu.id, name: pu.name, email: pu.email),
    ];
    final updatePayload = {
      'participantIds': newParticipantIds,
      'participants': newParticipants.map((m) => m.toMap()).toList(),
    };

    setState(() => _isAccepting = true);
    try {
      final local = context.read<OutingLocalPort>();
      final remote = context.read<OutingRemotePort>();
      await local.updateOuting(_outing.id, updatePayload);
      await local.removePendingUserFromOuting(_outing.id, pu.id);
      try {
        await remote.updateOuting(_outing.id, updatePayload);
        await remote.removePendingUserFromOuting(_outing.id, pu.id);
      } catch (_) {}
      await _refreshOuting();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al aprobar: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  Future<void> _enterFieldMode(String currentUserId) async {
    final ok = await context.read<FieldSessionProvider>().enterFieldMode(
          outingId: _outing.id,
          userId: currentUserId,
        );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes entrar en campo en esta expedición'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _exportRecords() async {
    final export = context.read<ExportProvider>();
    final prefix =
        _outing.prefix.isNotEmpty ? _outing.prefix : _outing.name;
    final ok = await export.exportByOuting(
      outingId: _outing.id,
      filePrefix: prefix,
    );
    if (!mounted) return;
    if (!ok && export.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(export.errorMessage!),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _downloadMap() async {
    final services = context.read<MapServices>();

    final place = await showDialog<OutingPlace>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Elige lugar para descargar'),
        children: _outing.places
            .map(
              (place) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, place),
                child: ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(place.name),
                  subtitle: Text(
                    '${place.latitude.toStringAsFixed(4)}, '
                    '${place.longitude.toStringAsFixed(4)}',
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
    if (place == null || !mounted) return;

    final picked = await MapTileDownloadFlow.showDownloadDialog(
      context: context,
      initialName: place.name,
    );
    if (picked == null || !mounted) return;

    final (name, radiusKm) = picked;

    setState(() => _isDownloadingMap = true);

    try {
      await services.downloadMap.execute(
        lat: place.latitude,
        lon: place.longitude,
        radius: radiusKm,
        name: name,
        outingId: _outing.id,
        placeId: place.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mapa descargado con éxito'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloadingMap = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showRecordList) {
      return RecordListScreen(
        outingId: _outing.id,
        onBack: () => setState(() => _showRecordList = false),
        onNavigateToLocation: widget.onNavigateToLocation,
      );
    }

    final currentUser = context.watch<Authprovider>().user;
    final export = context.watch<ExportProvider>();
    final currentUserId = currentUser?.id ?? '';
    final dateFormat = DateFormat('dd MMM yyyy', 'es');
    final directorLabel = _memberLabel(_outing.createdById);
    final directorSubtitle =
        _memberSubtitle(_outing.createdById, directorLabel);

    return Column(
      children: [
        // ── Header with back ──
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _outing.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // ── Scrollable content ──
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _refreshOuting(forceRemoteSync: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
              // ── Director ──
              DetailSectionTitle('Director de expedición'),
              const SizedBox(height: 4),
              _InfoRow(
                icon: Icons.person,
                label: directorLabel,
                subtitle: directorSubtitle,
              ),
              const SizedBox(height: 16),

              // ── General info ──
              DetailSectionTitle('Información general'),
              const SizedBox(height: 8),
              DetailField(label: 'Prefijo', value: _outing.prefix),
              DetailField(label: 'Ubicación', value: _outing.location),
              DetailField(label: 'Zona', value: _outing.zone),
              DetailField(label: 'Razón', value: _outing.reason),
               DetailSectionTitle('Lugares (${_outing.places.length})'),
               const SizedBox(height: 8),
               ..._outing.places.map(
                 (place) => DetailField(
                   label: place.name,
                   value: '${place.latitude.toStringAsFixed(4)}, '
                       '${place.longitude.toStringAsFixed(4)} · '
                       '${place.altitude.toStringAsFixed(0)} m',
                 ),
               ),
              DetailField(
                label: 'Fecha inicio',
                value: dateFormat.format(_outing.startDate),
              ),
              DetailField(
                label: 'Fecha fin',
                value: dateFormat.format(_outing.endDate),
              ),
              DetailField(
                label: 'Estado',
                value: _outingStatusLabel(_outing.status),
              ),
              DetailField(
                label: 'Sincronización',
                value: _syncStatusLabel(_outing.syncStatus),
              ),
              const SizedBox(height: 16),

              // ── Participants ──
              DetailSectionTitle(
                'Participantes (${_outing.participantIds.length})',
              ),
              const SizedBox(height: 8),
              ..._outing.participantIds.map((id) {
                final member = _outing.memberById(id);
                final label = _memberLabel(id, member: member);
                return _InfoRow(
                  icon: Icons.person_outline,
                  label: label,
                  subtitle: _memberSubtitle(id, label, member: member),
                );
              }),
              const SizedBox(height: 16),

              // ── Pending users ──
              DetailSectionTitle(
                'Solicitantes (${_outing.pendingUsers.length})',
              ),
              const SizedBox(height: 8),
              if (_outing.pendingUsers.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(
                    'Sin solicitudes pendientes',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                ..._outing.pendingUsers.map(
                  (pu) => _InfoRow(
                    icon: Icons.hourglass_empty,
                    label: pu.name,
                    subtitle: pu.email,
                    trailing: _isOwner(currentUserId)
                        ? IconButton(
                            icon: const Icon(Icons.check_circle, color: AppColors.primary),
                            onPressed: _isAccepting ? null : () => _acceptUser(pu),
                          )
                        : null,
                  ),
                ),

              const SizedBox(height: 24),
            ],
            ),
          ),
        ),

        // ── Bottom action buttons (vertical) ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Listar registros
              OutlinedButton.icon(
                onPressed: () => setState(() => _showRecordList = true),
                icon: const Icon(Icons.list_alt, size: 18),
                label: const Text('Registros'),
              ),
              const SizedBox(height: 8),

              // Descargar mapa
              OutlinedButton.icon(
                onPressed: _isDownloadingMap ? null : _downloadMap,
                icon: _isDownloadingMap
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download, size: 18),
                label: Text(
                  _isDownloadingMap ? 'Descargando...' : 'Descargar mapa',
                ),
              ),
              const SizedBox(height: 8),

              OutlinedButton.icon(
                onPressed: export.isExporting ? null : _exportRecords,
                icon: export.isExporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.file_download_outlined, size: 18),
                label: Text(
                  export.isExporting
                      ? 'Exportando...'
                      : 'Exportar registros',
                ),
              ),
              const SizedBox(height: 8),

              // Solicitar unirse (solo si no eres propietario ni participante)
              if (!_canEnterField(currentUserId)) ...[
                ElevatedButton.icon(
                  onPressed: _isJoining ||
                          _alreadyPending(currentUserId) ||
                          currentUser == null
                      ? null
                      : () => _requestJoin(currentUser),
                  icon: Icon(
                    _alreadyPending(currentUserId) ? Icons.check : Icons.person_add,
                    size: 18,
                  ),
                  label: Text(
                    _alreadyPending(currentUserId)
                        ? 'Pendiente'
                        : _isJoining
                            ? 'Enviando...'
                            : 'Solicitar unirse',
                  ),
                ),
                const SizedBox(height: 8),
              ],

              if (_canEnterField(currentUserId))
                ElevatedButton.icon(
                  onPressed: currentUserId.isEmpty
                      ? null
                      : () => _enterFieldMode(currentUserId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  icon: const Icon(Icons.explore, size: 18),
                  label: const Text('En campo'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Helper widgets ──────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
