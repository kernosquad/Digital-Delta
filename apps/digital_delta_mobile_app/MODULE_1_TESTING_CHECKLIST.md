# Module 1 Testing Checklist - Digital Delta Mobile App

## 📋 Pre-Test Setup

### Environment Preparation

- [ ] Flutter SDK installed and updated (3.x)
- [ ] Physical Android device connected OR iOS device available
- [ ] Google Authenticator app installed on test device
- [ ] Backend API server running and accessible
- [ ] Network connectivity available (required for registration)

### Build and Install

```bash
# Clean build
cd apps/digital_delta_mobile_app
flutter clean
flutter pub get

# Run on device
flutter run --release

# Or build APK for Android
flutter build apk --release
```

---

## 🧪 Module 1.1 - TOTP Authentication (3 points)

### Test Case 1.1.1: TOTP Setup

**Objective**: Verify QR code generation and secret display

**Steps**:

1. Launch app → Complete onboarding
2. Register new account with valid credentials
3. Navigate to OTP Setup screen automatically
4. Verify QR code is displayed
5. Verify TOTP secret is shown in Base32 format
6. Verify live OTP code countdown timer (30s)
7. Verify device ID is displayed

**Expected Results**:

- ✅ QR code renders correctly
- ✅ Secret is 16-32 characters (Base32)
- ✅ OTP code updates every 30 seconds
- ✅ Countdown timer shows remaining seconds (30→0)
- ✅ Device ID is unique UUID format

**Test Data**:

```
Test Account:
- Name: Test User
- Email: test@digitalelta.com
- Password: TestPass123!
- Role: Field Volunteer
```

---

### Test Case 1.1.2: QR Code Scanning

**Objective**: Verify authenticator app integration

**Steps**:

1. From OTP Setup screen, tap "Scan with Authenticator"
2. Open Google Authenticator on same device
3. Scan QR code displayed
4. Verify account appears in Authenticator
5. Check account label format: `Digital Delta (email)`

**Expected Results**:

- ✅ QR code scannable by Google Authenticator
- ✅ Account added successfully
- ✅ 6-digit codes generated every 30s
- ✅ Account label includes user email

---

### Test Case 1.1.3: OTP Verification

**Objective**: Verify OTP code validation (offline-first)

**Steps**:

1. Navigate to OTP Verification screen
2. Enter 6-digit code from Google Authenticator
3. Observe local validation before API call
4. Verify navigation to Key Provisioning screen on success

**Expected Results**:

- ✅ 6-digit input fields auto-advance
- ✅ Local validation occurs (check logs for TOTP validation)
- ✅ Server verification successful
- ✅ Audit trail logs `otp_success` event
- ✅ Redirects to Key Provisioning screen

**Edge Cases**:

- [ ] Enter expired code → Shows error
- [ ] Enter invalid code → Shows error
- [ ] Enter correct code → Success

---

### Test Case 1.1.4: Offline TOTP Generation

**Objective**: Verify TOTP works without internet (CRITICAL for M1.1)

**Steps**:

1. Complete OTP setup and verification
2. Enable airplane mode on device
3. Logout from app
4. Navigate to Login screen
5. Enter email + password + current OTP code from Authenticator
6. Tap "Sign In"

**Expected Results**:

- ✅ OTP validation happens locally (no network call for OTP check)
- ✅ Login succeeds with valid OTP + credentials
- ✅ Audit trail updated after reconnection
- ✅ User can access app features offline

**Verification**:

```dart
// Check audit trail for offline validation
// Should see loginSuccess with deviceId
{
  "eventType": "loginSuccess",
  "deviceId": "...",
  "timestamp": "...",
  "payload": {"email": "...", "offline": true}
}
```

---

## 🔑 Module 1.2 - Key Pair Provisioning (3 points)

### Test Case 1.2.1: Ed25519 Key Generation

**Objective**: Verify cryptographic key pair generation

