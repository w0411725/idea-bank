import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../db/idea_database.dart';
import '../state/theme_notifier.dart';
import '../state/idea_provider.dart';
import '../services/auth_service.dart';
import '../routes.dart';
import 'edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final IdeaDatabase db;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is IdeaDatabase) {
        db = args;
        Provider.of<IdeaProvider>(context, listen: false).loadIdeas();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❗ Missing database for HomeScreen')),
        );
      }
    });
  }

  Future<bool> _handleBackPressed() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();

    if (!mounted) return false;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
    return false; // Prevent default pop behavior
  }

  @override
  Widget build(BuildContext context) {
    final ideaProvider = Provider.of<IdeaProvider>(context);

    return WillPopScope(
      onWillPop: _handleBackPressed,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('💡 Idea Bank'),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'toggle_theme') {
                  await themeNotifier.toggleTheme();
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
                            ideaProvider.loadIdeas(query: '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) =>
                    ideaProvider.loadIdeas(query: value),
              ),
            ),
          ),
        ),
        body: Consumer<IdeaProvider>(
          builder: (context, provider, child) {
            if (provider.ideas.isEmpty) {
              return const Center(child: Text('No ideas found.'));
            }

            return ListView.builder(
              itemCount: provider.ideas.length,
              itemBuilder: (context, index) {
                final idea = provider.ideas[index];

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
                    await provider.deleteIdea(idea.id);
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
                          builder: (_) =>
                              EditScreen(db: db, existingIdea: idea),
                        ),
                      );
                      provider.refresh();
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
              MaterialPageRoute(builder: (_) => EditScreen(db: db)),
            );
            ideaProvider.refresh();
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
