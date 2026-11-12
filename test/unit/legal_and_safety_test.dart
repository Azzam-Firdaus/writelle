import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:writtle/models/story_model.dart';
import 'package:writtle/repositories/block_repository.dart';
import 'package:writtle/screens/legal/privacy_policy_screen.dart';
import 'package:writtle/screens/legal/terms_of_service_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Legal Screens & Compliance Constants Tests', () {
    test('PrivacyPolicyScreen exposes valid version and last updated date', () {
      expect(PrivacyPolicyScreen.policyVersion, equals('1.0.0'));
      expect(PrivacyPolicyScreen.lastUpdated, isNotEmpty);
    });

    test('TermsOfServiceScreen exposes valid version and last updated date', () {
      expect(TermsOfServiceScreen.termsVersion, equals('1.0.0'));
      expect(TermsOfServiceScreen.lastUpdated, isNotEmpty);
    });
  });

  group('BlockRepository UGC Compliance Tests', () {
    late BlockRepository repo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repo = BlockRepository();
    });

    test('Author blocking and unblocking operations work properly', () async {
      const authorId = 'abusive-author-456';

      // Initial state
      expect(await repo.isAuthorBlocked(authorId), isFalse);

      // Block author
      await repo.blockAuthor(authorId);
      expect(await repo.isAuthorBlocked(authorId), isTrue);

      // Verify list contains blocked author
      final blockedList = await repo.getBlockedAuthorIds();
      expect(blockedList.contains(authorId), isTrue);

      // Unblock author
      await repo.unblockAuthor(authorId);
      expect(await repo.isAuthorBlocked(authorId), isFalse);
    });
  });

  group('14-Day Retention & Curator Deletion Isolation Tests', () {
    test('StoryModel accurately tracks deletedByCurator and retention days', () {
      final now = DateTime.now();
      final deletedTenDaysAgo = now.subtract(const Duration(days: 10));

      final curatorDeletedStory = StoryModel.fromMap({
        'id': 'quarantined-story-1',
        'category_id': 'cat-1',
        'title': 'Violating Content',
        'content': 'Some content that breached community ethos guidelines',
        'is_anonymous': true,
        'deleted_at': deletedTenDaysAgo.toIso8601String(),
        'deleted_by_curator': true,
        'created_at': now.subtract(const Duration(days: 15)).toIso8601String(),
      });

      expect(curatorDeletedStory.isDeleted, isTrue);
      expect(curatorDeletedStory.deletedByCurator, isTrue);
      // 14 - 10 = ~4 days left
      expect(curatorDeletedStory.daysUntilPermanentDeletion, inInclusiveRange(3, 4));
      expect(curatorDeletedStory.isPermanentDeletionExpired, isFalse);

      final authorDeletedStory = StoryModel.fromMap({
        'id': 'self-deleted-story-2',
        'category_id': 'cat-1',
        'title': 'My Regretful Draft',
        'content': 'I wrote this but decided to move it to my trash',
        'is_anonymous': false,
        'deleted_at': now.subtract(const Duration(days: 2)).toIso8601String(),
        'deleted_by_curator': false,
        'created_at': now.subtract(const Duration(days: 5)).toIso8601String(),
      });

      expect(authorDeletedStory.isDeleted, isTrue);
      expect(authorDeletedStory.deletedByCurator, isFalse);
      expect(authorDeletedStory.daysUntilPermanentDeletion, inInclusiveRange(11, 12));
    });
  });
}