**Steps**:

1. After OTP verification, navigate to Key Provisioning screen
2. Tap "Generate & Provision Key" button
3. Observe 3-step progress indicator:
   - Step 1: Generate (key pair creation)
   - Step 2: Provision (send to server)
   - Step 3: Complete
4. Verify public key displayed in Base64 format
5. Tap "Copy Public Key" → Verify copied to clipboard

**Expected Results**:

- ✅ Key generation takes <3 seconds
- ✅ Public key displayed (88 characters, Base64)
- ✅ Private key NEVER displayed in UI
- ✅ Progress indicator shows all 3 steps
- ✅ Success message shown

**Security Verification**:

```bash
# Check secure storage for private key
# On Android: Use adb to verify Keystore
adb shell
run-as com.digitalelta.app
# Should NOT find privateKey in plain SharedPreferences

# On iOS: Keychain should contain Ed25519 private key
```

---

### Test Case 1.2.2: Key Storage Security

**Objective**: Verify private key never leaves device

**Steps**:

1. Generate key pair from previous test
2. Check network logs during provisioning (use Charles Proxy or Wireshark)
3. Verify only PUBLIC key sent to server
4. Check secure storage contents

**Expected Results**:

- ✅ Network payload contains ONLY `publicKey` field
- ✅ Private key stored in FlutterSecureStorage
- ✅ Android: Keystore encryption with AES-GCM
- ✅ iOS: Keychain with `first_unlock_this_device` accessibility
- ✅ Private key never appears in API request/response

**API Request Verification**:

```json
POST /api/auth/keys/provision
{
  "deviceId": "...",
  "publicKey": "base64_encoded_public_key",
  "keyType": "ed25519"
  // privateKey should NOT be here!
}
```

---

### Test Case 1.2.3: Key Pair Persistence

**Objective**: Verify keys persist across app restarts

**Steps**:

1. Complete key provisioning
2. Close app completely (force stop)
3. Reopen app
4. Navigate to Settings → Device Info
5. Verify provisioning status shows "Complete"

**Expected Results**:

- ✅ Private key still in secure storage
- ✅ Public key retrievable from SharedPreferences
- ✅ Device shows as "fully provisioned"
- ✅ No re-provisioning required

---

## 👥 Module 1.3 - Role-Based Access Control (2 points)

### Test Case 1.3.1: Role Selection During Registration

**Objective**: Verify all 5 roles available and selectable

**Steps**:

1. Navigate to Registration screen
2. Fill in name, email, password
3. Tap "Role" dropdown
4. Verify all 5 roles visible:
   - Field Volunteer (default)
   - Supply Manager
   - Drone Operator
   - Camp Commander
   - Sync Admin
5. Select "Drone Operator"
6. Complete registration

**Expected Results**:

- ✅ Dropdown shows all 5 roles
- ✅ Default selection is "Field Volunteer"
- ✅ Selected role sent to API in registration request
- ✅ User profile shows assigned role

**API Request Verification**:

```json
POST /api/auth/register
{
  "name": "...",
  "email": "...",
  "password": "...",
  "role": "drone_operator",
  "deviceId": "..."
}
```

---

### Test Case 1.3.2: Permission Enforcement

**Objective**: Verify role permissions control UI visibility

**Steps**:

1. Login as "Field Volunteer"
2. Navigate to main screen
3. Verify visible actions:
   - ✅ View supply data
   - ✅ Submit PoD
   - ✅ View map
   - ❌ Control drones (hidden)
   - ❌ Manage users (hidden)

4. Logout and login as "Sync Admin"
5. Verify visible actions:
   - ✅ All features visible
   - ✅ Manage users
   - ✅ View audit logs
   - ✅ Emergency broadcast

**Expected Results**:

- ✅ UI adapts based on user role
- ✅ Unauthorized actions hidden or disabled
- ✅ Permission checks use `RBACGuard.can()` method

