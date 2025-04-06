import 'package:flutter/material.dart';
import '../db/idea_database.dart';

class HomeScreen extends StatefulWidget {
  final IdeaDatabase db;

  const HomeScreen({super.key, required this.db});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Idea>> _ideasFuture;

  @override
  void initState() {
    super.initState();
    _ideasFuture = widget.db.getAllIdeas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💡 Idea Bank'),
      ),
      body: FutureBuilder<List<Idea>>(
        future: _ideasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No ideas found.'));
          }

          final ideas = snapshot.data!;

          return ListView.builder(
            itemCount: ideas.length,
            itemBuilder: (context, index) {
              final idea = ideas[index];

              return ListTile(
                title: Text(idea.title),
                subtitle: Text(
                  idea.description ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
