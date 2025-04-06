import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme/app_theme.dart';
import 'db/idea_database.dart';
import 'services/auth_service.dart';
import 'state/idea_provider.dart';
import 'state/theme_notifier.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Starting app initialization...');

  await Hive.initFlutter();
  await themeNotifier.loadTheme();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://goyrpuevsmetvfaqcejd.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdveXJwdWV2c21ldHZmYXFjZWpkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM3NjU1MDMsImV4cCI6MjA1OTM0MTUwM30._5rvv7Hwl54xJXjH-jWjPJKBWaYLI_GqBqBr55YfaAo',
  );
  print('✅ Supabase initialized');

  final db = IdeaDatabase();
  print('Local Drift DB initialized');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => IdeaProvider(db: db)),
      ],
      child: MyApp(db: db),
    ),
  );
}

class MyApp extends StatelessWidget {
  final IdeaDatabase db;

  const MyApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'Idea Bank',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          initialRoute: AppRoutes.login,
          onGenerateRoute: RouteGenerator.generateRoute,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

