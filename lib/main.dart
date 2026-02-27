import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'data/local/local_store.dart';
import 'design_system/app_theme.dart';
import 'presentation/app_router.dart';

void main() async {
  print('🚀 [MAIN] Starting app initialization...');
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  print('🚀 [MAIN] Initializing Supabase...');
  print('🚀 [MAIN] Supabase URL: ${SupabaseConfig.supabaseUrl}');
  print('🚀 [MAIN] Redirect URL: ${SupabaseConfig.authRedirectUrl}');

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
      autoRefreshToken: true,
      detectSessionInUri: true,
    ),
  );

  print('🚀 [MAIN] Supabase initialized successfully');
  print('🚀 [MAIN] Current session: ${Supabase.instance.client.auth.currentSession != null ? "EXISTS" : "NULL"}');

  print('🚀 [MAIN] Initializing LocalStore...');
  await LocalStore.init();
  print('🚀 [MAIN] LocalStore initialized');

  print('🚀 [MAIN] Starting app...');
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
