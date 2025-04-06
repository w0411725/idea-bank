import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

part 'idea_database.g.dart';

// Drift table definition
class Ideas extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get voiceInput => boolean().withDefault(const Constant(false))();
  TextColumn get tagsJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Ideas])
class IdeaDatabase extends _$IdeaDatabase {
  IdeaDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) {
      return m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 3) {
        await m.addColumn(ideas, ideas.tagsJson);
      }
    },
  );

  // Helper: Convert tags JSON -> List<String>
  List<String> getTagsFromJson(String? tagsJson) {
    if (tagsJson == null || tagsJson.isEmpty) return [];
    try {
      final List<dynamic> parsed = json.decode(tagsJson);
      return parsed.map((tag) => tag.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  // Helper: Convert List<String> -> JSON
  String? getJsonFromTags(List<String> tags) {
    if (tags.isEmpty) return null;
    return json.encode(tags);
  }

  // Get all ideas
  Future<List<Idea>> getAllIdeas() async {
    return await select(ideas).get();
  }

  // Insert/overwrite idea
  Future<void> createNewIdea({
    required String id,
    required String userId,
    required String title,
    String? description,
    required DateTime createdAt,
    required DateTime updatedAt,
    required bool voiceInput,
    List<String> tags = const [],
  }) async {
    final tagsJson = getJsonFromTags(tags);

    await into(ideas).insertOnConflictUpdate(
      IdeasCompanion(
        id: Value(id),
        userId: Value(userId),
        title: Value(title),
        description: Value(description),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
        voiceInput: Value(voiceInput),
        tagsJson: Value(tagsJson),
      ),
    );
  }

  //Update idea
  Future<void> updateIdea(Idea idea) async {
    await update(ideas).replace(idea);
  }

  //Delete idea by id
  Future<void> deleteIdeaById(String id) async {
    await (delete(ideas)..where((tbl) => tbl.id.equals(id))).go();
  }

  // clear DB (testing only)
  Future<void> deleteAllIdeas() async {
    await delete(ideas).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'idea_bank.sqlite');
    return NativeDatabase(File(dbPath));
  });
}
