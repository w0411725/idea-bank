import 'package:flutter/material.dart';
import '../db/idea_database.dart';
import '../state/theme_notifier.dart';
import 'edit_screen.dart';

class HomeScreen extends StatefulWidget {
  final IdeaDatabase db;

  const HomeScreen({super.key, required this.db});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Idea>> _ideasFuture;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadIdeas('');
  }

  void _loadIdeas(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _ideasFuture = widget.db.getAllIdeas();
      } else {
        _ideasFuture = widget.db.searchIdeas(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💡 Idea Bank'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'toggle_theme') {
                print('🌓 Theme toggle triggered');
                await themeNotifier.toggleTheme();
                print('✅ New theme: ${themeNotifier.value}');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem<String>(
                value: 'toggle_theme',
                child: Text('Toggle Theme'),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search ideas...',
                filled: true,
                fillColor: Colors.white10,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadIdeas('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _loadIdeas,
            ),
          ),
        ),
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

              return Dismissible(
                key: ValueKey(idea.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  await widget.db.deleteIdeaById(idea.id);
                  _loadIdeas(_searchController.text);
                },
                child: ListTile(
                  title: Text(idea.title),
                  subtitle: Text(
                    idea.description ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditScreen(
                          db: widget.db,
                          existingIdea: idea,
                        ),
                      ),
                    );
                    _loadIdeas(_searchController.text);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditScreen(db: widget.db),
            ),
          );
          _loadIdeas(_searchController.text);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
