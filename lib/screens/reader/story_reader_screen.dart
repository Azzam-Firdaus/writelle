import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/story_cover_image.dart';
import '../../core/widgets/writtle_action_pills.dart';
import '../../core/widgets/writtle_ambient_background.dart';
import '../../core/widgets/writtle_auth_guard.dart';
import '../../core/widgets/writtle_avatar.dart';
import '../../core/widgets/writtle_editorial_content.dart';
import '../../models/story_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../repositories/follow_repository.dart';
import '../editor/story_editor_screen.dart';
import '../profile/public_profile_screen.dart';

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
  bool _isAuthor = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _story = widget.story;
    _checkAuthorStatus();
  }

  Future<void> _checkAuthorStatus() async {
    final authRepo = ref.read(authRepositoryProvider);
    final currentUserId = authRepo.currentUser?.id;
    if (currentUserId != null && _story.userId == currentUserId) {
      if (mounted) setState(() => _isAuthor = true);
    } else {
      final isAuthor = await ref.read(storyRepositoryProvider).isStoryAuthor(_story.id);
      if (mounted) setState(() => _isAuthor = isAuthor);
    }

    try {
      final profile = await authRepo.getCurrentProfile();
      if (mounted && profile != null && profile.isAdmin) {
        setState(() => _isAdmin = true);
      }
    } catch (_) {}
  }

  Future<void> _handleEditStory() async {
    final updated = await Navigator.of(context).push<StoryModel>(
      MaterialPageRoute(
        builder: (_) => StoryEditorScreen(initialStory: _story),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _story = updated);
    }
    ref.invalidate(feedStoriesProvider);
    ref.invalidate(myPublishedStoriesProvider);
    ref.invalidate(myDraftStoriesProvider);
  }

  Future<void> _handleDeleteStory() async {
    final isDeletingAsAdmin = _isAdmin && !_isAuthor;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isDeletingAsAdmin ? 'Move Tale to Trash (Admin)?' : 'Erase Tale?'),
        content: Text(
          isDeletingAsAdmin
              ? 'As a curator/admin, moving "${_story.title}" to trash will hide it from the sanctuary. It will be safely stored for 14 days and can be restored from the Curator Chamber before permanent erasure.'
              : 'Are you sure you wish to release this story into silence? This action cannot be recalled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isDeletingAsAdmin ? 'Move to Trash (14d)' : 'Erase'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repo = ref.read(storyRepositoryProvider);
        await repo.deleteStory(_story.id, asAdmin: _isAdmin, storyTitle: _story.title);

        ref.invalidate(feedStoriesProvider);
        ref.invalidate(myPublishedStoriesProvider);
        ref.invalidate(myDraftStoriesProvider);
        ref.invalidate(bookmarkedStoriesProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isDeletingAsAdmin
                    ? 'Story moved to trash (stored for 14 days).'
                    : 'Tale returned to silence.',
              ),
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not erase tale: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleToggleLike() async {
    if (!WrittleAuthGuard.check(
      context,
      ref,
      title: 'Like Story',
      message: 'Please sign in or create an account to like this story.',
    )) {
      return;
    }

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
      ref.invalidate(bookmarkedStoriesProvider);
      ref.invalidate(myPublishedStoriesProvider);
      ref.invalidate(myDraftStoriesProvider);
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
    if (!WrittleAuthGuard.check(
      context,
      ref,
      title: 'Save to Keepsakes',
      message: 'Please sign in or create an account to preserve this story in your keepsakes.',
    )) {
      return;
    }

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
      ref.invalidate(bookmarkedStoriesProvider);
      ref.invalidate(myPublishedStoriesProvider);
      ref.invalidate(myDraftStoriesProvider);
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

  void _handleShareStory() {
    final shareText = '${_story.title}\nBy ${_story.authorName}\n\nOn Writelle';
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Story link and snippet copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showReportDialog() {
    if (!WrittleAuthGuard.check(
      context,
      ref,
      title: 'Report Story',
      message: 'Please sign in or create an account to report this story.',
    )) {
      return;
    }

    String selectedReason = 'spam';
    final detailsController = TextEditingController();
    bool isSubmitting = false;

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
                    onChanged: isSubmitting
                        ? null
                        : (val) {
                            if (val != null) setDialogState(() => selectedReason = val);
                          },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: detailsController,
                    enabled: !isSubmitting,
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
                onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
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
                          if (ctx.mounted) {
                            setDialogState(() => isSubmitting = false);
                          }
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                            );
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Report'),
              ),
            ],
          );
        },
      ),
    ).whenComplete(() => detailsController.dispose());
  }

  void _onAuthorTapped(BuildContext context) {
    if (_story.isAnonymous) {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surfaceLight,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceWarm,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, color: AppColors.textSecondary, size: 26),
              ),
              const SizedBox(height: 14),
              Text(
                'Veiled in Anonymity',
                style: AppTypography.storyHeading.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'This author chose to share this tale under a cloak of quiet silence. Their identity remains sheltered in Writtle.',
                textAlign: TextAlign.center,
                style: AppTypography.uiBody.copyWith(color: AppColors.textSecondary, height: 1.45),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    } else {
      if (_story.userId == null || _story.userId!.isEmpty) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PublicProfileScreen(
            authorId: _story.userId!,
            initialPenName: _story.authorName,
          ),
        ),
      );
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Recent';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final hasCover = _story.coverUrl != null && _story.coverUrl!.trim().isNotEmpty;
    final formattedDate = _formatDate(_story.publishedAt ?? _story.createdAt);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimaryColor(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _story.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _story.isBookmarked ? AppColors.burntSienna : AppColors.textPrimaryColor(context),
            ),
            onPressed: _handleToggleBookmark,
          ),
          IconButton(
            icon: Icon(Icons.share_outlined, color: AppColors.textPrimaryColor(context)),
            tooltip: 'Share Tale',
            onPressed: _handleShareStory,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.textPrimaryColor(context)),
            onSelected: (val) {
              if (val == 'edit') {
                _handleEditStory();
              } else if (val == 'delete') {
                _handleDeleteStory();
              } else if (val == 'report') {
                _showReportDialog();
              }
            },
            itemBuilder: (context) => [
              if (_isAuthor)
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit Tale'),
                    ],
                  ),
                ),
              if (_isAuthor || _isAdmin)
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text(
                        _isAuthor ? 'Erase Tale' : 'Delete Tale (Admin)',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              if (!_isAuthor)
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag_outlined, size: 18, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Report Whisper'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: WrittleAmbientBackground(
        variant: AmbientVariant.reader,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Single Category Tag at Top (Substack style)
              if (_story.categoryName.trim().isNotEmpty) ...[
                _buildTopicChip(context, _story.categoryName.trim(), isSelected: true),
                const SizedBox(height: 14),
              ],

              // 2. Editorial Headline Title (Substack prominent serif headline)
              Text(
                _story.title,
                style: AppTypography.displayTitle.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.24,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 10),

              // 3. Reading Meta Info (e.g. 6 min read Â· Jul 9)
              Row(
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    size: 14,
                    color: AppColors.burntSienna,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_story.readingTime} Â· $formattedDate',
                    style: AppTypography.captionMeta.copyWith(
                      fontSize: 12.5,
                      color: AppColors.textSecondaryColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 4. Author Attribution Card with Follow Button
              InkWell(
                onTap: () => _onAuthorTapped(context),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      if (_story.isAnonymous)
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.surfaceWarmColor(context),
                          child: Icon(Icons.shield_outlined, size: 20, color: AppColors.burntSienna),
                        )
                      else
                        WrittleAvatar(
                          avatarUrl: null,
                          radius: 20,
                          fallbackInitial: _story.authorName.isNotEmpty ? _story.authorName[0] : 'W',
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _story.authorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.uiBodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                                color: AppColors.textPrimaryColor(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _story.isAnonymous
                                  ? 'Identity veiled in silence'
                                  : '@${_story.authorName.toLowerCase().replaceAll(RegExp(r'\s+'), '')}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.captionMeta.copyWith(
                                fontSize: 11.5,
                                color: AppColors.textSecondaryColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Follow Button for Reader
                      if (!_story.isAnonymous && _story.userId != null && !_isAuthor) ...[
                        const SizedBox(width: 8),
                        _FollowAuthorPill(authorId: _story.userId!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 5. Cover Image (Rounded 16:9 hero image below author)
              if (hasCover) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: StoryCoverImage(
                      coverUrl: _story.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 6. Narrative Story Body with Highlighter Feature & Pull Quotes
              WrittleEditorialContent(
                content: _story.content,
                defaultStyle: AppTypography.storyBody.copyWith(
                  fontSize: 17.5,
                  height: 1.85,
                  color: AppColors.textPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 28),

              // 7. Substack-style Bottom Interaction Bar (Like, Comment, Save, Share) - Tanpa Edit
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.borderColor(context), width: 1),
                    bottom: BorderSide(color: AppColors.borderColor(context), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // Like Pill
                    WrittleLikePill(
                      key: ValueKey('like_${_story.id}'),
                      isLiked: _story.isLiked,
                      likesCount: _story.likesCount,
                      onTap: _handleToggleLike,
                      isCompact: true,
                    ),

                    const Spacer(),

                    // Save / Bookmark Pill
                    WrittleBookmarkPill(
                      key: ValueKey('bookmark_${_story.id}'),
                      isBookmarked: _story.isBookmarked,
                      onTap: _handleToggleBookmark,
                      isCompact: true,
                    ),
                    const SizedBox(width: 8),

                    // Share Button
                    IconButton(
                      icon: const Icon(Icons.share_outlined, size: 20, color: AppColors.burntSienna),
                      tooltip: 'Share Tale',
                      onPressed: _handleShareStory,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopicChip(BuildContext context, String topic, {bool isSelected = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.burntSienna.withValues(alpha: isDark ? 0.25 : 0.12)
            : (isDark ? AppColors.softParchment.withValues(alpha: 0.08) : AppColors.softParchment.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected
              ? AppColors.burntSienna.withValues(alpha: 0.5)
              : AppColors.warmSand.withValues(alpha: isDark ? 0.25 : 0.5),
        ),
      ),
      child: Text(
        topic,
        style: AppTypography.captionMeta.copyWith(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.burntSienna : AppColors.textSecondaryColor(context),
        ),
      ),
    );
  }
}

/// Follow/Following author pill button for Story Reader (Image 1).
class _FollowAuthorPill extends ConsumerStatefulWidget {
  final String authorId;
  const _FollowAuthorPill({required this.authorId});

  @override
  ConsumerState<_FollowAuthorPill> createState() => _FollowAuthorPillState();
}

class _FollowAuthorPillState extends ConsumerState<_FollowAuthorPill> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authRepositoryProvider).currentUser?.id;
    if (currentUserId == null || currentUserId == widget.authorId) {
      return const SizedBox.shrink();
    }

    final isFollowingAsync = ref.watch(isFollowingTargetProvider(widget.authorId));
    final isFollowing = isFollowingAsync.value ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: _isLoading
          ? null
          : () async {
              setState(() => _isLoading = true);
              final repo = ref.read(followRepositoryProvider);
              try {
                if (isFollowing) {
                  await repo.unfollow(
                    followerId: currentUserId,
                    followingId: widget.authorId,
                  );
                } else {
                  await repo.follow(
                    followerId: currentUserId,
                    followingId: widget.authorId,
                  );
                }
                ref.invalidate(isFollowingTargetProvider(widget.authorId));
                ref.invalidate(userFollowStatsProvider(widget.authorId));
              } catch (_) {
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isFollowing
              ? (isDark ? AppColors.softParchment.withValues(alpha: 0.12) : AppColors.softParchment)
              : AppColors.espresso,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFollowing ? AppColors.warmSand : AppColors.espresso,
            width: 1.2,
          ),
          boxShadow: isFollowing
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
        ),
        child: _isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isFollowing) ...[
                    const Icon(Icons.check, size: 13, color: AppColors.burntSienna),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isFollowing ? AppColors.textPrimaryColor(context) : Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
