import 'package:flutter/material.dart';
import '../db/idea_database.dart';
import '../services/supabase_service.dart';

class SyncService {
  final IdeaDatabase _db;
  final SupabaseService _supabaseService;
  
  SyncService({
    required IdeaDatabase db,
    SupabaseService? supabaseService,
  }) : _db = db,
       _supabaseService = supabaseService ?? SupabaseService();
  
  // Sync remote ideas to local database
  Future<int> pullFromRemote() async {
    try {
      // Fetch all remote ideas
      final remoteIdeas = await _supabaseService.fetchUserIdeas();
      int counter = 0;
      
      // Save each remote idea to local database
      for (final idea in remoteIdeas) {
        await _db.createNewIdea(
          id: idea.id,
          userId: idea.userId,
          title: idea.title,
          description: idea.description,
          createdAt: idea.createdAt,
          updatedAt: idea.updatedAt,
          voiceInput: idea.voiceInput,
          tags: _db.getTagsFromJson(idea.tagsJson),
        );
        counter++;
      }
      
      // Also fetch and sync tags
      final remoteTags = await _supabaseService.fetchUserTags();
      for (final tag in remoteTags) {
        await _db.insertTag(
          id: tag['id'],
          userId: _supabaseService.client.auth.currentUser!.id,
          name: tag['name'],
        );
      }
      
      return counter;
    } catch (e) {
      debugPrint('Error pulling from remote: $e');
      rethrow;
    }
  }
  
  // Push local ideas to remote
  Future<int> pushToRemote() async {
    try {
      // Get all local ideas
      final localIdeas = await _db.getAllIdeas();
      int counter = 0;
      
      // Push each local idea to remote
      for (final idea in localIdeas) {
        try {
          final tags = _db.getTagsFromJson(idea.tagsJson);
          await _supabaseService.insertIdea(idea, tags);
          counter++;
        } catch (e) {
          debugPrint('Error pushing idea ${idea.id}: $e');
          // Continue with other ideas
          continue;
        }
      }
      
      return counter;
    } catch (e) {
      debugPrint('Error pushing to remote: $e');
      rethrow;
    }
  }
  
  // Simple conflict resolution: Last write wins based on updated_at
  Future<Map<String, int>> performFullSync() async {
    int pushed = 0;
    int pulled = 0;
    
    try {
      // First pull remote changes
      pulled = await pullFromRemote();
      
      // Then push local changes
      pushed = await pushToRemote();
      
      // Finally pull again to ensure consistency
      await pullFromRemote();
      
      return {
        'pushed': pushed,
        'pulled': pulled,
      };
    } catch (e) {
      debugPrint('Error during full sync: $e');
      return {
        'pushed': pushed,
        'pulled': pulled,
        'error': 1,
      };
    }
  }
}