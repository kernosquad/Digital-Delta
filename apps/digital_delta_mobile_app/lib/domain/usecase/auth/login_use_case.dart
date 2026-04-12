import '../../model/auth/auth_token_model.dart';
import '../../repository/auth_repository.dart';
import '../../util/result.dart';

class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase({required AuthRepository repository}) : _repository = repository;

  Future<Result<AuthTokenModel>> call({
    required String email,
    required String password,
  }) async {
    return _repository.login(email: email, password: password);
  }
}
