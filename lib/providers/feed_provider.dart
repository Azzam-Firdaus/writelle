import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../models/story_model.dart';
import '../repositories/block_repository.dart';
import '../repositories/story_repository.dart';
import 'auth_provider.dart';

final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return StoryRepository();
});

/// Fetches list of categories.
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repo = ref.watch(storyRepositoryProvider);
  return await repo.getCategories();
});

/// Category filter state notifier.
class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setCategory(String slug) {
    state = slug;
  }
}

/// Currently selected category filter slug ('all' means no filter).
final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, String>(SelectedCategoryNotifier.new);

/// Fetches published stories for the active category filter, filtering out blocked authors.
final feedStoriesProvider = FutureProvider<List<StoryModel>>((ref) async {
  ref.watch(authStateProvider.select((s) => s.value?.session?.user.id));
  final repo = ref.watch(storyRepositoryProvider);
  final categorySlug = ref.watch(selectedCategoryProvider);
  final blockedAuthorsAsync = ref.watch(blockedAuthorsProvider);
  final blockedAuthorIds = blockedAuthorsAsync.value ?? <String>{};

  final stories = await repo.getPublicStories(categorySlug: categorySlug);
  if (blockedAuthorIds.isEmpty) return stories;

  return stories.where((story) => !blockedAuthorIds.contains(story.userId)).toList();
});

/// Fetches user's bookmarked stories.
final bookmarkedStoriesProvider = FutureProvider<List<StoryModel>>((ref) async {
  // Re-run whenever auth user changes
  ref.watch(authStateProvider.select((s) => s.value?.session?.user.id));
  final isAuth = ref.watch(isAuthenticatedProvider);
  if (!isAuth) return [];

  final repo = ref.watch(storyRepositoryProvider);
  return await repo.getBookmarkedStories();
});
