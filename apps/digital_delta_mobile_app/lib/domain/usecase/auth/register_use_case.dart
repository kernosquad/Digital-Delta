import '../../model/auth/auth_token_model.dart';
import '../../repository/auth_repository.dart';
import '../../util/result.dart';

class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase({required AuthRepository repository})
    : _repository = repository;

  Future<Result<AuthTokenModel>> call({
    required String name,
    required String email,
    required String password,
  }) async {
    return _repository.register(name: name, email: email, password: password);
  }
}
