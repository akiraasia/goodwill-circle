import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goodwill_circle/core/config/supabase_config.dart';
import 'package:goodwill_circle/core/routing/router.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:goodwill_circle/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Initialize Firebase for AI Logic (Gemini Developer API via firebase_ai).
  // Requires google-services.json (Android) / GoogleService-Info.plist (iOS).
  // Run `npx firebase-tools init ailogic` once to provision the Gemini service.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print("Firebase initialized");

    await FirebaseAuth.instance.signInAnonymously();

    print("Anonymous sign-in successful");
  } catch (e, st) {
    print("Firebase startup failed:");
    print(e);
    print(st);
    rethrow;
  }

  runApp(const ProviderScope(child: GoodwillCircleApp()));
}

class GoodwillCircleApp extends ConsumerWidget {
  const GoodwillCircleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Goodwill Circle',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
