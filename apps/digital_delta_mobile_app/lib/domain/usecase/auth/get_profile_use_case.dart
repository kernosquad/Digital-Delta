import '../../model/auth/user_model.dart';
import '../../repository/auth_repository.dart';
import '../../util/result.dart';

class GetProfileUseCase {
  final AuthRepository _repository;

  GetProfileUseCase({required AuthRepository repository})
    : _repository = repository;

  Future<Result<UserModel>> call() async {
    return _repository.getProfile();
  }
}
