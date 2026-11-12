import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/admin_models.dart';
import '../../models/category_model.dart';
import '../../models/story_model.dart';
import '../../core/widgets/writtle_avatar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../repositories/admin_repository.dart';
import '../profile/public_profile_screen.dart';
import '../reader/story_reader_screen.dart';

/// Editorial Admin CMS Screen for platform moderation, curator delegation, and audit logging.
class AdminCmsScreen extends ConsumerStatefulWidget {
  const AdminCmsScreen({super.key});

  @override
  ConsumerState<AdminCmsScreen> createState() => _AdminCmsScreenState();
}

class _AdminCmsScreenState extends ConsumerState<AdminCmsScreen>
  with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Realtime Subscriptions & Heartbeat
  RealtimeChannel? _realtimeChannel;
  Timer? _heartbeatTimer;

  // Overview stats
  AdminStatsModel? _stats;
  bool _isLoadingStats = true;

  // Moderation state
  List<AdminReportModel> _reports = [];
  bool _isLoadingReports = true;
  String _reportStatusFilter = 'pending';

  // Stories CMS state
  List<StoryModel> _stories = [];
  bool _isLoadingStories = true;
  String _storyStatusFilter = 'all';
  final TextEditingController _storySearchController = TextEditingController();

  // Categories state
  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = true;

  // Authors state
  List<AdminAuthorModel> _authors = [];
  bool _isLoadingAuthors = true;
  final TextEditingController _authorSearchController = TextEditingController();

  // Audit Logs state
  List<CuratorAuditLogModel> _auditLogs = [];
  bool _isLoadingAuditLogs = true;
  String _auditTypeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      } else {
        if (_tabController.index == 5) {
          _loadAuditLogs(silent: true);
        }
      }
    });
    _loadAllData();
    _setupRealtimeSubscriptions();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    if (_realtimeChannel != null) {
      try {
        Supabase.instance.client.removeChannel(_realtimeChannel!);
      } catch (_) {}
    }
    _tabController.dispose();
    _storySearchController.dispose();
    _authorSearchController.dispose();
    super.dispose();
  }

  void _setupRealtimeSubscriptions() {
    try {
      final client = Supabase.instance.client;
      final channelName = 'admin_cms_realtime_${DateTime.now().millisecondsSinceEpoch}';

      // 1. Supabase Realtime WebSocket Channel (Silent Data Sync)
      _realtimeChannel = client
          .channel(channelName)
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'reports',
            callback: (payload) {
              debugPrint('[AdminCMS] Real-time report change received: ${payload.eventType}');
              _loadReports(silent: true);
              _loadStats(silent: true);
              _loadAuditLogs(silent: true);
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'stories',
            callback: (payload) {
              debugPrint('[AdminCMS] Real-time story change received: ${payload.eventType}');
              _loadReports(silent: true);
              _loadStories(silent: true);
              _loadStats(silent: true);
              _loadAuditLogs(silent: true);
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'curator_audit_logs',
            callback: (payload) {
              debugPrint('[AdminCMS] Real-time audit log change received: ${payload.eventType}');
              _loadAuditLogs(silent: true);
              _loadStats(silent: true);
            },
          )
          .subscribe((status, [error]) {
            debugPrint('[AdminCMS] Real-time channel status: $status, error: $error');
          });

      // 2. Periodic Heartbeat Fallback (Every 15 seconds, silent sync)
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        if (mounted) {
          _loadReports(silent: true);
          _loadStats(silent: true);
          _loadStories(silent: true);
          _loadAuditLogs(silent: true);
        }
      });
    } catch (e) {
      debugPrint('[AdminCMS] Real-time subscription error: $e');
    }
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadStats(),
      _loadReports(),
      _loadStories(),
      _loadCategories(),
      _loadAuthors(),
      _loadAuditLogs(),
    ]);
  }

  Future<void> _loadStats({bool silent = false}) async {
    if (!silent) setState(() => _isLoadingStats = true);
    final repo = ref.read(adminRepositoryProvider);
    final stats = await repo.getStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _loadReports({bool silent = false}) async {
    if (!silent) setState(() => _isLoadingReports = true);
    final repo = ref.read(adminRepositoryProvider);
    final reports = await repo.getReports(statusFilter: _reportStatusFilter);
    if (mounted) {
      setState(() {
        _reports = reports;
        _isLoadingReports = false;
      });
    }
  }

  Future<void> _loadStories({bool silent = false}) async {
    if (!silent) setState(() => _isLoadingStories = true);
    final repo = ref.read(adminRepositoryProvider);
    final stories = await repo.getAllStoriesAdmin(
      statusFilter: _storyStatusFilter,
      searchQuery: _storySearchController.text,
    );
    if (mounted) {
      setState(() {
        _stories = stories;
        _isLoadingStories = false;
      });
    }
  }

  Future<void> _loadCategories({bool silent = false}) async {
    if (!silent) setState(() => _isLoadingCategories = true);
    final repo = ref.read(adminRepositoryProvider);
    final categories = await repo.getCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _loadAuthors({bool silent = false}) async {
    if (!silent) setState(() => _isLoadingAuthors = true);
    final repo = ref.read(adminRepositoryProvider);
    final authors = await repo.getAllAuthorsAdmin(
      searchQuery: _authorSearchController.text,
    );
    if (mounted) {
      setState(() {
        _authors = authors;
        _isLoadingAuthors = false;
      });
    }
  }

  Future<void> _loadAuditLogs({bool silent = false}) async {
    if (!silent) setState(() => _isLoadingAuditLogs = true);
    final repo = ref.read(adminRepositoryProvider);
    final logs = await repo.getAuditLogs(targetTypeFilter: _auditTypeFilter);
    if (mounted) {
      setState(() {
        _auditLogs = logs;
        _isLoadingAuditLogs = false;
      });
    }
  }

  // --- Actions ---

  Future<void> _handleUpdateReportStatus(AdminReportModel report, String newStatus) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      final idx = _reports.indexWhere((r) => r.id == report.id);
      if (idx != -1) {
        _reports[idx] = _reports[idx].copyWith(status: newStatus);
      }
    });

    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.updateReportStatus(report.id, newStatus, storyTitle: report.storyTitle);
      messenger.showSnackBar(
        SnackBar(content: Text('Report marked as $newStatus.')),
      );
      _loadReports();
      _loadStats();
      _loadAuditLogs();
    } catch (e) {
      _loadReports();
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update report: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    }
  }

  Future<void> _handleModerateStory(String storyId, {bool unmoderate = false, String? storyTitle}) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text(
          unmoderate ? 'Unveil Tale' : 'Shield Sanctuary (Moderate Tale)',
          style: AppTypography.storyHeading.copyWith(fontSize: 18),
        ),
        content: Text(
          unmoderate
              ? 'Restore this scroll back to the public reading sanctuary?'
              : 'Hide this scroll from all readers in the sanctuary? It will remain veiled under moderation shelter.',
          style: AppTypography.uiBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: unmoderate ? AppColors.accentPrimary : AppColors.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(unmoderate ? 'Unveil Scroll' : 'Shield & Moderate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final newStatus = unmoderate ? 'published' : 'moderated';
    setState(() {
      for (int i = 0; i < _reports.length; i++) {
        if (_reports[i].storyId == storyId) {
          _reports[i] = _reports[i].copyWith(storyStatus: newStatus);
        }
      }
      if (newStatus == 'moderated' && _storyStatusFilter == 'published') {
        _stories.removeWhere((s) => s.id == storyId);
      }
    });

    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.moderateStory(storyId, unmoderate: unmoderate, storyTitle: storyTitle);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            unmoderate
                ? 'Tale has been unveiled and returned to sanctuary.'
                : 'Tale has been veiled under moderation shelter.',
          ),
        ),
      );
      _loadStories();
      _loadReports();
      _loadStats();
      _loadAuditLogs();
    } catch (e) {
      _loadStories();
      _loadReports();
      messenger.showSnackBar(
        SnackBar(content: Text('Action failed: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    }
  }

  Future<void> _handleSoftDeleteStory(String storyId, String title) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text('Move Scroll to Trash?', style: AppTypography.storyHeading.copyWith(fontSize: 18, color: AppColors.error)),
        content: Text(
          'Move "$title" to trash? It will be safely retained for 14 days and can be restored anytime before it is permanently purged.',
          style: AppTypography.uiBody,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Move to Trash (14d)'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.softDeleteStory(storyId, storyTitle: title);
      messenger.showSnackBar(
        const SnackBar(content: Text('Scroll moved to trash (safely retained for 14 days).')),
      );
      _loadStories(silent: true);
      _loadReports(silent: true);
      _loadStats(silent: true);
      _loadAuditLogs(silent: true);
      ref.invalidate(feedStoriesProvider);
      ref.invalidate(myPublishedStoriesProvider);
      ref.invalidate(myDraftStoriesProvider);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to delete scroll: $e')),
      );
    }
  }

  Future<void> _handleRestoreStory(String storyId, String title) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text('Restore Scroll to Sanctuary?', style: AppTypography.storyHeading.copyWith(fontSize: 18, color: AppColors.accentPrimary)),
        content: Text(
          'Restore "$title" back into the reading sanctuary? It will become visible again to readers.',
          style: AppTypography.uiBody,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPrimary),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restore Scroll'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.restoreStory(storyId, storyTitle: title);
      messenger.showSnackBar(
        SnackBar(content: Text('Scroll "$title" restored to sanctuary successfully.')),
      );
      _loadStories(silent: true);
      _loadReports(silent: true);
      _loadStats(silent: true);
      _loadAuditLogs(silent: true);
      ref.invalidate(feedStoriesProvider);
      ref.invalidate(myPublishedStoriesProvider);
      ref.invalidate(myDraftStoriesProvider);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to restore scroll: $e')),
      );
    }
  }

  Future<void> _handlePermanentDeleteStory(String storyId, String title) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text('Permanently Purge Scroll?', style: AppTypography.storyHeading.copyWith(fontSize: 18, color: AppColors.error)),
        content: Text(
          'Permanently erase "$title" immediately? This bypasses the 14-day retention and cannot be undone.',
          style: AppTypography.uiBody,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Purge Permanently'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.permanentlyDeleteStory(storyId, storyTitle: title);
      messenger.showSnackBar(
        SnackBar(content: Text('Scroll "$title" permanently purged from database.')),
      );
      _loadStories(silent: true);
      _loadReports(silent: true);
      _loadStats(silent: true);
      _loadAuditLogs(silent: true);
      ref.invalidate(feedStoriesProvider);
      ref.invalidate(myPublishedStoriesProvider);
      ref.invalidate(myDraftStoriesProvider);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to purge scroll: $e')),
      );
    }
  }

  Future<void> _handleAdminDeleteReportedStory(AdminReportModel report) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text(
          'Move Reported Tale to Trash?',
          style: AppTypography.storyHeading.copyWith(fontSize: 18, color: AppColors.error),
        ),
        content: Text(
          'Move "${report.storyTitle}" by ${report.storyAuthor ?? "author"} to trash? It will be removed from the sanctuary, safely kept for 14 days (restorable), and this report will be marked as reviewed.',
          style: AppTypography.uiBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Move to Trash (14d)'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.softDeleteStory(report.storyId, storyTitle: report.storyTitle);

      // Selesaikan laporan jika masih berstatus pending
      if (report.status == 'pending') {
        await repo.updateReportStatus(report.id, 'reviewed', storyTitle: report.storyTitle);
      }

      messenger.showSnackBar(
        SnackBar(content: Text('Story "${report.storyTitle}" moved to 14-day retention trash.')),
      );

      _loadStories(silent: true);
      _loadReports(silent: true);
      _loadStats(silent: true);
      _loadAuditLogs(silent: true);
      ref.invalidate(feedStoriesProvider);
      ref.invalidate(myPublishedStoriesProvider);
      ref.invalidate(myDraftStoriesProvider);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to delete story: $e')),
      );
    }
  }

  Future<void> _handleUpdateUserRole(AdminAuthorModel author, String newRole) async {
    final messenger = ScaffoldMessenger.of(context);
    final isPromotion = newRole == 'curator';
    final actionLabel = isPromotion ? 'Appoint as Curator' : 'Demote to Writer';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text(actionLabel, style: AppTypography.storyHeading.copyWith(fontSize: 18)),
        content: Text(
          isPromotion
              ? 'Grant Curator privileges to "${author.penName}"? They will gain authority to review reports, shelter stories, and manage realms.'
              : 'Revoke Curator privileges from "${author.penName}"? They will return to standard reader/writer status.',
          style: AppTypography.uiBody,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isPromotion ? AppColors.accentPrimary : AppColors.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isPromotion ? 'Confirm Appointment' : 'Revoke Role'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Optimistic UI update
    setState(() {
      final idx = _authors.indexWhere((a) => a.id == author.id);
      if (idx != -1) {
        _authors[idx] = _authors[idx].copyWith(role: newRole);
      }
    });

    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.updateAuthorRole(
        authorId: author.id,
        newRole: newRole,
        authorPenName: author.penName,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Role for "${author.penName}" updated to $newRole.')),
      );
      _loadAuthors();
      _loadStats();
      _loadAuditLogs();
    } catch (e) {
      _loadAuthors();
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update role: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    }
  }

  void _showForgeOrEditCategoryDialog({CategoryModel? existingCategory}) {
    final nameCtrl = TextEditingController(text: existingCategory?.name ?? '');
    final descCtrl = TextEditingController(text: existingCategory?.description ?? '');
    final isEditing = existingCategory != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text(
          isEditing ? 'Refine Realm' : 'Forge New Realm',
          style: AppTypography.storyHeading.copyWith(fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Realm / Category Name', style: AppTypography.uiHeadline.copyWith(fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'e.g. Philosophy, Nostalgia, Whispers',
                ),
              ),
              const SizedBox(height: 14),
              Text('Description (Optional)', style: AppTypography.uiHeadline.copyWith(fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'A brief poetic essence of this realm...',
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPrimary),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.of(ctx).pop();
              final messenger = ScaffoldMessenger.of(context);
              final repo = ref.read(adminRepositoryProvider);
              try {
                if (isEditing) {
                  await repo.updateCategory(
                    id: existingCategory.id,
                    name: name,
                    description: descCtrl.text.trim(),
                  );
                  messenger.showSnackBar(
                    SnackBar(content: Text('Realm "$name" updated successfully.')),
                  );
                } else {
                  await repo.createCategory(
                    name: name,
                    description: descCtrl.text.trim(),
                  );
                  messenger.showSnackBar(
                    SnackBar(content: Text('Realm "$name" forged into existence.')),
                  );
                }
                _loadCategories();
                _loadStats();
                _loadAuditLogs();
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text(isEditing ? 'Save Changes' : 'Forge Realm'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteCategory(CategoryModel category) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text('Dissolve Realm', style: AppTypography.storyHeading.copyWith(fontSize: 18, color: AppColors.error)),
        content: Text(
          'Are you sure you wish to dissolve the realm "${category.name}"? Stories in this realm will need reclassification.',
          style: AppTypography.uiBody,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Dissolve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.deleteCategory(category.id, categoryName: category.name);
      messenger.showSnackBar(
        SnackBar(content: Text('Realm "${category.name}" dissolved.')),
      );
      _loadCategories();
      _loadStats();
      _loadAuditLogs();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to delete realm: $e')),
      );
    }
  }

  void _showStoryContentPreview(String title, String? content, String author) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 36,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTypography.storyHeading.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                'Penned by $author',
                style: AppTypography.captionMeta.copyWith(color: AppColors.accentPrimary),
              ),
              const Divider(height: 24),
              SelectableText(
                content ?? 'No content preview available.',
                style: AppTypography.storyBody.copyWith(fontSize: 15, height: 1.7),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
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
        title: Text("Curator's Chamber", style: AppTypography.pageHeader),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            tooltip: 'Refresh All Chambers',
            onPressed: _loadAllData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.accentPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accentPrimary,
          indicatorWeight: 2.5,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(
              child: Row(
                children: [
                  Icon(Icons.dashboard_outlined, size: 16),
                  SizedBox(width: 6),
                  Text('Pulse'),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  Icon(Icons.gavel_outlined, size: 16),
                  SizedBox(width: 6),
                  Text('Moderation'),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  Icon(Icons.auto_stories_outlined, size: 16),
                  SizedBox(width: 6),
                  Text('Scrolls'),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  Icon(Icons.category_outlined, size: 16),
                  SizedBox(width: 6),
                  Text('Realms'),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  Icon(Icons.people_outline, size: 16),
                  SizedBox(width: 6),
                  Text('Scribes'),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  Icon(Icons.history_edu_outlined, size: 16),
                  SizedBox(width: 6),
                  Text('Audit Logs'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPulseTab(),
          _buildModerationTab(),
          _buildScrollsTab(),
          _buildRealmsTab(),
          _buildScribesTab(),
          _buildAuditLogsTab(),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: SANCTUARY PULSE (DASHBOARD)
  // ==========================================
  Widget _buildPulseTab() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = _stats ?? const AdminStatsModel();

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: AppColors.accentPrimary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Sanctuary Health Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: stats.pendingReports > 0
                        ? AppColors.error.withValues(alpha: 0.12)
                        : AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    stats.pendingReports > 0
                        ? Icons.shield_outlined
                        : Icons.check_circle_outline,
                    color: stats.pendingReports > 0
                        ? AppColors.error
                        : AppColors.success,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stats.pendingReports > 0
                            ? '${stats.pendingReports} Whispers Await Moderation'
                            : 'Sanctuary is Sheltered & Serene',
                        style: AppTypography.storyHeading.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stats.pendingReports > 0
                            ? 'Curators are invited to review reported scrolls for community sanctity.'
                            : 'All scrolls comply with peace and editorial harmony.',
                        style: AppTypography.uiBody.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Platform Metrics Grid
          Text(
            'Sanctuary Metrics',
            style: AppTypography.storyHeading.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              _buildMetricCard(
                title: 'Total Scrolls',
                value: '${stats.totalStories}',
                subtitle: '${stats.publishedStories} public • ${stats.draftStories} drafts',
                icon: Icons.menu_book_outlined,
                accentColor: AppColors.accentPrimary,
                onTap: () => _tabController.animateTo(2),
              ),
              _buildMetricCard(
                title: 'Veiled Scrolls',
                value: '${stats.moderatedStories}',
                subtitle: 'Held under moderation',
                icon: Icons.visibility_off_outlined,
                accentColor: AppColors.accentSubtle,
                onTap: () {
                  setState(() => _storyStatusFilter = 'moderated');
                  _loadStories();
                  _tabController.animateTo(2);
                },
              ),
              _buildMetricCard(
                title: 'Flagged Reports',
                value: '${stats.pendingReports}',
                subtitle: '${stats.totalReports} all time filed',
                icon: Icons.flag_outlined,
                accentColor: AppColors.error,
                onTap: () => _tabController.animateTo(1),
              ),
              _buildMetricCard(
                title: 'Active Curators',
                value: '${stats.totalCurators}',
                subtitle: 'Guardians of sanctuary',
                icon: Icons.shield_outlined,
                accentColor: AppColors.accentPrimary,
                onTap: () => _tabController.animateTo(4),
              ),
              _buildMetricCard(
                title: 'Registered Scribes',
                value: '${stats.totalAuthors}',
                subtitle: 'Voices in sanctuary',
                icon: Icons.people_outline,
                accentColor: AppColors.success,
                onTap: () => _tabController.animateTo(4),
              ),
              _buildMetricCard(
                title: 'Realms of Thought',
                value: '${stats.totalCategories}',
                subtitle: 'Story categories',
                icon: Icons.category_outlined,
                accentColor: AppColors.accentPrimary,
                onTap: () => _tabController.animateTo(3),
              ),
              _buildMetricCard(
                title: 'Trash / Retained',
                value: '${stats.deletedStories}',
                subtitle: '14-day recovery window',
                icon: Icons.delete_outline,
                accentColor: AppColors.error,
                onTap: () {
                  setState(() => _storyStatusFilter = 'deleted');
                  _loadStories();
                  _tabController.animateTo(2);
                },
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Quick Operations
          Text(
            'Curator Operations',
            style: AppTypography.storyHeading.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 12),
          _buildQuickActionTile(
            title: 'Audit Moderation Queue',
            subtitle: 'Inspect tales flagged for violations',
            icon: Icons.shield_outlined,
            onTap: () => _tabController.animateTo(1),
          ),
          _buildQuickActionTile(
            title: 'Audit Chronicles & Logs',
            subtitle: 'Review actions performed by curators',
            icon: Icons.history_edu_outlined,
            onTap: () => _tabController.animateTo(5),
          ),
          _buildQuickActionTile(
            title: 'Forge New Realm',
            subtitle: 'Create a new topic or category for writers',
            icon: Icons.add_circle_outline,
            onTap: () => _showForgeOrEditCategoryDialog(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.uiHeadline.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(icon, size: 18, color: accentColor),
              ],
            ),
            Text(
              value,
              style: AppTypography.displayTitle.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: AppTypography.captionMeta.copyWith(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.accentPrimary, size: 20),
          ),
          title: Text(title, style: AppTypography.uiHeadline.copyWith(fontSize: 14)),
          subtitle: Text(subtitle, style: AppTypography.captionMeta),
          trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
          onTap: onTap,
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: MODERATION CHAMBER
  // ==========================================
  Widget _buildModerationTab() {
    return Column(
      children: [
        // Filter Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: AppColors.surfaceLight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Pending', 'pending', _reportStatusFilter, (v) {
                  setState(() => _reportStatusFilter = v);
                  _loadReports();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Reviewed', 'reviewed', _reportStatusFilter, (v) {
                  setState(() => _reportStatusFilter = v);
                  _loadReports();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Dismissed', 'dismissed', _reportStatusFilter, (v) {
                  setState(() => _reportStatusFilter = v);
                  _loadReports();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('All Reports', 'all', _reportStatusFilter, (v) {
                  setState(() => _reportStatusFilter = v);
                  _loadReports();
                }),
              ],
            ),
          ),
        ),
        const Divider(height: 1),

        // Reports List
        Expanded(
          child: _isLoadingReports
              ? const Center(child: CircularProgressIndicator())
              : _reports.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.done_all, size: 48, color: AppColors.success),
                          const SizedBox(height: 12),
                          Text(
                            'No reports in this chamber',
                            style: AppTypography.storyHeading.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'The sanctuary remains undisturbed.',
                            style: AppTypography.uiBody.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadReports,
                      color: AppColors.accentPrimary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reports.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final report = _reports[index];
                          return _buildReportCard(report);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildReportCard(AdminReportModel report) {
    Color reasonColor;
    String reasonLabel;
    switch (report.reason.toLowerCase()) {
      case 'spam':
        reasonColor = AppColors.accentSubtle;
        reasonLabel = 'Spam & Solicitation';
      case 'harassment':
        reasonColor = AppColors.error;
        reasonLabel = 'Harassment';
      case 'hate_speech':
        reasonColor = Colors.purple.shade700;
        reasonLabel = 'Hate Speech';
      case 'explicit_content':
      case 'explicit':
        reasonColor = Colors.red.shade900;
        reasonLabel = 'Explicit Content';
      default:
        reasonColor = AppColors.textSecondary;
        reasonLabel = 'Rule Violation';
    }

    final isStoryModerated = report.storyStatus == 'moderated';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: report.status == 'pending' ? AppColors.error.withValues(alpha: 0.3) : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: reasonColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reasonLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: reasonColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: report.status == 'pending'
                      ? AppColors.error.withValues(alpha: 0.1)
                      : (report.status == 'reviewed' ? AppColors.success.withValues(alpha: 0.1) : AppColors.surfaceWarm),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  report.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: report.status == 'pending'
                        ? AppColors.error
                        : (report.status == 'reviewed' ? AppColors.success : AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.storyTitle,
            style: AppTypography.storyHeading.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(
            'Author: ${report.storyAuthor ?? "Unknown"} • Status: ${report.storyStatus ?? "published"}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.captionMeta.copyWith(color: AppColors.textSecondary),
          ),
          if (report.details != null && report.details!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '“${report.details}”',
                style: AppTypography.uiBody.copyWith(
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Structured Action Deck (Responsive to prevent RenderFlex overflow)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tier 1: Inspection & Triage (Responsive Wrap)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      side: const BorderSide(color: AppColors.borderLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.auto_stories_outlined, size: 14, color: AppColors.textPrimary),
                    label: const Text('Read Tale', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                    onPressed: () {
                      _showStoryContentPreview(
                        report.storyTitle,
                        report.storyContent,
                        report.storyAuthor ?? 'Veiled Author',
                      );
                    },
                  ),
                  if (report.status == 'pending') ...[
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentPrimary.withValues(alpha: 0.12),
                        foregroundColor: AppColors.accentPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 14),
                      label: const Text('Mark Reviewed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      onPressed: () => _handleUpdateReportStatus(report, 'reviewed'),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.close_rounded, size: 14),
                      label: const Text('Dismiss', style: TextStyle(fontSize: 12)),
                      onPressed: () => _handleUpdateReportStatus(report, 'dismissed'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // Tier 2: Moderation & Admin Direct Story Deletion
              Row(
                children: [
                  // Shield / Unveil Tale
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isStoryModerated ? AppColors.success : AppColors.burntSienna,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: Icon(
                        isStoryModerated ? Icons.lock_open_outlined : Icons.shield_outlined,
                        size: 15,
                      ),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isStoryModerated ? 'Unveil Tale' : 'Shield & Moderate',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      onPressed: () => _handleModerateStory(
                        report.storyId,
                        unmoderate: isStoryModerated,
                        storyTitle: report.storyTitle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Admin Direct Story Deletion
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 15),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Delete Story',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      onPressed: () => _handleAdminDeleteReportedStory(report),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: SCROLLS CATALOGUE (STORIES CMS)
  // ==========================================
  Widget _buildScrollsTab() {
    return Column(
      children: [
        // Search & Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surfaceLight,
          child: Column(
            children: [
              TextField(
                controller: _storySearchController,
                decoration: InputDecoration(
                  hintText: 'Search scrolls by title...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _storySearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _storySearchController.clear();
                            _loadStories();
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _loadStories(),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All Scrolls', 'all', _storyStatusFilter, (v) {
                      setState(() => _storyStatusFilter = v);
                      _loadStories();
                    }),
                    const SizedBox(width: 8),
                    _buildFilterChip('Published', 'published', _storyStatusFilter, (v) {
                      setState(() => _storyStatusFilter = v);
                      _loadStories();
                    }),
                    const SizedBox(width: 8),
                    _buildFilterChip('Moderated', 'moderated', _storyStatusFilter, (v) {
                      setState(() => _storyStatusFilter = v);
                      _loadStories();
                    }),
                    const SizedBox(width: 8),
                    _buildFilterChip('Drafts', 'draft', _storyStatusFilter, (v) {
                      setState(() => _storyStatusFilter = v);
                      _loadStories();
                    }),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Trash / Retained (14d)${(_stats?.deletedStories ?? 0) > 0 ? " • ${_stats!.deletedStories}" : ""}',
                      'deleted',
                      _storyStatusFilter,
                      (v) {
                        setState(() => _storyStatusFilter = v);
                        _loadStories();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Stories List
        Expanded(
          child: _isLoadingStories
              ? const Center(child: CircularProgressIndicator())
              : _stories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.menu_book_outlined, size: 48, color: AppColors.textTertiary),
                          const SizedBox(height: 12),
                          Text('No scrolls found', style: AppTypography.storyHeading.copyWith(fontSize: 16)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadStories,
                      color: AppColors.accentPrimary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _stories.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final story = _stories[index];
                          return _buildStoryCatalogueCard(story);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildStoryCatalogueCard(StoryModel story) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  story.categoryName,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 8),
              if (story.isAnonymous)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 10, color: AppColors.textSecondary),
                      SizedBox(width: 3),
                      Text('Anonymous', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              if (story.isDeleted) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.delete_outline, size: 11, color: AppColors.error),
                      const SizedBox(width: 3),
                      Text(
                        'Trash (${story.daysUntilPermanentDeletion}d left)',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, size: 20),
                onSelected: (val) {
                  if (val == 'preview') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => StoryReaderScreen(story: story)),
                    );
                  } else if (val == 'restore') {
                    _handleRestoreStory(story.id, story.title);
                  } else if (val == 'permanent_delete') {
                    _handlePermanentDeleteStory(story.id, story.title);
                  } else if (val == 'moderate') {
                    _handleModerateStory(story.id, unmoderate: false, storyTitle: story.title);
                  } else if (val == 'unveil') {
                    _handleModerateStory(story.id, unmoderate: true, storyTitle: story.title);
                  } else if (val == 'delete') {
                    _handleSoftDeleteStory(story.id, story.title);
                  }
                },
                itemBuilder: (ctx) {
                  if (story.isDeleted) {
                    return [
                      const PopupMenuItem(
                        value: 'preview',
                        child: Row(
                          children: [
                            Icon(Icons.auto_stories_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Read Tale'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'restore',
                        child: Row(
                          children: [
                            Icon(Icons.restore_outlined, size: 18, color: AppColors.success),
                            SizedBox(width: 8),
                            Text('Restore to Sanctuary', style: TextStyle(color: AppColors.success)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'permanent_delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_forever_outlined, size: 18, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Permanently Delete', style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ];
                  }

                  return [
                    const PopupMenuItem(
                      value: 'preview',
                      child: Row(
                        children: [
                          Icon(Icons.auto_stories_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Read Tale'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'moderate',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_off_outlined, size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Shield / Moderate', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'unveil',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 18, color: AppColors.success),
                          SizedBox(width: 8),
                          Text('Unveil (Restore)'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Move to Trash (14d)', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            story.title,
            style: AppTypography.storyHeading.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'By ${story.isAnonymous ? "Anonymous Scribe" : story.authorName}',
            style: AppTypography.captionMeta.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.remove_red_eye_outlined, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text('${story.viewsCount}', style: AppTypography.captionMeta),
              const SizedBox(width: 14),
              const Icon(Icons.favorite_border, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text('${story.likesCount}', style: AppTypography.captionMeta),
              const Spacer(),
              Text(
                story.readingTime,
                style: AppTypography.captionMeta.copyWith(color: AppColors.accentPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 4: REALMS OF THOUGHT (CATEGORIES CMS)
  // ==========================================
  Widget _buildRealmsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.surfaceLight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_categories.length} Realms Defined',
                style: AppTypography.uiHeadline.copyWith(fontSize: 14),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Forge Realm', style: TextStyle(fontSize: 13)),
                onPressed: () => _showForgeOrEditCategoryDialog(),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _isLoadingCategories
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadCategories,
                  color: AppColors.accentPrimary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceWarm,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.folder_open_outlined, color: AppColors.accentPrimary, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.name,
                                    style: AppTypography.storyHeading.copyWith(fontSize: 16),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Slug: #${category.slug}',
                                    style: AppTypography.captionMeta.copyWith(
                                      color: AppColors.accentPrimary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (category.description != null && category.description!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      category.description!,
                                      style: AppTypography.captionMeta.copyWith(color: AppColors.textSecondary),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                              tooltip: 'Refine Realm',
                              onPressed: () => _showForgeOrEditCategoryDialog(existingCategory: category),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                              tooltip: 'Dissolve Realm',
                              onPressed: () => _handleDeleteCategory(category),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 5: SCRIBES & CURATORS DIRECTORY
  // ==========================================
  Widget _buildScribesTab() {
    final currentProfile = ref.watch(currentUserProfileProvider).value;
    final isSuperAdmin = currentProfile?.role == 'admin';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surfaceLight,
          child: TextField(
            controller: _authorSearchController,
            decoration: InputDecoration(
              hintText: 'Search scribes by pen name...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _authorSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _authorSearchController.clear();
                        _loadAuthors();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onSubmitted: (_) => _loadAuthors(),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _isLoadingAuthors
              ? const Center(child: CircularProgressIndicator())
              : _authors.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_search_outlined, size: 48, color: AppColors.textTertiary),
                          const SizedBox(height: 12),
                          Text('No scribes found', style: AppTypography.storyHeading.copyWith(fontSize: 16)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAuthors,
                      color: AppColors.accentPrimary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _authors.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final author = _authors[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: ListTile(
                                leading: WrittleAvatar(
                                  radius: 22,
                                  avatarUrl: author.avatarUrl,
                                  fallbackInitial: author.penName.isNotEmpty ? author.penName[0] : '?',
                                ),
                                title: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        author.penName,
                                        style: AppTypography.storyHeading.copyWith(fontSize: 15),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (author.isSuperAdmin) ...[
                                      const SizedBox(width: 6),
                                      _buildRoleBadge('ADMIN', AppColors.accentPrimary),
                                    ] else if (author.isCurator) ...[
                                      const SizedBox(width: 6),
                                      _buildRoleBadge('CURATOR', AppColors.success),
                                    ],
                                  ],
                                ),
                                subtitle: Text(
                                  author.bio != null && author.bio!.isNotEmpty
                                      ? author.bio!
                                      : 'A quiet voice in the sanctuary',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.captionMeta,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceWarm,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${author.storiesCount} scrolls',
                                        style: AppTypography.captionMeta.copyWith(fontSize: 11),
                                      ),
                                    ),
                                    if (isSuperAdmin && author.id != currentProfile?.id) ...[
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
                                        onSelected: (val) {
                                          if (val == 'promote') {
                                            _handleUpdateUserRole(author, 'curator');
                                          } else if (val == 'demote') {
                                            _handleUpdateUserRole(author, 'user');
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          if (author.role != 'curator' && !author.isSuperAdmin)
                                            const PopupMenuItem(
                                              value: 'promote',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.shield_outlined, size: 16, color: AppColors.success),
                                                  SizedBox(width: 8),
                                                  Text('Appoint as Curator'),
                                                ],
                                              ),
                                            ),
                                          if (author.isCurator)
                                            const PopupMenuItem(
                                              value: 'demote',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.person_outline, size: 16, color: AppColors.error),
                                                  SizedBox(width: 8),
                                                  Text('Demote to Writer', style: TextStyle(color: AppColors.error)),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ] else ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
                                    ],
                                  ],
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PublicProfileScreen(
                                        authorId: author.id,
                                        initialPenName: author.penName,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ==========================================
  // TAB 6: CHRONICLES & AUDIT LOGS
  // ==========================================
  Widget _buildAuditLogsTab() {
    return Column(
      children: [
        // Filter Chips
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: AppColors.surfaceLight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Actions', 'all', _auditTypeFilter, (v) {
                  setState(() => _auditTypeFilter = v);
                  _loadAuditLogs();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Stories', 'story', _auditTypeFilter, (v) {
                  setState(() => _auditTypeFilter = v);
                  _loadAuditLogs();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Reports', 'report', _auditTypeFilter, (v) {
                  setState(() => _auditTypeFilter = v);
                  _loadAuditLogs();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Realms', 'category', _auditTypeFilter, (v) {
                  setState(() => _auditTypeFilter = v);
                  _loadAuditLogs();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Curators', 'user', _auditTypeFilter, (v) {
                  setState(() => _auditTypeFilter = v);
                  _loadAuditLogs();
                }),
              ],
            ),
          ),
        ),
        const Divider(height: 1),

        // Logs List
        Expanded(
          child: _isLoadingAuditLogs
              ? const Center(child: CircularProgressIndicator())
              : _auditLogs.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadAuditLogs,
                      color: AppColors.accentPrimary,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.history_edu_outlined, size: 48, color: AppColors.textTertiary),
                                const SizedBox(height: 12),
                                Text(
                                  'No audit logs recorded yet',
                                  style: AppTypography.storyHeading.copyWith(fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Curator actions will be chronicled here in real-time.',
                                  style: AppTypography.uiBody.copyWith(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textPrimary,
                                    side: const BorderSide(color: AppColors.borderLight),
                                  ),
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Refresh Logs'),
                                  onPressed: () => _loadAuditLogs(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAuditLogs,
                      color: AppColors.accentPrimary,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _auditLogs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final log = _auditLogs[index];
                          return _buildAuditLogCard(log);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildAuditLogCard(CuratorAuditLogModel log) {
    IconData actionIcon;
    Color actionColor;
    String actionTitle;

    switch (log.action) {
      case 'moderate_story':
        actionIcon = Icons.visibility_off_outlined;
        actionColor = AppColors.error;
        actionTitle = 'Sheltered Story';
      case 'restore_story':
        actionIcon = Icons.visibility_outlined;
        actionColor = AppColors.success;
        actionTitle = 'Restored Story';
      case 'delete_story':
        actionIcon = Icons.delete_outline;
        actionColor = AppColors.error;
        actionTitle = 'Moved to Trash';
      case 'permanent_delete_story':
        actionIcon = Icons.delete_forever_outlined;
        actionColor = AppColors.error;
        actionTitle = 'Permanently Purged';
      case 'review_report':
        actionIcon = Icons.check_circle_outline;
        actionColor = AppColors.success;
        actionTitle = 'Reviewed Report';
      case 'dismiss_report':
        actionIcon = Icons.cancel_outlined;
        actionColor = AppColors.textSecondary;
        actionTitle = 'Dismissed Report';
      case 'create_category':
        actionIcon = Icons.add_circle_outline;
        actionColor = AppColors.accentPrimary;
        actionTitle = 'Forged Realm';
      case 'update_category':
        actionIcon = Icons.edit_outlined;
        actionColor = AppColors.accentSubtle;
        actionTitle = 'Refined Realm';
      case 'delete_category':
        actionIcon = Icons.folder_delete_outlined;
        actionColor = AppColors.error;
        actionTitle = 'Dissolved Realm';
      case 'assign_curator':
        actionIcon = Icons.verified_user_outlined;
        actionColor = AppColors.success;
        actionTitle = 'Appointed Curator';
      case 'demote_curator':
        actionIcon = Icons.person_remove_outlined;
        actionColor = AppColors.error;
        actionTitle = 'Revoked Curator';
      default:
        actionIcon = Icons.info_outline;
        actionColor = AppColors.accentPrimary;
        actionTitle = 'Platform Action';
    }

    final timeStr = _formatTimestamp(log.createdAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: actionColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(actionIcon, size: 18, color: actionColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      actionTitle,
                      style: AppTypography.uiHeadline.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: actionColor,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: AppTypography.captionMeta.copyWith(fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: AppTypography.uiBody.copyWith(fontSize: 13),
                    children: [
                      TextSpan(
                        text: log.curatorName,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const TextSpan(text: ' executed on '),
                      TextSpan(
                        text: log.targetTitle ?? log.targetId ?? 'item',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.accentPrimary),
                      ),
                    ],
                  ),
                ),
                if (log.details != null && log.details!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    log.details!,
                    style: AppTypography.captionMeta.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildFilterChip(String label, String value, String activeValue, ValueChanged<String> onSelected) {
    final isSelected = activeValue == value;
    return InkWell(
      onTap: () => onSelected(value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentPrimary : AppColors.surfaceWarm,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accentPrimary : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
