import 'package:field_colector/adapters/real/firebase_auth_adapter.dart';
import 'package:field_colector/adapters/real/event_registration_role_adapter.dart';
import 'package:field_colector/adapters/real/firebase_social_record_adapter.dart';
import 'package:field_colector/adapters/real/isar_bird_record_adapter.dart';
import 'package:field_colector/adapters/real/isar_outing_adapter.dart';
import 'package:field_colector/adapters/real/isar_rock_record_adapter.dart';
import 'package:field_colector/adapters/real/isar_social_record_adapter.dart';
import 'package:field_colector/adapters/real/isar_soil_record_adapter.dart';
import 'package:field_colector/adapters/real/isar_user_adapter.dart';
import 'package:field_colector/adapters/real/isar_vegetation_record_adapter.dart';
import 'package:field_colector/adapters/real/isar_water_record_adapter.dart';
import 'package:field_colector/adapters/real/photo_storage_adapter.dart';
import 'package:field_colector/core/database/offline_pin_store.dart';
import 'package:field_colector/core/services/connectivity_sync_service.dart';
import 'package:field_colector/core/services/expedition_sync_service.dart';
import 'package:field_colector/core/services/offline_expedition_service.dart';
import 'package:field_colector/core/services/record_local_persistence.dart';
import 'package:field_colector/core/services/record_sync_service.dart';
import 'package:field_colector/core/services/record_submit_service.dart';
import 'package:field_colector/core/services/sync_service.dart';
import 'package:field_colector/core/services/user_cache_service.dart';
import 'package:field_colector/domain/ports/photo_local_port.dart';
import 'package:field_colector/domain/ports/sync_port.dart';
import 'package:field_colector/domain/mappers/form_mapper_registry.dart';
import 'package:field_colector/domain/ports/bird_record_local_port.dart';
import 'package:field_colector/domain/ports/outing_local_port.dart';
import 'package:field_colector/domain/ports/rock_record_local_port.dart';
import 'package:field_colector/domain/ports/social_record_local_port.dart';
import 'package:field_colector/domain/ports/social_record_remote_port.dart';
import 'package:field_colector/domain/ports/soil_record_local_port.dart';
import 'package:field_colector/domain/ports/vegetation_record_local_port.dart';
import 'package:field_colector/domain/ports/water_record_local_port.dart';
import 'package:field_colector/core/database/app_settings_store.dart';
import 'package:field_colector/core/database/form_draft_service.dart';
import 'package:field_colector/adapters/geolocator_provider.dart';
import 'package:field_colector/domain/ports/locator_provider.dart';
import 'package:field_colector/features/settings/providers/settings_provider.dart';
import 'package:field_colector/core/database/isar_service.dart';
import 'package:field_colector/core/services/session_validation_service.dart';
import 'package:field_colector/features/auth/providers/auth_provider.dart';
import 'package:field_colector/features/profile/providers/profile_provider.dart';
import 'package:field_colector/features/expeditions/providers/field_session_provider.dart';
import 'package:field_colector/features/home/screens/home.dart';
import 'package:field_colector/features/map/map_services.dart';
import 'package:field_colector/features/map/providers/nearby_records_provider.dart';
import 'package:field_colector/features/utilities/theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:field_colector/domain/ports/bird_record_remote_port.dart';
import 'package:field_colector/domain/ports/outing_remote_port.dart';
import 'package:field_colector/domain/ports/rock_record_remote_port.dart';
import 'package:field_colector/domain/ports/soil_record_remote_port.dart';
import 'package:field_colector/domain/ports/species_remote_port.dart';
import 'package:field_colector/domain/ports/user_remote_port.dart';
import 'package:field_colector/domain/entities/role.dart';
import 'package:field_colector/domain/ports/vegetation_record_remote_port.dart';
import 'package:field_colector/domain/ports/water_record_remote_port.dart';

import 'package:field_colector/adapters/real/firebase_bird_record_adapter.dart';
import 'package:field_colector/adapters/real/firebase_outing_adapter.dart';
import 'package:field_colector/adapters/real/firebase_rock_record_adapter.dart';
import 'package:field_colector/adapters/real/firebase_soil_record_adapter.dart';
import 'package:field_colector/adapters/real/firebase_species_adapter.dart';
import 'package:field_colector/adapters/real/firebase_user_adapter.dart';
import 'package:field_colector/adapters/real/firebase_vegetation_record_adapter.dart';
import 'package:field_colector/adapters/real/firebase_water_record_adapter.dart';

