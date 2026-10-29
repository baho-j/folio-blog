import 'dart:io';

import 'package:flutter/material.dart';

import '../models/post.dart';
import '../state/post_store.dart';
import '../theme/app_theme.dart';
import '../util/date_text.dart';
import '../widgets/image_source_sheet.dart';
import '../widgets/post_image.dart';

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
  String? _pickedImagePath;
  bool _saving = false;

  bool get _isDirty =>
      _title.text != _original.title ||
      _body.text != _original.body ||
      _entryDate != _original.entryDate ||
      _pickedImagePath != null;

  File? get _previewImage {
    final picked = _pickedImagePath;
    return picked != null ? File(picked) : widget.store.imageOf(_original);
  }

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

  Future<void> _chooseImage() async {
    final action = await showImageSourceSheet(context);
    if (action == null) return;
    await _attach(fromCamera: action == ImageAction.camera);
  }

  Future<void> _attach({required bool fromCamera}) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await widget.store.pickPhoto(fromCamera: fromCamera);
      if (path != null && mounted) setState(() => _pickedImagePath = path);
    } on Exception {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            fromCamera ? 'The camera could not be opened' : 'The gallery could not be opened',
          ),
        ),
      );
    }
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
        pickedImagePath: _pickedImagePath,
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
              _ImageArea(image: _previewImage, onTap: _chooseImage),
              const SizedBox(height: AppSpacing.large),
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

class _ImageArea extends StatelessWidget {
  const _ImageArea({this.image, required this.onTap});

  static const double _height = 200;

  final File? image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      label: image == null ? 'Add a photo' : 'Change or remove the photo',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: scheme.surfaceContainerLow,
          child: InkWell(
            onTap: onTap,
            child: image == null
                ? SizedBox(
                    height: _height,
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 32, color: scheme.primary),
                        const SizedBox(height: AppSpacing.small),
                        Text('Add a photo', style: theme.textTheme.labelLarge),
                      ],
                    ),
                  )
                : PostImage(file: image!, width: double.infinity, height: _height),
          ),
        ),
      ),
    );
  }
}
