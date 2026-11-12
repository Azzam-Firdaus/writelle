import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
}