import 'package:field_colector/features/export/providers/export_provider.dart';
import 'package:field_colector/features/manual/providers/manual_intro_provider.dart';
import 'package:field_colector/features/utilities/export_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  // Android puede auto-init nativo mientras Dart ve apps vacío; hot restart igual.
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
  await GoogleSignIn.instance.initialize();
  await FMTCObjectBoxBackend().initialise();
  await initializeDateFormatting('es');

  await IsarService.getInstance();
  final userLocalAdapter = IsarUserAdapter();
  final sessionValidation = SessionValidationService(userLocalAdapter);
  final authPort = FirebaseAuthAdapter(FirebaseAuth.instance, userLocalAdapter);

  final mapServices = MapServices.create();

  runApp(
    MyApp(
      mapServices: mapServices,
      authPort: authPort,
      sessionValidation: sessionValidation,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.mapServices,
    required this.authPort,
    required this.sessionValidation,
  });

  final MapServices mapServices;
  final FirebaseAuthAdapter authPort;
  final SessionValidationService sessionValidation;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<UserRemotePort>(
          create: (_) => FirebaseUserAdapter(FirebaseFirestore.instance),
        ),
        ChangeNotifierProvider(
          create: (context) => Authprovider(
            authPort: authPort,
            registrationRole: EventRegistrationRoleAdapter(
              role: Role.legacy,
              endsAt: DateTime.utc(2026, 10, 11, 5),
            ),
            userRemote: context.read<UserRemotePort>(),
            sessionValidation: sessionValidation,
          ),
        ),
        ChangeNotifierProvider(create: (_) => ManualIntroProvider()),
        ChangeNotifierProvider(create: (_) => FormDraftService()),
        Provider<MapServices>.value(value: mapServices),
        ChangeNotifierProvider(
          create: (context) => SettingsProvider(
            store: AppSettingsStore(),
            mapServices: context.read<MapServices>(),
            formDrafts: context.read<FormDraftService>(),
          ),
        ),
        Provider<LocatorProvider>(
          create: (context) =>
              GeolocatorProvider(context.read<SettingsProvider>()),
        ),

        Provider<BirdRecordRemotePort>(
          create: (_) => FirebaseBirdRecordAdapter(FirebaseFirestore.instance),
        ),
        Provider<BirdRecordLocalPort>(create: (_) => IsarBirdRecordAdapter()),
        Provider<RockRecordRemotePort>(
          create: (_) => FirebaseRockRecordAdapter(FirebaseFirestore.instance),
        ),
        Provider<RockRecordLocalPort>(create: (_) => IsarRockRecordAdapter()),
        Provider<SoilRecordRemotePort>(
          create: (_) => FirebaseSoilRecordAdapter(FirebaseFirestore.instance),
        ),
        Provider<SoilRecordLocalPort>(create: (_) => IsarSoilRecordAdapter()),
        Provider<VegetationRecordRemotePort>(
          create: (_) =>
              FirebaseVegetationRecordAdapter(FirebaseFirestore.instance),
        ),
        Provider<VegetationRecordLocalPort>(
          create: (_) => IsarVegetationRecordAdapter(),
        ),
        Provider<WaterRecordRemotePort>(
          create: (_) => FirebaseWaterRecordAdapter(FirebaseFirestore.instance),
        ),
        Provider<WaterRecordLocalPort>(create: (_) => IsarWaterRecordAdapter()),
        Provider<SocialRecordRemotePort>(
          create: (_) =>
              FirebaseSocialRecordAdapter(FirebaseFirestore.instance),
        ),
        Provider<SocialRecordLocalPort>(
          create: (_) => IsarSocialRecordAdapter(),
        ),
        Provider<OutingRemotePort>(
          create: (_) => FirebaseOutingAdapter(FirebaseFirestore.instance),
        ),
        Provider<OutingLocalPort>(create: (_) => IsarOutingAdapter()),
        Provider<SpeciesRemotePort>(
          create: (_) => FirebaseSpeciesAdapter(FirebaseFirestore.instance),
        ),
        Provider<PhotoLocalPort>(create: (_) => PhotoStorageAdapter()),
        Provider<FormMapperRegistry>(create: (_) => FormMapperRegistry()),
        Provider<ExpeditionSyncService>(
          create: (context) => ExpeditionSyncService(
            outingLocal: context.read<OutingLocalPort>(),
            outingRemote: context.read<OutingRemotePort>(),
            reachability: context.read<MapServices>().reachability,
          ),
        ),
        Provider<RecordLocalPersistence>(
          create: (context) => RecordLocalPersistence(
            birdLocal: context.read<BirdRecordLocalPort>(),
            rockLocal: context.read<RockRecordLocalPort>(),
            soilLocal: context.read<SoilRecordLocalPort>(),
            vegetationLocal: context.read<VegetationRecordLocalPort>(),
            waterLocal: context.read<WaterRecordLocalPort>(),
            socialLocal: context.read<SocialRecordLocalPort>(),
          ),
        ),
        Provider<RecordSyncService>(
          create: (context) => RecordSyncService(
            birdRemote: context.read<BirdRecordRemotePort>(),
            rockRemote: context.read<RockRecordRemotePort>(),
            soilRemote: context.read<SoilRecordRemotePort>(),
            vegetationRemote: context.read<VegetationRecordRemotePort>(),
            waterRemote: context.read<WaterRecordRemotePort>(),
            socialRemote: context.read<SocialRecordRemotePort>(),
            recordPersistence: context.read<RecordLocalPersistence>(),
            reachability: context.read<MapServices>().reachability,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => FieldSessionProvider(
            outingLocal: context.read<OutingLocalPort>(),
          ),
        ),
        Provider<OfflinePinStore>(create: (_) => OfflinePinStore()),
        Provider<OfflineExpeditionService>(
          create: (context) => OfflineExpeditionService(
            pinStore: context.read<OfflinePinStore>(),
            expeditionSync: context.read<ExpeditionSyncService>(),
            recordSync: context.read<RecordSyncService>(),
            recordPersistence: context.read<RecordLocalPersistence>(),
            reachability: context.read<MapServices>().reachability,
          )..init(),
        ),
        Provider<UserCacheService>(
          create: (context) =>
              UserCacheService(userRemote: context.read<UserRemotePort>()),
        ),
        Provider<RecordSubmitService>(
          create: (context) => RecordSubmitService(
            registry: context.read<FormMapperRegistry>(),
            outingLocal: context.read<OutingLocalPort>(),
            photoLocal: context.read<PhotoLocalPort>(),
            birdLocal: context.read<BirdRecordLocalPort>(),
            rockLocal: context.read<RockRecordLocalPort>(),
            soilLocal: context.read<SoilRecordLocalPort>(),
            vegetationLocal: context.read<VegetationRecordLocalPort>(),
            waterLocal: context.read<WaterRecordLocalPort>(),
            socialLocal: context.read<SocialRecordLocalPort>(),
          ),
        ),
        ChangeNotifierProvider<ProfileProvider>(
          create: (context) =>
              ProfileProvider(auth: context.read<Authprovider>()),
        ),
        ChangeNotifierProvider(
          create: (context) => NearbyRecordsProvider(
            birdLocal: context.read<BirdRecordLocalPort>(),
            rockLocal: context.read<RockRecordLocalPort>(),
            soilLocal: context.read<SoilRecordLocalPort>(),
            vegetationLocal: context.read<VegetationRecordLocalPort>(),
            waterLocal: context.read<WaterRecordLocalPort>(),
            socialLocal: context.read<SocialRecordLocalPort>(),
            birdRemote: context.read<BirdRecordRemotePort>(),
            rockRemote: context.read<RockRecordRemotePort>(),
            soilRemote: context.read<SoilRecordRemotePort>(),
            vegetationRemote: context.read<VegetationRecordRemotePort>(),
            waterRemote: context.read<WaterRecordRemotePort>(),
            socialRemote: context.read<SocialRecordRemotePort>(),
            reachability: context.read<MapServices>().reachability,
            fieldSession: context.read<FieldSessionProvider>(),
            auth: context.read<Authprovider>(),
            recordPersistence: context.read<RecordLocalPersistence>(),
          )..start(),
        ),
        Provider<SyncPort>(
          create: (context) => SyncService(
            outingLocalPort: context.read<OutingLocalPort>(),
            outingRemotePort: context.read<OutingRemotePort>(),
            birdLocalPort: context.read<BirdRecordLocalPort>(),
            birdRemotePort: context.read<BirdRecordRemotePort>(),
            rockLocalPort: context.read<RockRecordLocalPort>(),
            rockRemotePort: context.read<RockRecordRemotePort>(),
            soilLocalPort: context.read<SoilRecordLocalPort>(),
            soilRemotePort: context.read<SoilRecordRemotePort>(),
            vegLocalPort: context.read<VegetationRecordLocalPort>(),
            vegRemotePort: context.read<VegetationRecordRemotePort>(),
            waterLocalPort: context.read<WaterRecordLocalPort>(),
            waterRemotePort: context.read<WaterRecordRemotePort>(),
            socialLocalPort: context.read<SocialRecordLocalPort>(),
            socialRemotePort: context.read<SocialRecordRemotePort>(),
            photoLocalPort: context.read<PhotoLocalPort>(),
          ),
        ),
        Provider<ConnectivitySyncService>(
          create: (context) => ConnectivitySyncService(
            context.read<SyncPort>(),
            offlineExpeditionService: context.read<OfflineExpeditionService>(),
          )..startListening(),
        ),
        Provider<ExportService>(
          create: (context) => ExportService(
            birdPort: context.read<BirdRecordRemotePort>(),
            rockPort: context.read<RockRecordRemotePort>(),
            soilPort: context.read<SoilRecordRemotePort>(),
            vegetationPort: context.read<VegetationRecordRemotePort>(),
            waterPort: context.read<WaterRecordRemotePort>(),
            socialPort: context.read<SocialRecordRemotePort>(),
          ),
        ),
        ChangeNotifierProvider<ExportProvider>(
          create: (context) =>
              ExportProvider(exportService: context.read<ExportService>()),
        ),
      ],
      child: MaterialApp(
        title: 'Citesa Field Colector',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es'), Locale('en')],
        home: const HomeScreen(),
      ),
    );
  }
}
