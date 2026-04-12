import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../../../../domain/model/auth/user_model.dart';
import '../model/auth/local_auth_account.dart';
import '../model/auth/pending_auth_action.dart';
import 'auth_offline_store.dart';

class AuthOfflineStoreImpl implements AuthOfflineStore {
  final Database _database;

  AuthOfflineStoreImpl._(this._database);

  static Future<AuthOfflineStoreImpl> create() async {
    final directory = await getApplicationDocumentsDirectory();
    final database = sqlite3.open('${directory.path}/digital_delta_auth.db');
    final store = AuthOfflineStoreImpl._(database);
    store._migrate();
    return store;
  }

  void _migrate() {
    _database.execute('''
      CREATE TABLE IF NOT EXISTS accounts (
        email TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        role TEXT,
        status TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    _database.execute('''
      CREATE TABLE IF NOT EXISTS pending_auth_actions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        email TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    _database.execute('''
      CREATE TABLE IF NOT EXISTS otp_devices (
        email TEXT NOT NULL,
        device_id TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        PRIMARY KEY (email, device_id)
      )
    ''');

    _database.execute('''
      CREATE TABLE IF NOT EXISTS user_keys (
        email TEXT NOT NULL,
        device_id TEXT NOT NULL,
        public_key TEXT NOT NULL,
        key_type TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        revoked_at TEXT,
        PRIMARY KEY (email, device_id)
      )
    ''');
  }

  @override
  Future<LocalAuthAccount?> findAccountByEmail(String email) async {
    final result = _database.select(
      'SELECT * FROM accounts WHERE email = ? LIMIT 1',
      [email],
    );

    if (result.isEmpty) {
      return null;
    }

    return LocalAuthAccount.fromRow(result.first);
  }

  @override
  Future<void> upsertAccount({
    required UserModel user,
    required String passwordHash,
    required bool isSynced,
  }) async {
    final now = DateTime.now().toIso8601String();
    final existing = await findAccountByEmail(user.email);

    _database.execute(
      '''
      INSERT INTO accounts (
        email,
        user_id,
        name,
        phone,
        role,
        status,
        password_hash,
        is_synced,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(email) DO UPDATE SET
        user_id = excluded.user_id,
        name = excluded.name,
        phone = excluded.phone,
        role = excluded.role,
        status = excluded.status,
        password_hash = excluded.password_hash,
        is_synced = excluded.is_synced,
        updated_at = excluded.updated_at
      ''',
      [
        user.email,
        user.id,
        user.name,
        user.phone,
        user.role,
        user.status,
        passwordHash,
        isSynced ? 1 : 0,
        existing?.createdAt.toIso8601String() ?? now,
        now,
      ],
    );
  }

  @override
  Future<void> queueAction({
    required String type,
    required String email,
    required Map<String, dynamic> payload,
  }) async {
    if (type == 'register' || type == 'login') {
      await deletePendingActionsByTypeAndEmail(type: type, email: email);
    }

    _database.execute(
      'INSERT INTO pending_auth_actions (type, email, payload, created_at) VALUES (?, ?, ?, ?)',
      [type, email, jsonEncode(payload), DateTime.now().toIso8601String()],
    );
  }

  @override
  Future<List<PendingAuthAction>> getPendingActions() async {
    final result = _database.select(
      'SELECT * FROM pending_auth_actions ORDER BY id ASC',
    );
    return result.map(PendingAuthAction.fromRow).toList(growable: false);
  }

  @override
  Future<void> deletePendingAction(int id) async {
    _database.execute('DELETE FROM pending_auth_actions WHERE id = ?', [id]);
  }

  @override
  Future<void> deletePendingActionsByTypeAndEmail({
    required String type,
    required String email,
  }) async {
    _database.execute(
      'DELETE FROM pending_auth_actions WHERE type = ? AND email = ?',
      [type, email],
    );
  }

  @override
  Future<void> saveOtpDevice({
    required String email,
    required String deviceId,
  }) async {
    final now = DateTime.now().toIso8601String();
    _database.execute(
      '''
      INSERT INTO otp_devices (email, device_id, is_active, created_at, updated_at)
      VALUES (?, ?, 1, ?, ?)
      ON CONFLICT(email, device_id) DO UPDATE SET
        is_active = 1,
        updated_at = excluded.updated_at
      ''',
      [email, deviceId, now, now],
    );
  }

  @override
  Future<bool> hasOtpDevice({
    required String email,
    required String deviceId,
  }) async {
    final result = _database.select(
      'SELECT 1 FROM otp_devices WHERE email = ? AND device_id = ? AND is_active = 1 LIMIT 1',
      [email, deviceId],
    );
    return result.isNotEmpty;
  }

  @override
  Future<void> saveUserKey({
    required String email,
    required String deviceId,
    required String publicKey,
    required String keyType,
  }) async {
    _database.execute(
      'UPDATE user_keys SET is_active = 0, revoked_at = ? WHERE email = ? AND device_id = ? AND is_active = 1',
      [DateTime.now().toIso8601String(), email, deviceId],
    );

    _database.execute(
      '''
      INSERT INTO user_keys (email, device_id, public_key, key_type, is_active, created_at, revoked_at)
      VALUES (?, ?, ?, ?, 1, ?, NULL)
      ON CONFLICT(email, device_id) DO UPDATE SET
        public_key = excluded.public_key,
        key_type = excluded.key_type,
        is_active = 1,
        created_at = excluded.created_at,
        revoked_at = NULL
      ''',
      [email, deviceId, publicKey, keyType, DateTime.now().toIso8601String()],
    );
  }
}
