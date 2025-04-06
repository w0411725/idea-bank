class Idea {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final List<String> tags;

  Idea({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.tags,
  });
}
