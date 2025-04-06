import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Idea Bank',
      theme: AppTheme.dark,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Idea Bank'),
      ),
      body: const Center(
        child: Text('Let\'s build something cool. 🚀'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // We'll wire this up to "new idea" later
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
