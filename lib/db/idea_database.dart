import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

part 'idea_database.g.dart';

/// 🧠 Ideas table (aligned with Supabase)
class Ideas extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get userId => text()(); // Supabase auth.users FK
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get voiceInput => boolean().withDefault(const Constant(false))();

  // Local-only cached tags (from many-to-many join)
  TextColumn get tagsJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 🏷 Tags table (aligned with Supabase)
class Tags extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get userId => text()(); // Supabase FK
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE(user_id, name)'];
}

@DriftDatabase(tables: [Ideas, Tags])
class IdeaDatabase extends _$IdeaDatabase {
  IdeaDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) {
      return m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 3) {
        await m.addColumn(ideas, ideas.tagsJson);
      }
      if (from < 4) {
        await m.createTable(tags);
      }
    },
  );

  /// 🔁 Tag <-> JSON Helpers
  List<String> getTagsFromJson(String? tagsJson) {
    if (tagsJson == null || tagsJson.isEmpty) return [];
    try {
      final List<dynamic> parsed = json.decode(tagsJson);
      return parsed.map((tag) => tag.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  String? getJsonFromTags(List<String> tags) {
    if (tags.isEmpty) return null;
    return json.encode(tags);
  }

  /// 📥 Idea CRUD
  Future<List<Idea>> getAllIdeas() => select(ideas).get();

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

  Future<void> updateIdea(Idea idea) async {
    await update(ideas).replace(idea);
  }

  Future<void> deleteIdeaById(String id) async {
    await (delete(ideas)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> deleteAllIdeas() async => await delete(ideas).go();

  Future<List<Idea>> searchIdeas(String query) async {
    return (select(ideas)
          ..where((tbl) =>
              tbl.title.contains(query) |
              tbl.description.contains(query)))
        .get();
  }

  /// 🏷 Tag CRUD
  Future<void> insertTag({
    required String id,
    required String userId,
    required String name,
  }) async {
    await into(tags).insert(
      TagsCompanion(
        id: Value(id),
        userId: Value(userId),
        name: Value(name),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<List<Tag>> getAllTags({String? userId}) {
    final query = select(tags);
    if (userId != null) {
      query.where((t) => t.userId.equals(userId));
    }
    return query.get();
  }

  Future<void> deleteTagById(String tagId) async {
    await (delete(tags)..where((t) => t.id.equals(tagId))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'idea_bank.sqlite');
    return NativeDatabase(File(dbPath));
  });
}
