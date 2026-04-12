import '../model/auth/local_auth_account.dart';
import '../model/auth/pending_auth_action.dart';
import '../../../../../domain/model/auth/user_model.dart';

abstract class AuthOfflineStore {
  Future<LocalAuthAccount?> findAccountByEmail(String email);

  Future<void> upsertAccount({
    required UserModel user,
    required String passwordHash,
    required bool isSynced,
  });

  Future<void> queueAction({
    required String type,
    required String email,
    required Map<String, dynamic> payload,
  });

  Future<List<PendingAuthAction>> getPendingActions();

  Future<void> deletePendingAction(int id);

  Future<void> deletePendingActionsByTypeAndEmail({
    required String type,
    required String email,
  });

  Future<void> saveOtpDevice({required String email, required String deviceId});

  Future<bool> hasOtpDevice({required String email, required String deviceId});

  Future<void> saveUserKey({
    required String email,
    required String deviceId,
    required String publicKey,
    required String keyType,
  });
}
