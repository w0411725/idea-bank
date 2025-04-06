import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../db/idea_database.dart';

class EditScreen extends StatefulWidget {
  final IdeaDatabase db;
  final Idea? existingIdea;

  const EditScreen({
    super.key,
    required this.db,
    this.existingIdea,
  });

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _newTagController = TextEditingController();

  bool _voiceInput = false;
  List<String> _availableTags = [];
  List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();

    if (widget.existingIdea != null) {
      _titleController.text = widget.existingIdea!.title;
      _descController.text = widget.existingIdea!.description ?? '';
      _voiceInput = widget.existingIdea!.voiceInput;
      _selectedTags = widget.db.getTagsFromJson(widget.existingIdea!.tagsJson);
    }

    _loadTags();
  }

  Future<void> _loadTags() async {
    final tags = await widget.db.getAllTags(userId: 'offline-user');
    setState(() {
      _availableTags = tags.map((t) => t.name).toList();
    });
  }

  Future<void> _addNewTag() async {
    final name = _newTagController.text.trim();
    if (name.isEmpty || _availableTags.contains(name)) return;

    await widget.db.insertTag(
      id: const Uuid().v4(),
      userId: 'offline-user',
      name: name,
    );

    _newTagController.clear();
    await _loadTags();
    setState(() => _selectedTags.add(name));
  }

  Future<void> _saveIdea() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final id = widget.existingIdea?.id ?? const Uuid().v4();
    final userId = widget.existingIdea?.userId ?? 'offline-user';

    final newIdea = Idea(
      id: id,
      userId: userId,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      createdAt: widget.existingIdea?.createdAt ?? now,
      updatedAt: now,
      voiceInput: _voiceInput,
      tagsJson: widget.db.getJsonFromTags(_selectedTags),
    );

    await widget.db.createNewIdea(
      id: newIdea.id,
      userId: newIdea.userId,
      title: newIdea.title,
      description: newIdea.description,
      createdAt: newIdea.createdAt,
      updatedAt: newIdea.updatedAt,
      voiceInput: newIdea.voiceInput,
      tags: _selectedTags,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingIdea != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Idea' : 'New Idea'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveIdea,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Voice Input?'),
                value: _voiceInput,
                onChanged: (val) => setState(() => _voiceInput = val),
              ),
              const SizedBox(height: 16),
              Text('Tags', style: Theme.of(context).textTheme.titleMedium),
              Wrap(
                spacing: 8,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                    checkmarkColor: Colors.white,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newTagController,
                      decoration: const InputDecoration(labelText: 'New tag'),
                      onSubmitted: (_) => _addNewTag(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addNewTag,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
