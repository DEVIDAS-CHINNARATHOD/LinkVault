// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'features/groups/domain/entities/group_entity.dart';
import 'features/links/domain/entities/link_entity.dart';
import 'features/vault/domain/entities/vault_entry_entity.dart';
import 'main_scaffold.dart';
import 'services/encryption_service.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── System UI ───────────────────────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // ── Environment ─────────────────────────────────────────────────────────
  await dotenv.load(fileName: '.env');

  // ── Hive local database ─────────────────────────────────────────────────
  await Hive.initFlutter();
  Hive.registerAdapter(LinkEntityAdapter());
  Hive.registerAdapter(GroupEntityAdapter());
  Hive.registerAdapter(VaultEntryEntityAdapter());

  await Future.wait([
    Hive.openBox<LinkEntity>(AppConstants.linksBox),
    Hive.openBox<GroupEntity>(AppConstants.groupsBox),
    Hive.openBox<VaultEntryEntity>(AppConstants.vaultBox),
    Hive.openBox(AppConstants.settingsBox),
  ]);

  // ── Encryption engine ────────────────────────────────────────────────────
  await EncryptionService.initialize();

  // ── Supabase (cloud sync) ────────────────────────────────────────────────
  await SupabaseService.initialize();
  if (!SupabaseService.isAuthenticated) {
    try {
      // Anonymous auth — no account required, data still synced per device
      await SupabaseService.signInAnonymously();
    } catch (_) {
      // Offline graceful degradation — local-only mode
    }
  }

  runApp(const ProviderScope(child: LinkVaultApp()));
}

class LinkVaultApp extends StatelessWidget {
  const LinkVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      onGenerateRoute: AppRouter.generateRoute,
      home: const MainScaffold(),
      builder: (context, child) {
        // Enforce consistent text scale across all device accessibility settings
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
    );
  }
}
