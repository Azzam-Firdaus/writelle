import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/anonymity_toggle.dart';
import '../../core/widgets/editorial_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';

class StoryEditorScreen extends ConsumerStatefulWidget {
  const StoryEditorScreen({super.key});

  @override
  ConsumerState<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends ConsumerState<StoryEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _selectedCategoryId;
  bool _isAnonymous = true;
  bool _isSavingDraft = false;
  bool _isPublishing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleSave({required bool isDraft}) async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (!isDraft) {
      if (title.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title must be at least 3 characters long.')),
        );
        return;
      }
      if (content.length < 30) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story content must be at least 30 characters long.')),
        );
        return;
      }
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category for your story.')),
        );
        return;
      }
    }

    setState(() {
      if (isDraft) {
        _isSavingDraft = true;
      } else {
        _isPublishing = true;
      }
    });

    try {
      final repo = ref.read(storyRepositoryProvider);
      final categories = ref.read(categoriesProvider).value ?? [];
      final effectiveCatId = _selectedCategoryId ?? (categories.isNotEmpty ? categories.first.id : '');

      await repo.createStory(
        categoryId: effectiveCatId,
        title: title.isEmpty ? 'Untitled Story' : title,
        content: content,
        isAnonymous: _isAnonymous,
        isDraft: isDraft,
      );

      ref.invalidate(feedStoriesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDraft ? 'Draft saved privately.' : 'Your story has been published!',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingDraft = false;
          _isPublishing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final penName = userProfileAsync.value?.penName ?? 'Author';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSavingDraft || _isPublishing
                ? null
                : () => _handleSave(isDraft: true),
            child: _isSavingDraft
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Draft'),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: EditorialButton(
              label: 'Publish',
              isLoading: _isPublishing,
              variant: EditorialButtonVariant.secondary,
              onPressed: () => _handleSave(isDraft: false),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Anonymity Toggle Banner (BR-002, BR-003)
            AnonymityToggle(
              isAnonymous: _isAnonymous,
              penName: penName,
              onChanged: (val) => setState(() => _isAnonymous = val),
            ),
            const SizedBox(height: 20),

            // Category Picker
            categoriesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => const SizedBox.shrink(),
              data: (categories) {
                if (categories.isEmpty) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Select a Category'),
                      value: _selectedCategoryId ?? categories.first.id,
                      items: categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name, style: AppTypography.uiBodyMedium),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategoryId = val);
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Story Title Field
            TextField(
              controller: _titleController,
              style: AppTypography.storyHeading.copyWith(fontSize: 22),
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Give your story a title...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const Divider(height: 32),

            // Story Body Content Field
            TextField(
              controller: _contentController,
              style: AppTypography.storyBody.copyWith(fontSize: 17),
              maxLines: null,
              minLines: 12,
              decoration: const InputDecoration(
                hintText: 'Share what’s on your mind... your story is safe here.',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
