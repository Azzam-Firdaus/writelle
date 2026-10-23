import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/comment_model.dart';
import '../../models/story_model.dart';
import '../../providers/feed_provider.dart';

class StoryReaderScreen extends ConsumerStatefulWidget {
  final StoryModel story;

  const StoryReaderScreen({super.key, required this.story});

  @override
  ConsumerState<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends ConsumerState<StoryReaderScreen> {
  late StoryModel _story;
  bool _isLiking = false;
  bool _isBookmarking = false;

  @override
  void initState() {
    super.initState();
    _story = widget.story;
  }

  Future<void> _handleToggleLike() async {
    if (_isLiking) return;
    setState(() => _isLiking = true);

    try {
      final repo = ref.read(storyRepositoryProvider);
      final newLikedState = await repo.toggleLike(_story.id);
      setState(() {
        _story = _story.copyWith(
          isLiked: newLikedState,
          likesCount: newLikedState ? _story.likesCount + 1 : _story.likesCount - 1,
        );
      });
      ref.invalidate(feedStoriesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLiking = false);
    }
  }

  Future<void> _handleToggleBookmark() async {
    if (_isBookmarking) return;
    setState(() => _isBookmarking = true);

    try {
      final repo = ref.read(storyRepositoryProvider);
      final newBookmarkedState = await repo.toggleBookmark(_story.id);
      setState(() {
        _story = _story.copyWith(isBookmarked: newBookmarkedState);
      });
      ref.invalidate(bookmarkedStoriesProvider);
      ref.invalidate(feedStoriesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isBookmarking = false);
    }
  }

  void _showReportDialog() {
    String selectedReason = 'spam';
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surfaceLight,
            title: Text(
              'Report Story',
              style: AppTypography.storyHeading.copyWith(fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Please select the reason for reporting this story:'),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: selectedReason,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'spam', child: Text('Spam or Advertisement')),
                      DropdownMenuItem(value: 'harassment', child: Text('Harassment or Bullying')),
                      DropdownMenuItem(value: 'hate_speech', child: Text('Hate Speech')),
                      DropdownMenuItem(value: 'explicit_content', child: Text('Explicit / Inappropriate Content')),
                      DropdownMenuItem(value: 'other', child: Text('Other Violation')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedReason = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: detailsController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Additional details (optional)...',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final navigator = Navigator.of(ctx);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final repo = ref.read(storyRepositoryProvider);
                    await repo.reportStory(_story.id, selectedReason, detailsController.text);
                    if (ctx.mounted) navigator.pop();
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Thank you. The report has been submitted.')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                      );
                    }
                  }
                },
                child: const Text('Submit Report'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openCommentsSheet() {
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: Column(
                  children: [
                    // Handle and Title
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      height: 4,
                      width: 36,
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Comments', style: AppTypography.uiHeadline),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Comments List
                    Expanded(
                      child: FutureBuilder<List<CommentModel>>(
                        future: ref.read(storyRepositoryProvider).getComments(_story.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary));
                          }
                          final comments = snapshot.data ?? [];
                          if (comments.isEmpty) {
                            return Center(
                              child: Text(
                                'No comments yet. Share an empathetic thought.',
                                style: AppTypography.uiBody.copyWith(color: AppColors.textSecondary),
                              ),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: comments.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, idx) {
                              final comment = comments[idx];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        comment.authorPenName,
                                        style: AppTypography.captionMeta.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(comment.content, style: AppTypography.uiBody),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // Input Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: AppColors.borderLight)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentController,
                              decoration: const InputDecoration(
                                hintText: 'Write a mindful comment...',
                                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.send, color: AppColors.accentPrimary),
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    final text = commentController.text.trim();
                                    if (text.isEmpty) return;
                                    final messenger = ScaffoldMessenger.of(context);
                                    setSheetState(() => isSubmitting = true);
                                    try {
                                      final repo = ref.read(storyRepositoryProvider);
                                      await repo.addComment(_story.id, text);
                                      commentController.clear();
                                      setState(() {
                                        _story = _story.copyWith(
                                          commentsCount: _story.commentsCount + 1,
                                        );
                                      });
                                    } catch (e) {
                                      if (mounted) {
                                        messenger.showSnackBar(
                                          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                                        );
                                      }
                                    } finally {
                                      setSheetState(() => isSubmitting = false);
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _story.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _story.isBookmarked ? AppColors.accentPrimary : AppColors.textPrimary,
            ),
            onPressed: _handleToggleBookmark,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onSelected: (val) {
              if (val == 'report') _showReportDialog();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Report Inappropriate'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.backgroundLight,
          border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Like action
              InkWell(
                onTap: _handleToggleLike,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        _story.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _story.isLiked ? AppColors.error : AppColors.textPrimary,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text('${_story.likesCount}', style: AppTypography.uiBodyMedium),
                    ],
                  ),
                ),
              ),

              // Comment action
              InkWell(
                onTap: _openCommentsSheet,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, color: AppColors.textPrimary, size: 20),
                      const SizedBox(width: 6),
                      Text('${_story.commentsCount} Comments', style: AppTypography.uiBodyMedium),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category & Read Time
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _story.categoryName.toUpperCase(),
                    style: AppTypography.captionMeta.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.accentPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('•', style: AppTypography.captionMeta),
                const SizedBox(width: 8),
                Text(_story.readingTime, style: AppTypography.captionMeta),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              _story.title,
              style: AppTypography.displayTitle.copyWith(
                fontSize: 26,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 14),

            // Author Identification
            Row(
              children: [
                Icon(
                  _story.isAnonymous ? Icons.shield_outlined : Icons.person_outline,
                  size: 16,
                  color: _story.isAnonymous ? AppColors.accentSubtle : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  _story.authorName,
                  style: AppTypography.uiBodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Narrative Story Body
            SelectableText(
              _story.content,
              style: AppTypography.storyBody.copyWith(
                fontSize: 18,
                height: 1.7,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