**Code Verification**:

```dart
// Check RBACGuard usage in UI
final user = getUserFromAuth();
final canControlDrones = RBACGuard(user.role).can(Permission.controlDrones);

if (canControlDrones) {
  // Show drone controls
}
```

---

### Test Case 1.3.3: Role-Based API Authorization

**Objective**: Verify backend enforces role permissions

**Steps**:

1. Login as "Field Volunteer"
2. Attempt to access `/api/admin/users` endpoint
3. Verify 403 Forbidden response

4. Login as "Sync Admin"
5. Access `/api/admin/users` endpoint
6. Verify 200 OK with user list

**Expected Results**:

- ✅ Field Volunteer rejected for admin endpoints
- ✅ Sync Admin allowed for admin endpoints
- ✅ Consistent client-side and server-side enforcement

---

## 📝 Module 1.4 - Audit Trail (1 point)

### Test Case 1.4.1: Event Logging

**Objective**: Verify all auth events logged to audit trail

**Test Events**:

1. **Login Success**
   - Login with valid credentials
   - Check audit trail for `loginSuccess` entry

2. **Login Failure**
   - Login with wrong password
   - Check audit trail for `loginFail` entry

3. **OTP Success**
   - Verify OTP during setup
   - Check audit trail for `otpSuccess` entry

4. **OTP Failure**
   - Enter invalid OTP code
   - Check audit trail for `otpFail` entry

5. **Key Provision**
   - Complete key provisioning
   - Check audit trail for `keyProvision` entry

6. **Logout**
   - Logout from app
   - Check audit trail for `logout` entry

**Expected Results**:

- ✅ All 6 event types logged
- ✅ Each entry contains timestamp
- ✅ `deviceId` included in all events
- ✅ `userId` included when user authenticated

**Audit Trail Verification**:

```dart
// Access audit trail from debug screen
final auditTrail = getIt<AuditTrail>();
final events = await auditTrail.getEvents();

// Verify event structure
{
  "eventType": "loginSuccess",
  "timestamp": "2026-04-12T10:30:00.000Z",
  "userId": 123,
  "deviceId": "uuid-here",
  "payload": {"email": "test@example.com"},
  "previousHash": "abc123...",
  "hash": "def456..."
}
```

---

### Test Case 1.4.2: Hash Chain Integrity

**Objective**: Verify tamper detection via hash chains

**Steps**:

1. Generate 5+ audit events (login, logout, OTP, etc.)
2. Navigate to Settings → Audit Logs
3. Tap "Verify Integrity" button
4. Verify shows "✓ Integrity Valid"
5. Tap "Simulate Tampering" (debug feature)
6. Tap "Verify Integrity" again
7. Verify shows "⚠ Corruption Detected at index X"

**Expected Results**:

- ✅ Untampered chain validates successfully
- ✅ Corrupted chain detected correctly
- ✅ Corruption index identified
- ✅ All hashes SHA-256 (64 hex characters)

**Hash Chain Verification**:

```dart
// Each event's hash should link to previous
for (int i = 1; i < events.length; i++) {
  assert(events[i].previousHash == events[i-1].hash);
}

// Genesis event has previousHash = '0000...0000' (64 zeros)
assert(events[0].previousHash == '0' * 64);
```

---

### Test Case 1.4.3: Audit Log Export

**Objective**: Verify audit logs exportable for forensics

**Steps**:

1. Navigate to Settings → Audit Logs
2. Tap "Export Logs" button
3. Save JSON file to device
4. Open exported file
5. Verify JSON structure

**Expected Results**:

- ✅ Export completes successfully
- ✅ JSON is valid and readable
- ✅ Contains all events in chronological order
- ✅ Includes integrity verification metadata

**Exported JSON Structure**:

