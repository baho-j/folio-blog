import 'package:flutter/material.dart';

import '../models/post.dart';
import '../state/post_store.dart';
import '../theme/app_theme.dart';
import '../util/date_text.dart';

/// Creates a new post, or edits [post] when one is given.
class PostEditorScreen extends StatefulWidget {
  /// Creates an editor for [post], or for a new post when it is null.
  const PostEditorScreen({super.key, required this.store, this.post});

  /// Shared state of the application.
  final PostStore store;

  /// The post being edited, or null for a new one.
  final Post? post;

  @override
  State<PostEditorScreen> createState() => _PostEditorScreenState();
}

class _PostEditorScreenState extends State<PostEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Post _original = widget.post ?? Post.draft(DateTime.now());
  late final _title = TextEditingController(text: _original.title);
  late final _body = TextEditingController(text: _original.body);
  late DateTime _entryDate = _original.entryDate;
  bool _saving = false;

  bool get _isDirty =>
      _title.text != _original.title ||
      _body.text != _original.body ||
      _entryDate != _original.entryDate;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _entryDate = Post.dateOnly(picked));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await widget.store.save(
        _original.copyWith(
          title: _title.text.trim(),
          body: _body.text.trim(),
          entryDate: _entryDate,
        ),
      );
      navigator.pop();
    } on Exception {
      messenger.showSnackBar(const SnackBar(content: Text('The post could not be saved')));
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _leave() async {
    final navigator = Navigator.of(context);
    if (!_isDirty || await _confirmDiscard()) navigator.pop();
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your changes to this post have not been saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.post == null ? 'New post' : 'Edit post'),
          actions: [
            TextButton(onPressed: _saving ? null : _save, child: const Text('Save')),
            const SizedBox(width: AppSpacing.small),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.medium),
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                maxLength: Post.maxTitleLength,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                validator: Post.validateTitle,
              ),
              const SizedBox(height: AppSpacing.small),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of entry',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(longDate(_entryDate)),
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              TextFormField(
                controller: _body,
                decoration: const InputDecoration(labelText: 'Post', alignLabelWithHint: true),
                minLines: 8,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                validator: Post.validateBody,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
