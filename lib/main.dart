import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'data/local/local_store.dart';
import 'design_system/app_theme.dart';
import 'presentation/app_router.dart';

void main() async {
  if (kDebugMode) debugPrint('[MAIN] Starting app initialization...');
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  if (kDebugMode) debugPrint('[MAIN] Initializing Supabase...');

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
      autoRefreshToken: true,
      detectSessionInUri: true,
    ),
  );

  if (kDebugMode) debugPrint('[MAIN] Supabase initialized successfully');

  if (kDebugMode) debugPrint('[MAIN] Initializing LocalStore...');
  await LocalStore.init();
  if (kDebugMode) debugPrint('[MAIN] LocalStore initialized');

  if (kDebugMode) debugPrint('[MAIN] Starting app...');
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final router = ref.watch(appRouterProvider);
        return MaterialApp.router(
          title: 'Journal App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: router,
        );
      },
    );
  }
}
