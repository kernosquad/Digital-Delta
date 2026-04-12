import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// M1.4 - Audit Trail & Immutable Login Logs
///
/// Hash-chained tamper-evident audit log for auth events.
/// Each event is cryptographically linked to the previous event.
/// Any modification to historical logs can be detected.
///
/// Inspired by blockchain's immutability principle.
class AuditTrail {
  static const String _storageKey = 'audit_trail_logs';
  static const String _lastHashKey = 'audit_trail_last_hash';

  final SharedPreferences _prefs;

  AuditTrail(this._prefs);

  /// Appends a new auth event to the audit trail
  ///
  /// Each log entry contains:
  /// - eventType: Type of auth event (login_success, login_fail, otp_fail, etc.)
  /// - userId: User ID (null for failed logins)
  /// - deviceId: Device identifier
  /// - ipAddress: IP address (if available)
  /// - payload: Additional data (email, error codes, etc.)
  /// - previousHash: Hash of the previous event (or '0' * 64 for genesis)
  /// - createdAt: Timestamp (ISO 8601)
  /// - eventHash: SHA-256 hash of all above fields
  ///
  /// Returns the new event hash
  Future<String> appendEvent({
    required AuthEventType eventType,
    int? userId,
    String? deviceId,
    String? ipAddress,
    Map<String, dynamic>? payload,
  }) async {
    final previousHash = await _getLastHash();
    final createdAt = DateTime.now().toUtc().toIso8601String();

    final eventData = {
      'eventType': eventType.name,
      'userId': userId,
      'deviceId': deviceId,
      'ipAddress': ipAddress,
      'payload': payload,
      'previousHash': previousHash,
      'createdAt': createdAt,
    };

    // Compute hash of canonical event data (sorted keys for determinism)
    final canonicalJson = _canonicalizeJson(eventData);
    final eventHash = sha256.convert(utf8.encode(canonicalJson)).toString();

    // Append hash to the event
    final logEntry = {...eventData, 'eventHash': eventHash};

    // Persist to local storage
    await _appendToStorage(logEntry);
    await _prefs.setString(_lastHashKey, eventHash);

    return eventHash;
  }

  /// Retrieves all audit logs (most recent first)
  Future<List<Map<String, dynamic>>> getAllLogs() async {
    final logsJson = _prefs.getString(_storageKey);
    if (logsJson == null) return [];

    final logsList = jsonDecode(logsJson) as List;
    return logsList.reversed.map((e) => e as Map<String, dynamic>).toList();
  }

  /// Retrieves logs for a specific user
  Future<List<Map<String, dynamic>>> getLogsForUser(int userId) async {
    final allLogs = await getAllLogs();
    return allLogs.where((log) => log['userId'] == userId).toList();
  }

  /// Retrieves logs for a specific device
  Future<List<Map<String, dynamic>>> getLogsForDevice(String deviceId) async {
    final allLogs = await getAllLogs();
    return allLogs.where((log) => log['deviceId'] == deviceId).toList();
  }

  /// Verifies the integrity of the entire audit trail
  ///
  /// Returns:
  /// - {valid: true} if chain is intact
  /// - {valid: false, corruptedIndex: N, message: "..."} if tampered
  Future<Map<String, dynamic>> verifyIntegrity() async {
    final allLogs = (await getAllLogs()).reversed
        .toList(); // Chronological order

    if (allLogs.isEmpty) {
      return {'valid': true, 'message': 'No logs to verify'};
    }

    String expectedPreviousHash = '0' * 64; // Genesis hash

    for (int i = 0; i < allLogs.length; i++) {
      final log = allLogs[i];
      final storedHash = log['eventHash'] as String;
      final storedPreviousHash = log['previousHash'] as String;

      // Verify previous hash link
      if (storedPreviousHash != expectedPreviousHash) {
        return {
          'valid': false,
          'corruptedIndex': i,
          'message':
              'Previous hash mismatch at log #$i. '
              'Expected: $expectedPreviousHash, Found: $storedPreviousHash',
        };
      }

      // Recompute hash to verify data integrity
      final eventDataWithoutHash = Map<String, dynamic>.from(log);
      eventDataWithoutHash.remove('eventHash');

      final canonicalJson = _canonicalizeJson(eventDataWithoutHash);
      final computedHash = sha256
          .convert(utf8.encode(canonicalJson))
          .toString();

      if (computedHash != storedHash) {
        return {
          'valid': false,
          'corruptedIndex': i,
          'message': 'Event hash mismatch at log #$i. Data has been tampered.',
        };
      }

      expectedPreviousHash = storedHash;
    }

    return {
      'valid': true,
      'message': 'All ${allLogs.length} logs verified. Chain is intact.',
    };
  }

  /// Clears all audit logs (use with caution - for testing only)
  Future<void> clearAllLogs() async {
    await _prefs.remove(_storageKey);
    await _prefs.remove(_lastHashKey);
  }

  /// Exports audit trail as JSON (for backup or investigation)
  Future<String> exportAsJson() async {
    final allLogs = await getAllLogs();
    return jsonEncode({
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'totalLogs': allLogs.length,
      'logs': allLogs,
    });
  }

  /// Simulates a tampering attack (for demonstration purposes)
  ///
  /// Modifies log at [index] to show that integrity check fails.
  /// Required for Module 1.4 demo: "injecting a log corruption and detecting it"
  Future<void> simulateTampering(int index) async {
    final logsJson = _prefs.getString(_storageKey);
    if (logsJson == null) return;

    final logsList = jsonDecode(logsJson) as List;
    if (index >= logsList.length) return;

    // Modify the payload without updating the hash
    logsList[index]['payload'] = {
      'tampered': true,
      'original': logsList[index]['payload'],
    };

    await _prefs.setString(_storageKey, jsonEncode(logsList));
    print(
      '⚠️ Audit log #$index has been tampered. Run verifyIntegrity() to detect.',
    );
  }

  // ── Private Methods ──────────────────────────────────────────────────

  Future<String> _getLastHash() async {
    return _prefs.getString(_lastHashKey) ?? ('0' * 64);
  }

  Future<void> _appendToStorage(Map<String, dynamic> logEntry) async {
    final logsJson = _prefs.getString(_storageKey);
    final logsList = logsJson != null ? jsonDecode(logsJson) as List : [];

    logsList.add(logEntry);

    await _prefs.setString(_storageKey, jsonEncode(logsList));
  }

  /// Canonicalizes JSON for deterministic hashing
  ///
  /// Ensures same data always produces same hash regardless of key order.
  String _canonicalizeJson(Map<String, dynamic> data) {
    final sortedKeys = data.keys.toList()..sort();
    final sortedMap = <String, dynamic>{};
    for (final key in sortedKeys) {
      sortedMap[key] = data[key];
    }
    return jsonEncode(sortedMap);
  }
}

/// Auth event types for audit trail
enum AuthEventType {
  loginSuccess('login_success'),
  loginFail('login_fail'),
  otpSuccess('otp_success'),
  otpFail('otp_fail'),
  keyProvision('key_provision'),
  keyRotation('key_rotation'),
  logout('logout'),
  registerSuccess('register_success'),
  registerFail('register_fail'),
  offlineLogin('offline_login'),
  syncSuccess('sync_success'),
  syncFail('sync_fail');

  final String name;
  const AuthEventType(this.name);

  static AuthEventType fromString(String value) {
    return AuthEventType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AuthEventType.loginFail,
    );
  }
}
