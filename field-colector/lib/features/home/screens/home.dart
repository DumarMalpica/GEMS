import 'dart:async';

import 'package:field_colector/core/services/expedition_sync_service.dart';
import 'package:field_colector/domain/ports/locator_provider.dart';
import 'package:field_colector/features/auth/providers/auth_provider.dart';
import 'package:field_colector/features/auth/screens/login.dart';
import 'package:field_colector/features/dashboard/screens/dashboard.dart';
import 'package:field_colector/features/home/screens/loading.dart';
import 'package:field_colector/features/manual/widgets/manual_intro_host.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _lastSyncedUserId;

  @override
  void initState() {
    super.initState();
    final auth = context.read<Authprovider>();
    auth.restoreSession();
  }

  void _scheduleExpeditionSync(Authprovider auth) {
    if (auth.isLoading || !auth.isAuthenticated) {
      if (!auth.isAuthenticated) _lastSyncedUserId = null;
      return;
    }

    final userId = auth.user?.id;
    if (userId == null || userId.isEmpty) return;
    if (_lastSyncedUserId == userId) return;

    _lastSyncedUserId = userId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        context.read<ExpeditionSyncService>().syncExpeditionsForUser(userId),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Authprovider>(
      builder: (context, auth, _) {
        _scheduleExpeditionSync(auth);

        if (auth.isLoading) {
          return LoadingScreen();
        }

        if (!auth.isAuthenticated) {
          return LoginScreen();
        }

        if (!(auth.user?.profileComplete ?? false)) {
          return LoginScreen(
            key: const ValueKey('profile-completion'),
            initialZone: LoginZone.register,
            isProfileCompletion: true,
          );
        }

        return ManualIntroHost(
          child: DashboardScreen(locator: context.read<LocatorProvider>()),
        );
      },
    );
  }
}
