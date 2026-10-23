import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../models/story_model.dart';
import '../repositories/story_repository.dart';

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

/// Fetches published stories for the active category filter.
final feedStoriesProvider = FutureProvider<List<StoryModel>>((ref) async {
  final repo = ref.watch(storyRepositoryProvider);
  final categorySlug = ref.watch(selectedCategoryProvider);
  return await repo.getPublicStories(categorySlug: categorySlug);
});

/// Fetches user's bookmarked stories.
final bookmarkedStoriesProvider = FutureProvider<List<StoryModel>>((ref) async {
  final repo = ref.watch(storyRepositoryProvider);
  return await repo.getBookmarkedStories();
});
