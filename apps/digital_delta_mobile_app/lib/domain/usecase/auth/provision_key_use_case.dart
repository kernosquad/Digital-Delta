import '../../model/auth/key_provision_result_model.dart';
import '../../repository/auth_repository.dart';
import '../../util/result.dart';

class ProvisionKeyUseCase {
  final AuthRepository _repository;

  ProvisionKeyUseCase({required AuthRepository repository})
    : _repository = repository;

  Future<Result<KeyProvisionResultModel>> call({
    required String deviceId,
    required String publicKey,
    required String keyType,
  }) async {
    return _repository.provisionKey(
      deviceId: deviceId,
      publicKey: publicKey,
      keyType: keyType,
    );
  }
}
