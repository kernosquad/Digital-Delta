import '../../../../../domain/model/auth/user_model.dart';

class LocalAuthAccount {
  final UserModel user;
  final String passwordHash;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LocalAuthAccount({
    required this.user,
    required this.passwordHash,
    required this.isSynced,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LocalAuthAccount.fromRow(Map<String, Object?> row) {
    return LocalAuthAccount(
      user: UserModel(
        id: row['user_id'] as String,
        email: row['email'] as String,
        name: row['name'] as String,
        phone: row['phone'] as String?,
        role: row['role'] as String?,
        status: (row['status'] as String?) ?? 'active',
        createdAt: DateTime.tryParse((row['created_at'] as String?) ?? ''),
        updatedAt: DateTime.tryParse((row['updated_at'] as String?) ?? ''),
      ),
      passwordHash: row['password_hash'] as String,
      isSynced: ((row['is_synced'] as int?) ?? 0) == 1,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
