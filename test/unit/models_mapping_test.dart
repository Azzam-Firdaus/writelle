import 'package:flutter_test/flutter_test.dart';
import 'package:writtle/models/category_model.dart';
import 'package:writtle/models/comment_model.dart';
import 'package:writtle/models/story_model.dart';
import 'package:writtle/models/user_profile_model.dart';

void main() {
  group('TC-003 & TC-004: StoryModel Privacy & Anonymity Tests (FR-014, FR-015, BR-002, BR-003)', () {
    test('TC-003: Pure Anonymity Mode conceals author pen name and avatar', () {
      final map = {
        'id': 'story-uuid-1',
        'category_id': 'cat-1',
        'category_name': 'Reflections',
        'category_slug': 'reflections',
        'title': 'Whispers in the Dark',
        'content': 'This is an intimate confession about my struggles in university...',
        'is_anonymous': true,
        'author_name': 'Anonymous',
        'author_avatar_url': null,
        'published_at': '2026-10-23T06:00:00Z',
        'created_at': '2026-10-23T06:00:00Z',
        'views_count': 15,
        'likes_count': 5,
        'comments_count': 2,
      };

      final story = StoryModel.fromMap(map);

      expect(story.isAnonymous, isTrue);
      expect(story.authorName, equals('Anonymous'));
      expect(story.authorAvatarUrl, isNull);
    });

    test('TC-004: Pseudonym Mode correctly displays pen name alias', () {
      final map = {
        'id': 'story-uuid-2',
        'category_id': 'cat-2',
        'category_name': 'Life Lessons',
        'category_slug': 'life-lessons',
        'title': 'Lessons from the Midnight Train',
        'content': 'Sitting by the window as the city drifted past taught me...',
        'is_anonymous': false,
        'author_name': 'NightOwl_42',
        'author_avatar_url': 'https://example.com/avatar.jpg',
        'published_at': '2026-10-23T06:30:00Z',
        'created_at': '2026-10-23T06:30:00Z',
        'views_count': 40,
        'likes_count': 12,
        'comments_count': 4,
      };

      final story = StoryModel.fromMap(map);

      expect(story.isAnonymous, isFalse);
      expect(story.authorName, equals('NightOwl_42'));
      expect(story.authorAvatarUrl, equals('https://example.com/avatar.jpg'));
    });
  });

  group('TC-002: Model Serialization & Deserialization Tests', () {
    test('CategoryModel correctly maps fields from Supabase payload', () {
      final map = {
        'id': 'cat-uuid-1',
        'name': 'Reflections',
        'slug': 'reflections',
        'description': 'Introspective thoughts and personal growth',
      };

      final category = CategoryModel.fromMap(map);

      expect(category.id, equals('cat-uuid-1'));
      expect(category.name, equals('Reflections'));
      expect(category.slug, equals('reflections'));
      expect(category.description, equals('Introspective thoughts and personal growth'));
    });

    test('UserProfileModel serialization toMap and fromMap preserves data', () {
      final now = DateTime.now();
      final profile = UserProfileModel(
        id: 'user-uuid-123',
        penName: 'SilentPoet',
        bio: 'Writing between the lines.',
        avatarUrl: null,
        createdAt: now,
        updatedAt: now,
      );

      final map = profile.toMap();
      expect(map['id'], equals('user-uuid-123'));
      expect(map['pen_name'], equals('SilentPoet'));
      expect(map['bio'], equals('Writing between the lines.'));

      final restored = UserProfileModel.fromMap(map);
      expect(restored.id, equals(profile.id));
      expect(restored.penName, equals(profile.penName));
      expect(restored.role, equals('user'));
      expect(restored.isAdmin, isFalse);

      final adminProfile = profile.copyWith(role: 'admin');
      expect(adminProfile.isAdmin, isTrue);
      expect(adminProfile.toMap()['role'], equals('admin'));
    });

    test('CommentModel extracts author pen name from nested profile join', () {
      final map = {
        'id': 'comment-uuid-1',
        'story_id': 'story-uuid-1',
        'user_id': 'user-uuid-888',
        'content': 'Your words resonated deeply with me. Stay strong.',
        'created_at': '2026-10-23T07:00:00Z',
        'profiles': {'pen_name': 'EmpatheticSoul'},
      };

      final comment = CommentModel.fromMap(map);

      expect(comment.id, equals('comment-uuid-1'));
      expect(comment.content, equals('Your words resonated deeply with me. Stay strong.'));
      expect(comment.authorPenName, equals('EmpatheticSoul'));
    });
  });
}
