import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/story_model.dart';
import '../models/user_profile_model.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

/// Reactive provider that emits whether a user is currently authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  final session = authState.value?.session;
  if (session != null) return true;
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.isAuthenticated;
});

/// Reactive provider that emits current authenticated user ID, or null if guest.
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  final session = authState.value?.session;
  if (session?.user.id != null) return session!.user.id;
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.currentUser?.id;
});

final currentUserProfileProvider = FutureProvider<UserProfileModel?>((ref) async {
  // Re-run whenever auth user changes
  ref.watch(authStateProvider.select((s) => s.value?.session?.user.id));
  final authRepo = ref.read(authRepositoryProvider);
  return await authRepo.getCurrentProfile();
});

final myPublishedStoriesProvider = FutureProvider<List<StoryModel>>((ref) async {
  ref.watch(authStateProvider.select((s) => s.value?.session?.user.id));
  final authRepo = ref.read(authRepositoryProvider);
  if (!authRepo.isAuthenticated) return [];
  return authRepo.getMyStories(draftsOnly: false);
});

final myDraftStoriesProvider = FutureProvider<List<StoryModel>>((ref) async {
  ref.watch(authStateProvider.select((s) => s.value?.session?.user.id));
  final authRepo = ref.read(authRepositoryProvider);
  if (!authRepo.isAuthenticated) return [];
  return authRepo.getMyStories(draftsOnly: true);
});

/// Fetches user's own soft-deleted stories in the 14-day retention window.
/// Stories deleted by a curator/admin are strictly excluded.
final myTrashStoriesProvider = FutureProvider<List<StoryModel>>((ref) async {
  ref.watch(authStateProvider.select((s) => s.value?.session?.user.id));
  final authRepo = ref.read(authRepositoryProvider);
  if (!authRepo.isAuthenticated) return [];
  return authRepo.getMyTrashStories();
});

final searchAuthorsProvider =
    FutureProvider.family<List<UserProfileModel>, String>((ref, query) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.searchProfiles(query);
});

