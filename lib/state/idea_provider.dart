import 'package:flutter/material.dart';
import '../db/idea_database.dart';
import '../services/supabase_service.dart';

class IdeaProvider extends ChangeNotifier {
  final IdeaDatabase db;
  late final SupabaseService _supabaseService;
  
  List<Idea> _ideas = [];
  List<Idea> get ideas => _ideas;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String _lastQuery = '';
  
  IdeaProvider({required this.db}) {
    _supabaseService = SupabaseService();
  }

  Future<void> loadIdeas({String query = ''}) async {
    _isLoading = true;
    _lastQuery = query;
    notifyListeners();
    
    try {
      if (query.trim().isEmpty) {
        _ideas = await db.getAllIdeas();
      } else {
        _ideas = await db.searchIdeas(query);
      }
    } catch (e) {
      debugPrint('Error loading ideas: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteIdea(String id) async {
    try {
      // Delete locally
      await db.deleteIdeaById(id);
      
      // Delete from Supabase (if online)
      try {
        await _supabaseService.deleteIdea(id);
      } catch (e) {
        debugPrint('Error deleting from Supabase: $e');
        // Continue anyway - offline first approach
      }
      
      // Refresh list
      await loadIdeas(query: _lastQuery);
    } catch (e) {
      debugPrint('Error deleting idea: $e');
    }
  }

  Future<void> createOrUpdateIdea({
    required String id,
    required String userId,
    required String title,
    String? description,
    required DateTime createdAt,
    required DateTime updatedAt,
    required bool voiceInput,
    List<String> tags = const [],
  }) async {
    try {
      // Save locally first
      await db.createNewIdea(
        id: id,
        userId: userId,
        title: title,
        description: description,
        createdAt: createdAt,
        updatedAt: updatedAt,
        voiceInput: voiceInput,
        tags: tags,
      );
      
      // Create in Supabase if online
      try {
        final idea = Idea(
          id: id,
          userId: userId,
          title: title,
          description: description,
          createdAt: createdAt,
          updatedAt: updatedAt,
          voiceInput: voiceInput,
          tagsJson: db.getJsonFromTags(tags),
        );
        
        await _supabaseService.insertIdea(idea, tags);
      } catch (e) {
        debugPrint('Error saving to Supabase: $e');
        // Continue anyway - offline first approach
      }
      
      // Refresh the list
      await loadIdeas(query: _lastQuery);
    } catch (e) {
      debugPrint('Error creating/updating idea: $e');
    }
  }

  Future<void> syncWithRemote() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Fetch from Supabase
      final remoteIdeas = await _supabaseService.fetchUserIdeas();
      
      // Save to local DB
      for (final idea in remoteIdeas) {
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
      
      // Refresh the list
      await loadIdeas(query: _lastQuery);
    } catch (e) {
      debugPrint('Error syncing with remote: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadIdeas(query: _lastQuery);
  }
}