```json
{
  "deviceId": "...",
  "exportedAt": "2026-04-12T10:30:00.000Z",
  "eventsCount": 10,
  "integrityValid": true,
  "events": [
    {
      "eventType": "loginSuccess",
      "timestamp": "...",
      "hash": "...",
      "previousHash": "...",
      "payload": {...}
    }
  ]
}
```

---

## 🎯 Integration Tests

### Test Case INT-1: Complete Registration Flow

**Objective**: Verify end-to-end new user setup

**Steps**:

1. Launch app (fresh install)
2. Complete onboarding (4 screens)
3. Tap "Get Started" → Register
4. Fill registration form:
   - Name: "Jane Doe"
   - Email: "jane@test.com"
   - Password: "SecurePass123!"
   - Role: "Supply Manager"
5. Submit → Auto-redirect to OTP Setup
6. Scan QR with Google Authenticator
7. Navigate to OTP Verification
8. Enter 6-digit code
9. Auto-redirect to Key Provisioning
10. Tap "Generate & Provision Key"
11. Wait for completion
12. Tap "Continue to App"
13. Verify main screen loads

**Expected Results**:

- ✅ Complete flow takes <2 minutes
- ✅ No manual navigation required (auto-redirects)
- ✅ Device fully provisioned (OTP + Keys)
- ✅ Audit trail contains 3+ events
- ✅ User can access role-appropriate features

---

### Test Case INT-2: Offline Login with OTP

**Objective**: Verify complete offline authentication

**Steps**:

1. Complete INT-1 (device provisioned)
2. Logout from app
3. Enable airplane mode
4. Navigate to Login screen
5. Enter credentials + current OTP from Authenticator
6. Tap "Sign In"
7. Verify successful login
8. Disable airplane mode
9. Verify audit trail synced to server

**Expected Results**:

- ✅ Login works completely offline
- ✅ OTP validated locally with saved secret
- ✅ Audit events queued for sync
- ✅ Events uploaded when online

---

### Test Case INT-3: Multi-Device Provisioning

**Objective**: Verify same user on multiple devices

**Steps**:

1. Register account on Device A
2. Complete OTP + Key provisioning on Device A
3. Logout from Device A
4. Login on Device B (different device)
5. Complete OTP setup (new QR code)
6. Complete Key provisioning (new key pair)
7. Verify Device A and Device B have different:
   - Device IDs
   - OTP secrets
   - Key pairs
8. Verify both devices can login simultaneously

**Expected Results**:

- ✅ Each device has unique device_id
- ✅ Each device has separate OTP secret
- ✅ Each device has separate Ed25519 key pair
- ✅ Server tracks multiple devices per user
- ✅ Audit trail separates events by device_id

---

## 🐛 Edge Cases & Error Handling

### Test Case ERR-1: Network Failure During Registration

**Steps**:

1. Start registration
2. Disable wifi/data mid-request
3. Tap "Create Account"

**Expected**: Error message "Registration requires internet connection"

---

### Test Case ERR-2: Expired OTP Code

**Steps**:

1. Get OTP code from Authenticator
2. Wait 35+ seconds (past expiry)
3. Enter expired code

**Expected**: Error "Invalid OTP code" (local validation catches it)

---

### Test Case ERR-3: Key Generation Failure

**Steps**:

1. Navigate to Key Provisioning
2. Simulate low device memory
3. Tap "Generate & Provision Key"

**Expected**: Error handling with retry option

---

### Test Case ERR-4: Corrupted Audit Trail

**Steps**:

1. Manually edit SharedPreferences to corrupt audit event
2. Attempt to verify integrity

**Expected**: Corruption detected with specific event index

---

## 📊 Performance Benchmarks

### Performance Test 1: TOTP Generation Speed

**Target**: <100ms per code generation

**Test**:

```dart
final stopwatch = Stopwatch()..start();
for (int i = 0; i < 100; i++) {
  TotpGenerator.generateTOTP(secret: testSecret);
}
stopwatch.stop();
print('Average: ${stopwatch.elapsedMilliseconds / 100}ms');
```

