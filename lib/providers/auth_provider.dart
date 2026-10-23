import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

final currentUserProfileProvider = FutureProvider<UserProfileModel?>((ref) async {
  // Re-run whenever auth state changes
  ref.watch(authStateProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  return await authRepo.getCurrentProfile();
});
