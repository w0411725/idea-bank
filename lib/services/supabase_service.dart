import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/idea_database.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  // Fetch all ideas for the current user
  Future<List<Idea>> fetchUserIdeas() async {
    // Get current user ID
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Fetch ideas with their associated tags
    final response = await client
        .from('ideas')
        .select('''
          *,
          idea_tags:idea_tags(
            tag_id,
            tags:tags(id, name)
          )
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final List<dynamic> data = response;
    
    // Convert the response to Idea objects
    return data.map((item) {
      // Extract tags from the nested join data
      List<String> tags = [];
      if (item['idea_tags'] != null) {
        for (var tagJoin in item['idea_tags']) {
          if (tagJoin['tags'] != null) {
            tags.add(tagJoin['tags']['name']);
          }
        }
      }
      
      // Create the Idea object
      return Idea(
        id: item['id'],
        userId: item['user_id'],
        title: item['title'],
        description: item['description'],
        createdAt: DateTime.parse(item['created_at']),
        updatedAt: DateTime.parse(item['updated_at']),
        voiceInput: item['voice_input'] ?? false,
        tagsJson: tags.isEmpty ? null : jsonEncode(tags),
      );
    }).toList();
  }

  // Insert an idea with its tags
  Future<void> insertIdea(Idea idea, List<String> tags) async {
    // Get current user ID
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Start a transaction using Supabase Edge Functions (or manual transaction)
    // 1. Insert/update the idea
    await client.from('ideas').upsert({
      'id': idea.id,
      'user_id': userId,
      'title': idea.title,
      'description': idea.description,
      'created_at': idea.createdAt.toIso8601String(),
      'updated_at': idea.updatedAt.toIso8601String(),
      'voice_input': idea.voiceInput,
    });

    // 2. For each tag, insert if not exists
    final List<String> tagIds = [];
    for (final tag in tags) {
      // Check if tag exists
      final existingTag = await client
          .from('tags')
          .select('id')
          .eq('name', tag)
          .eq('user_id', userId)
          .maybeSingle();

      String tagId;
      if (existingTag != null) {
        // Use existing tag
        tagId = existingTag['id'];
      } else {
        // Create new tag
        final newTag = await client
            .from('tags')
            .insert({
              'name': tag,
              'user_id': userId,
            })
            .select('id')
            .single();
        tagId = newTag['id'];
      }
      tagIds.add(tagId);
    }

    // 3. Delete existing idea_tags
    await client
        .from('idea_tags')
        .delete()
        .eq('idea_id', idea.id);

    // 4. Insert new idea_tags
    for (final tagId in tagIds) {
      await client.from('idea_tags').insert({
        'idea_id': idea.id,
        'tag_id': tagId,
      });
    }
  }

  // Delete an idea
  Future<void> deleteIdea(String id) async {
    // Junction table entries will be deleted by cascade constraints
    await client.from('ideas').delete().eq('id', id);
  }

  // Get all tags for current user
  Future<List<Map<String, dynamic>>> fetchUserTags() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await client
        .from('tags')
        .select('id, name')
        .eq('user_id', userId)
        .order('name');

    return List<Map<String, dynamic>>.from(response);
  }
}