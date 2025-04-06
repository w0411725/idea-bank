import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';
import '../db/idea_database.dart';
import '../state/idea_provider.dart';
import 'dart:io' show Platform;

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

  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;

  bool _voiceInput = false;
  List<String> _availableTags = [];
  List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _initSpeech();

    if (widget.existingIdea != null) {
      _titleController.text = widget.existingIdea!.title;
      _descController.text = widget.existingIdea!.description ?? '';
      _voiceInput = widget.existingIdea!.voiceInput;
      _selectedTags = widget.db.getTagsFromJson(widget.existingIdea!.tagsJson);
    }

    _loadTags();
  }

  Future<void> _initSpeech() async {
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) {
      debugPrint('🛑 Speech not supported on this platform.');
      return;
    }

    try {
      await _speech.initialize();
    } catch (e) {
      debugPrint('⚠ Failed to initialize speech: $e');
    }
  }

  Future<void> _startVoiceInput() async {
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech input not supported on this platform.')),
      );
      return;
    }

    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _voiceInput = true;
        });

        _speech.listen(
          onResult: (result) {
            setState(() {
              if (_descController.text.isEmpty) {
                _descController.text = result.recognizedWords;
              } else {
                _descController.text += ' ${result.recognizedWords}';
              }

              if (result.finalResult) {
                _isListening = false;
              }
            });
          },
        );
      }
    } else {
      setState(() {
        _isListening = false;
        _speech.stop();
      });
    }
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

    if (!mounted) return;
    Provider.of<IdeaProvider>(context, listen: false).refresh();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _newTagController.dispose();
    _speech.cancel();
    super.dispose();
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
                decoration: InputDecoration(
                  labelText: 'Description',
                  suffixIcon: IconButton(
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                    onPressed: _startVoiceInput,
                    color: _isListening ? Colors.red : null,
                  ),
                ),
                maxLines: 3,
              ),
              if (_isListening)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Listening...',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Voice Input Used?'),
                subtitle: const Text('Auto-enabled when using the mic'),
                value: _voiceInput,
                onChanged: null, // ← disables interaction safely
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
                    selectedColor:
                        Theme.of(context).colorScheme.primaryContainer,
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
