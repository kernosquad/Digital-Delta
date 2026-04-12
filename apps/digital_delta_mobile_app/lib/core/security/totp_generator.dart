import 'dart:async';
import 'package:otp/otp.dart';

/// M1.1 - Mobile OTP Generation (TOTP/HOTP)
/// RFC 6238 (TOTP) and RFC 4226 (HOTP) compliant OTP generator
///
/// This class handles offline OTP generation for device authentication.
/// OTP must be valid without internet connection.
class TotpGenerator {
  static const int _defaultLength = 6;
  static const int _defaultInterval = 30; // seconds
  static const Algorithm _defaultAlgorithm = Algorithm.SHA256;

  /// Generates a TOTP code from a base32 secret
  ///
  /// [secret] Base32-encoded secret from server (/api/auth/otp/setup)
  /// [timeInSeconds] Optional custom time (for testing), defaults to current time
  /// [length] OTP code length (default: 6 digits)
  /// [interval] Time step in seconds (default: 30s)
  /// Returns a 6-digit OTP code valid for 30 seconds
  static String generateTOTP({
    required String secret,
    int? timeInSeconds,
    int length = _defaultLength,
    int interval = _defaultInterval,
  }) {
    final time = timeInSeconds ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return OTP.generateTOTPCodeString(
      secret,
      time,
      length: length,
      interval: interval,
      algorithm: _defaultAlgorithm,
      isGoogle: true, // Google Authenticator compatible
    );
  }

  /// Generates an HOTP code from a base32 secret
  ///
  /// [secret] Base32-encoded secret
  /// [counter] HOTP counter value (incremented after each use)
  /// [length] OTP code length (default: 6 digits)
  static String generateHOTP({
    required String secret,
    required int counter,
    int length = _defaultLength,
  }) {
    return OTP.generateHOTPCodeString(
      secret,
      counter,
      length: length,
      algorithm: _defaultAlgorithm,
      isGoogle: true,
    );
  }

  /// Calculates remaining seconds until current TOTP expires
  ///
  /// Useful for displaying countdown timer in UI
  static int getRemainingSeconds({int interval = _defaultInterval}) {
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return interval - (currentTime % interval);
  }

  /// Gets the current time step for TOTP
  ///
  /// Used for vector clock synchronization in M2.2
  static int getCurrentTimeStep({int interval = _defaultInterval}) {
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return currentTime ~/ interval;
  }

  /// Stream that emits new TOTP codes every [interval] seconds
  ///
  /// Automatically regenerates OTP when time window expires.
  /// Used in OTP verification screens for live updates.
  static Stream<String> totpStream({
    required String secret,
    int interval = _defaultInterval,
  }) async* {
    while (true) {
      yield generateTOTP(secret: secret, interval: interval);

      // Wait until next time window
      final remainingSeconds = getRemainingSeconds(interval: interval);
      await Future.delayed(Duration(seconds: remainingSeconds));
    }
  }

  /// Validates TOTP with tolerance for clock drift
  ///
  /// [code] User-entered OTP code
  /// [secret] Base32 secret
  /// [tolerance] Number of time steps to check before/after (default: 1)
  ///             tolerance=1 means ±30s window (total 90s)
  ///
  /// Returns true if code matches current or adjacent time windows
  static bool validateTOTP({
    required String code,
    required String secret,
    int tolerance = 1,
    int interval = _defaultInterval,
  }) {
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Check current time window and ±tolerance windows
    for (int i = -tolerance; i <= tolerance; i++) {
      final timeOffset = currentTime + (i * interval);
      final expectedCode = generateTOTP(
        secret: secret,
        timeInSeconds: timeOffset,
        interval: interval,
      );

      if (code == expectedCode) {
        return true;
      }
    }

    return false;
  }

  /// Validates HOTP code
  ///
  /// [code] User-entered OTP code
  /// [secret] Base32 secret
  /// [counter] Current HOTP counter value
  /// [lookAheadWindow] Number of future counters to check (default: 3)
  ///
  /// Returns the counter value if valid, null otherwise
  static int? validateHOTP({
    required String code,
    required String secret,
    required int counter,
    int lookAheadWindow = 3,
  }) {
    // Check current counter and look-ahead window
    for (int i = 0; i <= lookAheadWindow; i++) {
      final testCounter = counter + i;
      final expectedCode = generateHOTP(secret: secret, counter: testCounter);

      if (code == expectedCode) {
        return testCounter;
      }
    }

    return null;
  }

  /// Generates a random base32 secret for TOTP
  ///
  /// Server-side generation is preferred, but this is useful for
  /// testing or fallback scenarios.
  ///
  /// [secretLength] Secret length in bytes (default: 20 = 160 bits)
  static String generateSecret({int secretLength = 20}) {
    return OTP.randomSecret();
  }
}
