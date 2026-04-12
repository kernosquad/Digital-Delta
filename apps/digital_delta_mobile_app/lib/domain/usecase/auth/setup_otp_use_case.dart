import '../../model/auth/otp_setup_result_model.dart';
import '../../repository/auth_repository.dart';
import '../../util/result.dart';

class SetupOtpUseCase {
  final AuthRepository _repository;

  SetupOtpUseCase({required AuthRepository repository})
    : _repository = repository;

  Future<Result<OtpSetupResultModel>> call({required String deviceId}) async {
    return _repository.setupOtp(deviceId: deviceId);
  }
}
