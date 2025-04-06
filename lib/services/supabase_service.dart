import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/idea_database.dart'; // Drift-generated model

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  /// Fetch all ideas for the current user
  Future<List<Idea>> fetchUserIdeas() async {
    final response = await client
        .from('ideas')
        .select()
        .order('created_at', ascending: false);

    final data = response as List<dynamic>;

    return data.map((item) {
      return Idea(
        id: item['id'],
        userId: item['user_id'],
        title: item['title'],
        description: item['description'],
        createdAt: DateTime.parse(item['created_at']),
        updatedAt: DateTime.parse(item['updated_at']),
        voiceInput: item['voice_input'] ?? false,
        tagsJson: null, // Drift only, handled separately
      );
    }).toList();
  }

  /// Insert an idea and sync normalized tags
  Future<void> insertIdea(Idea idea, List<String> tags) async {
    // 1. Insert the idea into `ideas`
    await client.from('ideas').insert({
      'id': idea.id,
      'user_id': idea.userId,
      'title': idea.title,
      'description': idea.description,
      'created_at': idea.createdAt.toIso8601String(),
      'updated_at': idea.updatedAt.toIso8601String(),
      'voice_input': idea.voiceInput,
    });

    // 2. Insert tags into `tags` (if not already created), collect tag IDs
    final List<String> tagIds = [];

    for (final tag in tags) {
      final existing = await client
          .from('tags')
          .select('id')
          .eq('name', tag)
          .eq('user_id', idea.userId)
          .maybeSingle();

      String tagId;

      if (existing != null) {
        tagId = existing['id'];
      } else {
        final response = await client
            .from('tags')
            .insert({
              'user_id': idea.userId,
              'name': tag,
            })
            .select('id')
            .single();

        tagId = response['id'];
      }

      tagIds.add(tagId);
    }

    // 3. Link tags to the idea in `idea_tags`
    for (final tagId in tagIds) {
      await client.from('idea_tags').insert({
        'idea_id': idea.id,
        'tag_id': tagId,
      });
    }
  }

  /// Delete an idea by ID
  Future<void> deleteIdea(String id) async {
    await client.from('ideas').delete().eq('id', id);
  }
}
