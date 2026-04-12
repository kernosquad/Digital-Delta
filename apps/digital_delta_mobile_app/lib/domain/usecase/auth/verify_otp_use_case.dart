import '../../repository/auth_repository.dart';
import '../../util/result.dart';

class VerifyOtpUseCase {
  final AuthRepository _repository;

  VerifyOtpUseCase({required AuthRepository repository})
    : _repository = repository;

  Future<Result<bool>> call({
    required String deviceId,
    required String code,
  }) async {
    return _repository.verifyOtp(deviceId: deviceId, code: code);
  }
}
