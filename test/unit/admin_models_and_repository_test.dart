import 'package:flutter_test/flutter_test.dart';
import 'package:writtle/models/admin_models.dart';
import 'package:writtle/repositories/admin_repository.dart';

void main() {
  group('AdminModels Tests', () {
    test('AdminStatsModel default values and copyWith work properly', () {
      const stats = AdminStatsModel();
      expect(stats.totalStories, 0);
      expect(stats.publishedStories, 0);
      expect(stats.moderatedStories, 0);
      expect(stats.pendingReports, 0);

      final updated = stats.copyWith(
        totalStories: 25,
        publishedStories: 20,
        moderatedStories: 5,
        pendingReports: 3,
        totalAuthors: 12,
        totalCurators: 4,
      );

      expect(updated.totalStories, 25);
      expect(updated.publishedStories, 20);
      expect(updated.moderatedStories, 5);
      expect(updated.pendingReports, 3);
      expect(updated.totalAuthors, 12);
      expect(updated.totalCurators, 4);
    });

    test('AdminReportModel parses correctly from map with joined story', () {
      final map = {
        'id': 'rep-101',
        'story_id': 'story-202',
        'reporter_id': 'user-303',
        'reason': 'spam',
        'details': 'Repetitive advertising text',
        'status': 'pending',
        'created_at': '2026-10-23T12:00:00.000Z',
        'stories': {
          'title': 'Echoes of the Valley',
          'content': 'Once upon a time in a distant realm...',
          'status': 'published',
          'is_anonymous': false,
          'profiles': {
            'pen_name': 'ValleyBard',
          },
        },
      };

      final report = AdminReportModel.fromMap(map);

      expect(report.id, 'rep-101');
      expect(report.storyId, 'story-202');
      expect(report.storyTitle, 'Echoes of the Valley');
      expect(report.storyAuthor, 'ValleyBard');
      expect(report.isStoryAnonymous, false);
      expect(report.reason, 'spam');
      expect(report.details, 'Repetitive advertising text');
      expect(report.status, 'pending');
    });

    test('AdminReportModel conceals author when story is anonymous', () {
      final map = {
        'id': 'rep-102',
        'story_id': 'story-203',
        'reporter_id': 'user-304',
        'reason': 'harassment',
        'status': 'pending',
        'created_at': '2026-10-23T12:00:00.000Z',
        'stories': {
          'title': 'A Secret Tale',
          'is_anonymous': true,
          'profiles': {
            'pen_name': 'HiddenWriter',
          },
        },
      };

      final report = AdminReportModel.fromMap(map);
      expect(report.isStoryAnonymous, true);
      expect(report.storyAuthor, 'Anonymous Scribe');
    });

    test('AdminAuthorModel parses pen name, role, bio, and storiesCount', () {
      final map = {
        'id': 'author-01',
        'pen_name': 'SanctuaryPoet',
        'bio': 'Lover of verses and silence.',
        'avatar_url': 'https://example.com/avatar.png',
        'role': 'curator',
        'created_at': '2026-01-01T00:00:00.000Z',
      };

      final author = AdminAuthorModel.fromMap(map, storiesCount: 7);
      expect(author.id, 'author-01');
      expect(author.penName, 'SanctuaryPoet');
      expect(author.bio, 'Lover of verses and silence.');
      expect(author.role, 'curator');
      expect(author.isAdmin, isTrue);
      expect(author.isCurator, isTrue);
      expect(author.isSuperAdmin, isFalse);
      expect(author.storiesCount, 7);
    });

    test('CuratorAuditLogModel parses correctly from map', () {
      final map = {
        'id': 'log-101',
        'curator_id': 'curator-01',
        'curator_name': 'AzzamTes',
        'action': 'moderate_story',
        'target_type': 'story',
        'target_id': 'story-55',
        'target_title': 'Echoes of the Night',
        'details': 'Scroll sheltered under moderation',
        'created_at': '2026-10-23T15:00:00.000Z',
      };

      final log = CuratorAuditLogModel.fromMap(map);
      expect(log.id, 'log-101');
      expect(log.curatorName, 'AzzamTes');
      expect(log.action, 'moderate_story');
      expect(log.targetType, 'story');
      expect(log.targetTitle, 'Echoes of the Night');
    });
  });

  group('AdminRepository in-memory operations', () {
    late AdminRepository repo;

    setUp(() {
      repo = AdminRepository(); // without client, operates in offline/safe mode
    });

    test('getStats returns initial metrics without throwing', () async {
      final stats = await repo.getStats();
      expect(stats.totalStories, greaterThanOrEqualTo(0));
      expect(stats.totalCategories, greaterThanOrEqualTo(0));
      expect(stats.totalCurators, greaterThanOrEqualTo(0));
    });

    test('Category management: create, update, delete', () async {
      final newCat = await repo.createCategory(
        name: 'Solitude & Stars',
        description: 'Tails of night and contemplation',
      );

      expect(newCat.name, 'Solitude & Stars');
      expect(newCat.slug, 'solitude-stars');

      final cats = await repo.getCategories();
      expect(cats.any((c) => c.name == 'Solitude & Stars'), isTrue);

      await repo.updateCategory(
        id: newCat.id,
        name: 'Celestial Musings',
        description: 'Updated description',
      );

      final updatedCats = await repo.getCategories();
      final updatedCat = updatedCats.firstWhere((c) => c.id == newCat.id);
      expect(updatedCat.name, 'Celestial Musings');
      expect(updatedCat.description, 'Updated description');

      await repo.deleteCategory(newCat.id);
      final remainingCats = await repo.getCategories();
      expect(remainingCats.any((c) => c.id == newCat.id), isFalse);
    });

    test('Reports queue seeded fallback and status transitions', () async {
      final initialReports = await repo.getReports(statusFilter: 'all');
      expect(initialReports.isNotEmpty, isTrue);

      final first = initialReports.first;
      expect(first.status, 'pending');

      await repo.updateReportStatus(first.id, 'reviewed');

      final reviewedReports = await repo.getReports(statusFilter: 'reviewed');
      expect(reviewedReports.any((r) => r.id == first.id), isTrue);
    });

    test('Curator role update automatically creates audit log and updates local cache', () async {
      final initialAuthors = await repo.getAllAuthorsAdmin();
      expect(initialAuthors.isNotEmpty, isTrue);

      final targetAuthor = initialAuthors.first;

      await repo.updateAuthorRole(
        authorId: targetAuthor.id,
        newRole: 'curator',
        authorPenName: targetAuthor.penName,
      );

      final updatedAuthors = await repo.getAllAuthorsAdmin();
      final updatedTarget = updatedAuthors.firstWhere((a) => a.id == targetAuthor.id);
      expect(updatedTarget.role, 'curator');

      final logs = await repo.getAuditLogs();
      expect(logs.isNotEmpty, isTrue);

      final roleLog = logs.firstWhere((l) => l.targetId == targetAuthor.id);
      expect(roleLog.action, 'assign_curator');
      expect(roleLog.targetTitle, targetAuthor.penName);
    });
  });
}
