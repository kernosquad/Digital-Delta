import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../di/cache_module.dart';
import '../../../../domain/model/auth/user_model.dart';
import '../../../../domain/usecase/auth/get_profile_use_case.dart';

// Provider that gets the user profile
final userProfileProvider = FutureProvider<UserModel?>((ref) async {
  final useCase = getIt<GetProfileUseCase>();
  final result = await useCase();

  return result.when(success: (user) => user, failure: (_) => null);
});

// Provider that can be manually refreshed
final refreshableUserProfileProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<UserModel?>>(
      (ref) => UserProfileNotifier(),
    );

class UserProfileNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  UserProfileNotifier() : super(const AsyncValue.loading()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = const AsyncValue.loading();

    try {
      final useCase = getIt<GetProfileUseCase>();
      final result = await useCase();

      state = result.when(
        success: (user) {
          print('✅ Profile loaded successfully: ${user.email}');
          return AsyncValue.data(user);
        },
        failure: (failure) {
          print('❌ Profile load failed: ${failure.message}');
          return AsyncValue.error(failure.message, StackTrace.current);
        },
      );
    } catch (e, stack) {
      print('❌ Profile load exception: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await loadProfile();
  }
}
