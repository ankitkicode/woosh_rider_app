import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'data/services/location_foreground_service.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  LocationForegroundService.init();
  runApp(
    const ProviderScope(
      child: WooshDriverApp(),
    ),
  );
}

class WooshDriverApp extends ConsumerWidget {
  const WooshDriverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Woosh Queens',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRoutes.router,
    );
  }
}
