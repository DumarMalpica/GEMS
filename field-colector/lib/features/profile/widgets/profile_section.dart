import 'dart:async';

import 'package:field_colector/features/profile/providers/profile_provider.dart';
import 'package:field_colector/features/utilities/theme/app_colors.dart';
import 'package:field_colector/features/utilities/theme/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

/// Panel lateral: datos de usuario, refresco y cierre de sesión.
class ProfileSection extends StatefulWidget {
  const ProfileSection({super.key});

  @override
  State<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<ProfileProvider>().loadProfile());
    });
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    final a = parts.first.isNotEmpty ? parts.first[0] : '';
    final b = parts.last.isNotEmpty ? parts.last[0] : '';
    final pair = '$a$b';
    return pair.isEmpty ? '?' : pair.toUpperCase();
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar sesión en este dispositivo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (go == true && context.mounted) {
      await context.read<ProfileProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final user = profile.profileUser;

    if (user == null) {
      return const Center(
        child: Text('Sin sesión activa', style: AppStyles.body),
      );
    }
    final roleId = user.role.id.trim().toLowerCase();
    final styleRoleId = roleId == 'unicorn' ? 'unicor' : roleId;
    final isUnicor = styleRoleId == 'unicor';
    final isLegacy = styleRoleId == 'legacy';
    final roleColor = switch (styleRoleId) {
      'admin' => const Color(0xFFB3261E),
      'user' => const Color(0xFF1976D2),
      'unicor' => const Color(0xFFD52F9C),
      'legacy' => const Color(0xFFD6A52D),
      _ => AppColors.primary,
    };
    final roleBackground = switch (styleRoleId) {
      'admin' => const Color(0xFFFFF1F0),
      'user' => const Color(0xFFEAF3FF),
      'unicor' => const Color(0xFFFFF0F8),
      'legacy' => const Color(0xFFFFF8E5),
      _ => AppColors.surface,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Perfil',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (profile.isLoading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  tooltip: profile.canRefresh
                      ? 'Actualizar'
                      : 'Límite de 2 lecturas por sesión alcanzado',
                  onPressed: profile.canRefresh ? profile.refresh : null,
                  icon: Icon(Icons.refresh, color: AppColors.primary, size: 22),
                ),
            ],
          ),
        ),
        if (profile.errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              profile.errorMessage!,
              style: AppStyles.caption.copyWith(color: AppColors.error),
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Center(
                child: Container(
                  padding: EdgeInsets.all(isUnicor || isLegacy ? 7 : 0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLegacy ? const Color(0xFFFFE7A3) : null,
                    gradient: isUnicor
                        ? const SweepGradient(
                            colors: [
                              Color(0xFFFF4D8D),
                              Color(0xFFFFC857),
                              Color(0xFF53D6A5),
                              Color(0xFF54A8FF),
                              Color(0xFFB66DFF),
                              Color(0xFFFF4D8D),
                            ],
                          )
                        : null,
                  ),
                  child: CircleAvatar(
                    radius: 42,
                    backgroundColor: isLegacy
                        ? const Color(0xFFFFF8E5)
                        : isUnicor
                        ? const Color(0xFF472275)
                        : roleColor,
                    child: Text(
                      _initials(user.fullName),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: isLegacy
                            ? const Color(0xFF775500)
                            : AppColors.textOnPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _InfoCard(
                icon: PhosphorIconsRegular.user,
                label: 'Nombre',
                value: user.fullName,
              ),
              const SizedBox(height: 10),
              _InfoCard(
                icon: PhosphorIconsRegular.envelope,
                label: 'Correo',
                value: user.email,
              ),
              if (user.fieldStudy != null &&
                  user.fieldStudy!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                _InfoCard(
                  icon: PhosphorIconsRegular.graduationCap,
                  label: 'Estudio de campo',
                  value: user.fieldStudy!,
                ),
              ],
              const SizedBox(height: 10),
              _InfoCard(
                icon: PhosphorIconsRegular.shield,
                label: 'Rol',
                value: user.role.name,
                borderGradient: isUnicor
                    ? const SweepGradient(
                        colors: [
                          Color(0xFFFF4D8D),
                          Color(0xFFFFC857),
                          Color(0xFF53D6A5),
                          Color(0xFF54A8FF),
                          Color(0xFFB66DFF),
                          Color(0xFFFF4D8D),
                        ],
                      )
                    : null,
                decoration: BoxDecoration(
                  color: roleBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: isUnicor
                      ? null
                      : Border.all(color: roleColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: roleColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              if (user.createdAt != null) ...[
                const SizedBox(height: 10),
                _InfoCard(
                  icon: PhosphorIconsRegular.calendarBlank,
                  label: 'Miembro desde',
                  value: DateFormat.yMMMMd('es').format(user.createdAt!),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            icon: Icon(
              PhosphorIconsRegular.signOut,
              color: AppColors.error,
              size: 20,
            ),
            label: Text(
              'Cerrar sesión',
              style: TextStyle(color: AppColors.error),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.decoration,
    this.borderGradient,
  });

  final IconData icon;
  final String label;
  final String value;
  final BoxDecoration? decoration;
  final Gradient? borderGradient;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: decoration ?? AppStyles.card,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppStyles.caption),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (borderGradient == null) return card;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: borderGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: decoration?.boxShadow,
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(10), child: card),
    );
  }
}