**Pass Criteria**: <100ms average

---

### Performance Test 2: Ed25519 Key Generation

**Target**: <3000ms for key pair generation

**Test**:

```dart
final stopwatch = Stopwatch()..start();
final keyPair = await KeyPairManager.generateEd25519KeyPair();
stopwatch.stop();
print('Key generation: ${stopwatch.elapsedMilliseconds}ms');
```

**Pass Criteria**: <3000ms

---

### Performance Test 3: Audit Trail Verification

**Target**: <500ms for 100 events

**Test**:

```dart
// Generate 100 audit events
final stopwatch = Stopwatch()..start();
final result = await auditTrail.verifyIntegrity();
stopwatch.stop();
print('Verification: ${stopwatch.elapsedMilliseconds}ms');
```

**Pass Criteria**: <500ms for 100 events

---

## ✅ Final Module 1 Acceptance Criteria

### M1.1 - TOTP (3 points)

- [ ] QR code generation works
- [ ] Google Authenticator integration successful
- [ ] Offline OTP validation functional
- [ ] 30-second expiry enforced
- [ ] Live countdown timer accurate

### M1.2 - Ed25519 Keys (3 points)

- [ ] Key pair generated on-device
- [ ] Private key never transmitted
- [ ] Secure storage (Keychain/Keystore)
- [ ] Public key provisioned to server
- [ ] Keys persist across app restarts

### M1.3 - RBAC (2 points)

- [ ] All 5 roles selectable
- [ ] 17 permissions defined
- [ ] UI adapts based on role
- [ ] Permission guards implemented
- [ ] Server authorization enforced

### M1.4 - Audit Trail (1 point)

- [ ] All 6 event types logged
- [ ] SHA-256 hash chains functional
- [ ] Tamper detection working
- [ ] Integrity verification implemented
- [ ] Export to JSON available

---

## 🎬 Demo Script for Judges

**Total Time**: 10 minutes

### Part 1: Registration & Setup (4 min)

1. Show onboarding screens (30s)
2. Register account with role selection (1 min)
3. Setup TOTP with QR code scan (1.5 min)
4. Provision Ed25519 keys (1 min)

### Part 2: Offline Authentication (2 min)

1. Logout from app
2. Enable airplane mode
3. Login with OTP from Authenticator
4. Show successful offline login

### Part 3: Audit Trail (2 min)

1. Navigate to Audit Logs
2. Show all logged events
3. Verify integrity (pass)
4. Simulate tampering
5. Verify integrity (fail with corruption detected)

### Part 4: RBAC Demo (2 min)

1. Show Field Volunteer permissions
2. Logout and login as Sync Admin
3. Show additional admin features
4. Highlight permission-based UI changes

---

## 📝 Test Report Template

```markdown
# Module 1 Test Report

**Tester**: [Name]
**Date**: [YYYY-MM-DD]
**Device**: [Model/OS]
**Build**: [Version]

## Test Results Summary

| Module      | Test Cases | Passed | Failed | Pass Rate |
| ----------- | ---------- | ------ | ------ | --------- |
| M1.1 TOTP   | 4          |        |        |           |
| M1.2 Keys   | 3          |        |        |           |
| M1.3 RBAC   | 3          |        |        |           |
| M1.4 Audit  | 3          |        |        |           |
| Integration | 3          |        |        |           |
| **Total**   | **16**     |        |        | **%**     |

## Critical Issues Found

1. [Issue description]
2. [Issue description]

## Performance Results

- TOTP Generation: [X]ms (Target: <100ms)
- Key Generation: [X]ms (Target: <3000ms)
- Audit Verification: [X]ms (Target: <500ms)

## Recommendations

- [Recommendation 1]
- [Recommendation 2]

## Module 1 Score Estimate

**Total Points**: 9/9 ✅
```

---

**Testing Complete**: All Module 1 components fully testable with defined acceptance criteria.
