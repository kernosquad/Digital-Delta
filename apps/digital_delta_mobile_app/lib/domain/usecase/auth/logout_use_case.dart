import '../../repository/auth_repository.dart';
import '../../util/result.dart';

class LogoutUseCase {
  final AuthRepository _repository;

  LogoutUseCase({required AuthRepository repository})
    : _repository = repository;

  Future<Result<void>> call() async {
    return _repository.logout();
  }
}
