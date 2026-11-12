import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/cache/cover_cache.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/reading_time_calculator.dart';
import '../../core/utils/editorial_text_controller.dart';
import '../../core/widgets/anonymity_toggle.dart';
import '../../core/widgets/story_cover_image.dart';
import '../../core/widgets/writtle_ambient_background.dart';
import '../../core/widgets/writtle_editorial_content.dart';
import '../../core/widgets/writtle_image_cropper.dart';
import '../../models/category_model.dart';
import '../../models/story_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';

class StoryEditorScreen extends ConsumerStatefulWidget {
  final StoryModel? initialStory;

  const StoryEditorScreen({super.key, this.initialStory});

  @override
  ConsumerState<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends ConsumerState<StoryEditorScreen> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _contentController = WrittleEditorialTextController();
  final _contentUndoController = UndoHistoryController();

  final _titleFocusNode = FocusNode();
  final _subtitleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();

  String? _selectedCategoryId;
  String? _coverUrl;
  String? _localCoverPath;
  bool _isUploadingCover = false;
  bool _showRealName = false;
  bool _isSavingDraft = false;
  bool _isPublishing = false;
  bool _isPreview = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialStory != null) {
      final s = widget.initialStory!;
      _titleController.text = s.title;

      // Extract subtitle if explicitly formatted as heading (## )
      final lines = s.content.split('\n');
      String extractedSub = '';
      final List<String> bodyLines = [];
      bool foundSub = false;

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (!foundSub && (line.startsWith('## ') || line.startsWith('### '))) {
          extractedSub = line.replaceFirst(RegExp(r'^#+\s*'), '').trim();
          foundSub = true;
        } else {
          bodyLines.add(lines[i]);
        }
      }

      _subtitleController.text = extractedSub;
      _contentController.text = bodyLines.join('\n').trim();

      _selectedCategoryId = s.categoryId;
      _coverUrl = s.coverUrl ?? CoverCache.get(s.id);
      _localCoverPath = (_coverUrl != null && !_coverUrl!.startsWith('http')) ? _coverUrl : null;
      _showRealName = !s.isAnonymous;
    }
  }

  @override
  void dispose() {
    _titleFocusNode.dispose();
    _subtitleFocusNode.dispose();
    _contentFocusNode.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _contentController.dispose();
    _contentUndoController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadCoverFromGallery() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Fitur Crop: Sesuaikan framing gambar sampul ke rasio 16:9
      XFile uploadTarget = pickedFile;
      if (!kIsWeb && mounted) {
        final cropped = await WrittleImageCropper.crop(context, imageFile: File(pickedFile.path));
        if (cropped != null) {
          uploadTarget = XFile(cropped.path);
        }
      }

      // 1. Instant local preview
      setState(() {
        _localCoverPath = uploadTarget.path;
        _coverUrl = uploadTarget.path;
        _isUploadingCover = true;
      });

      // 2. Background upload to Supabase Storage
      final repo = ref.read(storyRepositoryProvider);
      final uploadedUrl = await repo.uploadCoverImage(uploadTarget);

      if (mounted) {
        setState(() {
          _coverUrl = uploadedUrl;
          _isUploadingCover = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story cover uploaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingCover = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Cover upload notice: $e'),
          ),
        );
      }
    }
  }

  void _showCoverActionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                height: 4,
                width: 36,
                decoration: BoxDecoration(
                  color: AppColors.borderColor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (_localCoverPath != null && !kIsWeb)
                ListTile(
                  leading: const Icon(Icons.crop, color: AppColors.burntSienna),
                  title: const Text('Crop / Re-frame Cover (16:9)'),
                  onTap: () async {
                    Navigator.of(bottomCtx).pop();
                    final cropped = await WrittleImageCropper.crop(
                      context,
                      imageFile: File(_localCoverPath!),
                    );
                    if (cropped != null && mounted) {
                      setState(() {
                        _localCoverPath = cropped.path;
                        _coverUrl = cropped.path;
                        _isUploadingCover = true;
                      });
                      try {
                        final repo = ref.read(storyRepositoryProvider);
                        final uploadedUrl = await repo.uploadCoverImage(XFile(cropped.path));
                        if (mounted) {
                          setState(() {
                            _coverUrl = uploadedUrl;
                            _isUploadingCover = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cover cropped & updated!')),
                          );
                        }
                      } catch (e) {
                        if (mounted) setState(() => _isUploadingCover = false);
                      }
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.burntSienna),
                title: const Text('Choose Another Photo from Gallery'),
                onTap: () {
                  Navigator.of(bottomCtx).pop();
                  _pickAndUploadCoverFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Remove Story Cover', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.of(bottomCtx).pop();
                  setState(() {
                    _coverUrl = null;
                    _localCoverPath = null;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInsertLinkDialog() {
    final urlController = TextEditingController(text: 'https://');
    final labelController = TextEditingController();

    final sel = _contentController.selection;
    if (!sel.isCollapsed && sel.isValid && sel.start >= 0 && sel.end <= _contentController.text.length) {
      labelController.text = _contentController.text.substring(sel.start, sel.end);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sisipkan Tautan (Link)',
          style: AppTypography.storyHeading.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'Teks Tautan',
                hintText: 'Judul atau label tautan',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL Tautan',
                hintText: 'https://example.com',
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.burntSienna,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final url = urlController.text.trim();
              final label = labelController.text.trim().isEmpty ? url : labelController.text.trim();
              if (url.isNotEmpty && url != 'https://') {
                final linkMarkdown = '[$label]($url)';
                if (!sel.isCollapsed && sel.isValid) {
                  _contentController.text =
                      _contentController.text.replaceRange(sel.start, sel.end, linkMarkdown);
                } else {
                  final pos = sel.baseOffset >= 0 ? sel.baseOffset : _contentController.text.length;
                  _contentController.text =
                      _contentController.text.replaceRange(pos, pos, linkMarkdown);
                }
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Sisipkan'),
          ),
        ],
      ),
    );
  }

  void _showFormattingStyleSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderColor(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.text_format, color: AppColors.burntSienna, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Format Penulisan (Styling)',
                      style: AppTypography.storyHeading.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryColor(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildQuickFormatPill(
                      icon: Icons.border_color,
                      label: 'Stabilo (Highlight)',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _contentController.toggleStabilo();
                        Navigator.of(sheetCtx).pop();
                      },
                    ),
                    _buildQuickFormatPill(
                      icon: Icons.title,
                      label: 'Judul Bagian (H2)',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _contentController.toggleHeading();
                        Navigator.of(sheetCtx).pop();
                      },
                    ),
                    _buildQuickFormatPill(
                      icon: Icons.format_bold,
                      label: 'Tebal (Bold)',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _contentController.toggleBold();
                        Navigator.of(sheetCtx).pop();
                      },
                    ),
                    _buildQuickFormatPill(
                      icon: Icons.format_italic,
                      label: 'Miring (Italic)',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _contentController.toggleItalic();
                        Navigator.of(sheetCtx).pop();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickFormatPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceWarmColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderColor(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.burntSienna),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _handleExitMode() {
    final hasContent = _titleController.text.trim().isNotEmpty ||
        _contentController.text.trim().isNotEmpty ||
        _subtitleController.text.trim().isNotEmpty;

    if (hasContent) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Keluar dari Mode Artikel?',
            style: AppTypography.storyHeading.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: const Text('Apakah Anda ingin menyimpan draf tulisan Anda sebelum keluar?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Buang', style: TextStyle(color: AppColors.error)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.burntSienna,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _handleSave(isDraft: true);
              },
              child: const Text('Simpan Draf'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleSave({required bool isDraft}) async {
    final title = _titleController.text.trim();
    final subtitle = _subtitleController.text.trim();
    final body = _contentController.text.trim();

    // Gabungkan subjudul jika ada menggunakan heading markdown standar
    final content = subtitle.isNotEmpty ? '## $subtitle\n\n$body' : body;

    if (!isDraft) {
      if (title.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Judul cerita memerlukan minimal 3 karakter.')),
        );
        return;
      }
      if (body.length < 20) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Isi cerita memerlukan minimal 20 karakter.')),
        );
        return;
      }
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih topik/kategori cerita Anda.')),
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
      final isAnonymous = !_showRealName;
      final effectiveCover = (_coverUrl != null && _coverUrl!.isNotEmpty)
          ? _coverUrl
          : (_localCoverPath != null && _localCoverPath!.isNotEmpty ? _localCoverPath : null);

      if (widget.initialStory != null) {
        await repo.updateStory(
          storyId: widget.initialStory!.id,
          categoryId: effectiveCatId,
          title: title.isEmpty ? 'Untitled Story' : title,
          content: content,
          isAnonymous: isAnonymous,
          isDraft: isDraft,
          coverUrl: effectiveCover,
        );

        if (effectiveCover != null && effectiveCover.isNotEmpty) {
          CoverCache.set(widget.initialStory!.id, effectiveCover);
        }

        final updatedStory = widget.initialStory!.copyWith(
          title: title.isEmpty ? 'Untitled Story' : title,
          content: content,
          categoryId: effectiveCatId,
          isAnonymous: isAnonymous,
          coverUrl: effectiveCover,
        );

        ref.invalidate(feedStoriesProvider);
        ref.invalidate(myPublishedStoriesProvider);
        ref.invalidate(myDraftStoriesProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isDraft ? 'Draf berhasil disimpan dengan tenang.' : 'Karya cerita berhasil diperbarui!',
              ),
            ),
          );
          Navigator.of(context).pop(updatedStory);
        }
        return;
      } else {
        final createdStory = await repo.createStory(
          categoryId: effectiveCatId,
          title: title.isEmpty ? 'Untitled Story' : title,
          content: content,
          isAnonymous: isAnonymous,
          isDraft: isDraft,
          coverUrl: effectiveCover,
        );

        if (effectiveCover != null && effectiveCover.isNotEmpty) {
          CoverCache.set(createdStory.id, effectiveCover);
        }
      }

      ref.invalidate(feedStoriesProvider);
      ref.invalidate(myPublishedStoriesProvider);
      ref.invalidate(myDraftStoriesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDraft ? 'Draf berhasil disimpan dengan tenang.' : 'Kisah Anda telah dibagikan ke sanctuary!',
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

  Widget _buildPreviewView(List<CategoryModel> categories, String penName) {
    final title = _titleController.text.trim().isEmpty ? 'Untitled Story' : _titleController.text.trim();
    final subtitle = _subtitleController.text.trim();
    final body = _contentController.text.trim();
    final content = subtitle.isNotEmpty ? '## $subtitle\n\n$body' : body;

    final cat = categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => categories.isNotEmpty
          ? categories.first
          : const CategoryModel(id: '', name: 'General', slug: 'general', description: null),
    );
    final readingTime = ReadingTimeCalculator.calculate(content);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceWarmColor(context),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.borderColor(context)),
            ),
            child: Row(
              children: [
                const Icon(Icons.remove_red_eye_outlined, size: 16, color: AppColors.burntSienna),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Preview Mode — Beginilah tampilan cerita Anda saat dibaca.',
                    style: AppTypography.captionMeta.copyWith(
                      color: AppColors.textPrimaryColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Cover Image Preview
          if ((_localCoverPath != null && _localCoverPath!.isNotEmpty) ||
              (_coverUrl != null && _coverUrl!.isNotEmpty)) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _localCoverPath != null && !kIsWeb
                    ? Image.file(
                        File(_localCoverPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => StoryCoverImage(
                          coverUrl: _coverUrl,
                          fit: BoxFit.cover,
                        ),
                      )
                    : StoryCoverImage(
                        coverUrl: _coverUrl ?? _localCoverPath,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Category & Reading Time
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.burntSienna.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  cat.name.toUpperCase(),
                  style: AppTypography.captionMeta.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.burntSienna,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('•'),
              const SizedBox(width: 8),
              Text(readingTime, style: AppTypography.captionMeta),
            ],
          ),
          const SizedBox(height: 16),

          // Story Title
          Text(title, style: AppTypography.displayTitle.copyWith(fontSize: 26, height: 1.25)),
          const SizedBox(height: 12),

          // Author Meta
          Row(
            children: [
              Icon(
                !_showRealName ? Icons.shield_outlined : Icons.person_outline,
                size: 15,
                color: AppColors.textSecondaryColor(context),
              ),
              const SizedBox(width: 6),
              Text(
                !_showRealName ? 'Anonymous' : '@$penName',
                style: AppTypography.captionMeta.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Divider(height: 36),

          // Narrative Body
          WrittleEditorialContent(
            content: content,
            defaultStyle: AppTypography.storyBody.copyWith(fontSize: 17.5, height: 1.8),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final penName = userProfileAsync.value?.penName ?? 'Author';
    final categories = categoriesAsync.value ?? [];

    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textPrimaryColor(context)),
          onPressed: _handleExitMode,
        ),
        title: Text(
          _isPreview ? 'Pratinjau Cerita' : 'Tulis Artikel',
          style: AppTypography.storyHeading.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryColor(context),
          ),
        ),
        actions: [
          // Preview Toggle
          IconButton(
            icon: Icon(
              _isPreview ? Icons.edit_note : Icons.remove_red_eye_outlined,
              size: 20,
              color: AppColors.burntSienna,
            ),
            tooltip: _isPreview ? 'Edit' : 'Pratinjau',
            onPressed: () => setState(() => _isPreview = !_isPreview),
          ),
          // Draf Button
          TextButton(
            onPressed: _isSavingDraft || _isPublishing ? null : () => _handleSave(isDraft: true),
            child: _isSavingDraft
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.burntSienna),
                  )
                : Text(
                    'Draf',
                    style: AppTypography.uiBodyMedium.copyWith(
                      color: AppColors.textSecondaryColor(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
          ),
          const SizedBox(width: 4),
          // Terbitkan Button
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.burntSienna,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _isSavingDraft || _isPublishing ? null : () => _handleSave(isDraft: false),
              child: _isPublishing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Terbitkan',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
      body: WrittleAmbientBackground(
        variant: AmbientVariant.editor,
        child: _isPreview
            ? _buildPreviewView(categories, penName)
            : SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Cover Photo Section (Rasio 16:9 dengan fitur Cropping)
                    _buildCoverSection(),
                    const SizedBox(height: 16),

                    // 2. Anonymity Toggle Banner (Statis sesuai tampilan sebelumnya)
                    AnonymityToggle(
                      isAnonymous: !_showRealName,
                      penName: penName,
                      onChanged: (val) {
                        setState(() => _showRealName = !val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // 3. Category Picker (Statis sesuai tampilan sebelumnya)
                    categoriesAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (err, stack) => const SizedBox.shrink(),
                      data: (cats) {
                        if (cats.isEmpty) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWarmColor(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderColor(context)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              dropdownColor: AppColors.surface(context),
                              hint: Text(
                                'Pilih Kategori Cerita',
                                style: AppTypography.uiBodyMedium.copyWith(
                                  color: AppColors.textSecondaryColor(context),
                                ),
                              ),
                              value: _selectedCategoryId ?? cats.first.id,
                              icon: const Icon(Icons.arrow_drop_down, color: AppColors.burntSienna),
                              items: cats.map((cat) {
                                return DropdownMenuItem<String>(
                                  value: cat.id,
                                  child: Text(
                                    cat.name,
                                    style: AppTypography.uiBodyMedium.copyWith(
                                      color: AppColors.textPrimaryColor(context),
                                    ),
                                  ),
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
                    const SizedBox(height: 20),

                    // 3. Judul (Title TextField - Clean, prominent typography matching screenshot)
                    TextField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      style: AppTypography.storyHeading.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryColor(context),
                        height: 1.25,
                      ),
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Judul',
                        hintStyle: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textTertiaryColor(context).withValues(alpha: 0.5),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 4. Tambahkan subjudul... (Subtitle TextField matching screenshot)
                    TextField(
                      controller: _subtitleController,
                      focusNode: _subtitleFocusNode,
                      style: AppTypography.uiBody.copyWith(
                        fontSize: 16,
                        color: AppColors.textSecondaryColor(context),
                        height: 1.4,
                      ),
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Tambahkan subjudul...',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: AppColors.textTertiaryColor(context).withValues(alpha: 0.6),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. Mulai menulis artikel... (Content Body TextField matching screenshot)
                    TextField(
                      controller: _contentController,
                      focusNode: _contentFocusNode,
                      undoController: _contentUndoController,
                      style: AppTypography.storyBody.copyWith(
                        fontSize: 17.5,
                        height: 1.8,
                        color: AppColors.textPrimaryColor(context),
                      ),
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      minLines: 12,
                      decoration: InputDecoration(
                        hintText: 'Mulai menulis artikel...',
                        hintStyle: TextStyle(
                          fontSize: 17.5,
                          height: 1.8,
                          color: AppColors.textTertiaryColor(context).withValues(alpha: 0.5),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomAccessoryBar(),
    );
  }

  // Cover image section matching the user's specification
  Widget _buildCoverSection() {
    if ((_localCoverPath != null && _localCoverPath!.isNotEmpty) ||
        (_coverUrl != null && _coverUrl!.isNotEmpty)) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _localCoverPath != null && !kIsWeb
                  ? Image.file(
                      File(_localCoverPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => StoryCoverImage(
                        coverUrl: _coverUrl,
                        fit: BoxFit.cover,
                      ),
                    )
                  : StoryCoverImage(
                      coverUrl: _coverUrl ?? _localCoverPath,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          if (_isUploadingCover)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      SizedBox(height: 8),
                      Text(
                        'Mengunggah sampul...',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Crop / Re-frame Cover Button
                if (_localCoverPath != null && !kIsWeb) ...[
                  InkWell(
                    onTap: () async {
                      final cropped = await WrittleImageCropper.crop(
                        context,
                        imageFile: File(_localCoverPath!),
                      );
                      if (cropped != null && mounted) {
                        setState(() {
                          _localCoverPath = cropped.path;
                          _coverUrl = cropped.path;
                          _isUploadingCover = true;
                        });
                        try {
                          final repo = ref.read(storyRepositoryProvider);
                          final uploadedUrl = await repo.uploadCoverImage(XFile(cropped.path));
                          if (mounted) {
                            setState(() {
                              _coverUrl = uploadedUrl;
                              _isUploadingCover = false;
                            });
                          }
                        } catch (_) {
                          if (mounted) setState(() => _isUploadingCover = false);
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.crop, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Crop', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                // Menu actions
                InkWell(
                  onTap: _showCoverActionsModal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_camera, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Ubah', style: TextStyle(color: Colors.white, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return InkWell(
        onTap: _pickAndUploadCoverFromGallery,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceWarmColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor(context)),
          ),
          child: const Column(
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 30, color: AppColors.burntSienna),
              SizedBox(height: 6),
              Text(
                'Pilih Sampul Cerita (16:9)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.espresso,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Mendukung fitur pemotongan / cropping foto',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.mutedCocoa,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // Bottom Toolbar matching the user's screenshot
  Widget _buildBottomAccessoryBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Floating Pill Button: "↩ Keluar dari mode artikel"
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: InkWell(
            onTap: _handleExitMode,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.softParchment.withValues(alpha: 0.12) : AppColors.softParchment,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderColor(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.undo, size: 16, color: AppColors.textPrimaryColor(context)),
                  const SizedBox(width: 8),
                  Text(
                    'Keluar dari mode artikel',
                    style: AppTypography.uiBodyMedium.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom Accessory Bar with 6 actions from screenshot
        Container(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            MediaQuery.of(context).viewInsets.bottom > 0
                ? 8
                : 8 + (MediaQuery.of(context).viewPadding.bottom > 0 ? MediaQuery.of(context).viewPadding.bottom : 8),
          ),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            border: Border(top: BorderSide(color: AppColors.borderColor(context), width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. (+) Circle Button (Hanya untuk menambahkan / mengatur sampul cerita)
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if ((_coverUrl != null && _coverUrl!.isNotEmpty) ||
                      (_localCoverPath != null && _localCoverPath!.isNotEmpty)) {
                    _showCoverActionsModal();
                  } else {
                    _pickAndUploadCoverFromGallery();
                  }
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.espresso,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),

              // 2. Link Icon
              IconButton(
                icon: Icon(Icons.link, color: AppColors.textPrimaryColor(context), size: 24),
                tooltip: 'Sisipkan Tautan',
                onPressed: _showInsertLinkDialog,
              ),

              // 3. Bullet List Icon
              IconButton(
                icon: Icon(Icons.format_list_bulleted, color: AppColors.textPrimaryColor(context), size: 24),
                tooltip: 'Daftar Poin',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _contentController.toggleBulletList();
                },
              ),

              // 4. Quote Icon
              IconButton(
                icon: Icon(Icons.format_quote_rounded, color: AppColors.textPrimaryColor(context), size: 24),
                tooltip: 'Kutipan (Quote)',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _contentController.toggleQuote();
                },
              ),

              // 5. Undo Icon
              IconButton(
                icon: Icon(Icons.undo, color: AppColors.textPrimaryColor(context), size: 22),
                tooltip: 'Undo',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _contentUndoController.undo();
                },
              ),

              // 6. Styling / Format Penulisan Icon (menggantikan sembunyikan keyboard)
              IconButton(
                icon: Icon(Icons.text_format, color: AppColors.textPrimaryColor(context), size: 26),
                tooltip: 'Format Penulisan',
                onPressed: _showFormattingStyleSheet,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
