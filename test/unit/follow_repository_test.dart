import 'package:flutter_test/flutter_test.dart';
import 'package:writtle/repositories/follow_repository.dart';

void main() {
  group('FollowRepository In-Memory & Local Cache Tests', () {
    late FollowRepository repo;

    setUp(() {
      repo = FollowRepository();
    });

    test('Follow, unfollow, and counts update correctly in memory', () async {
      const userA = 'user-aaa-111';
      const authorB = 'author-bbb-222';

      // Initial state
      expect(await repo.isFollowing(followerId: userA, followingId: authorB), isFalse);
      expect(await repo.getFollowersCount(authorB), equals(0));
      expect(await repo.getFollowingCount(userA), equals(0));

      // User A follows Author B
      await repo.follow(followerId: userA, followingId: authorB);
      expect(await repo.isFollowing(followerId: userA, followingId: authorB), isTrue);
      expect(await repo.getFollowersCount(authorB), equals(1));
      expect(await repo.getFollowingCount(userA), equals(1));

      // Followers of Author B should contain User A
      final followers = await repo.getFollowers(authorB);
      expect(followers, isNotEmpty);
      expect(followers.first.id, equals(userA));

      // Following of User A should contain Author B
      final following = await repo.getFollowing(userA);
      expect(following, isNotEmpty);
      expect(following.first.id, equals(authorB));

      // User A unfollows Author B
      await repo.unfollow(followerId: userA, followingId: authorB);
      expect(await repo.isFollowing(followerId: userA, followingId: authorB), isFalse);
      expect(await repo.getFollowersCount(authorB), equals(0));
      expect(await repo.getFollowingCount(userA), equals(0));
      expect(await repo.getFollowers(authorB), isEmpty);
      expect(await repo.getFollowing(userA), isEmpty);
    });

    test('User cannot follow themselves', () async {
      const userA = 'user-self-999';
      await repo.follow(followerId: userA, followingId: userA);
      expect(await repo.isFollowing(followerId: userA, followingId: userA), isFalse);
      expect(await repo.getFollowersCount(userA), equals(0));
    });
  });
}
