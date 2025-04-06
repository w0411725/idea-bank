import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme/app_theme.dart';
import 'db/idea_database.dart';
import 'services/supabase_service.dart';
import 'screens/home_screen.dart';
import 'state/theme_notifier.dart';

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

  // Sign in test user
  final authResponse = await Supabase.instance.client.auth.signInWithPassword(
    email: 'test@testmail.com',
    password: 'testpassword',
  );

  if (authResponse.user == null) {
    print('Login failed: ${authResponse.session?.accessToken}');
    return;
  } else {
    print('Logged in as ${authResponse.user!.email}');
  }

  final db = IdeaDatabase();
  print('Local Drift DB initialized');

  final supabaseService = SupabaseService();
  final remoteIdeas = await supabaseService.fetchUserIdeas();
  print('Fetched ${remoteIdeas.length} ideas from Supabase');

  for (final idea in remoteIdeas) {
    print('Saving idea: ${idea.title}');
    await db.createNewIdea(
      id: idea.id,
      userId: idea.userId,
      title: idea.title,
      description: idea.description,
      createdAt: idea.createdAt,
      updatedAt: idea.updatedAt,
      voiceInput: idea.voiceInput,
      tags: db.getTagsFromJson(idea.tagsJson),
    );
  }

  print('All ideas synced to local DB');

  runApp(MyApp(db: db));
}

class MyApp extends StatelessWidget {
  final IdeaDatabase db;

  const MyApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) => MaterialApp(
        title: 'Idea Bank',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: HomeScreen(db: db),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
