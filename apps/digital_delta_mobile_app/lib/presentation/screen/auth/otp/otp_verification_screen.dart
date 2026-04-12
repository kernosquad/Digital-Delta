import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../core/security/totp_generator.dart';
import '../../../common/widget/custom_button.dart';
import '../../../theme/color.dart';
import '../../../util/toaster.dart';
import '../notifier/provider.dart';
import '../state/auth_ui_state.dart';

/// M1.1 - OTP Verification Screen
///
/// Verifies the first TOTP code after setup to activate the device.
/// Shows live countdown timer and validates code locally before sending to server.
class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String deviceId;
  final String secret;

  const OtpVerificationScreen({
    super.key,
    required this.deviceId,
    required this.secret,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _remainingSeconds = 30;
  Timer? _countdownTimer;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _remainingSeconds = TotpGenerator.getRemainingSeconds();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds = TotpGenerator.getRemainingSeconds();
      });
    });
  }

  Future<void> _verifyOtp() async {
    final code = _otpControllers.map((c) => c.text).join();

    if (code.length != 6) {
      Toaster.showError(context, 'Please enter all 6 digits');
      return;
    }

    // First, validate locally
    setState(() => _isValidating = true);

    final isValid = TotpGenerator.validateTOTP(
      code: code,
      secret: widget.secret,
      tolerance: 1, // ±30s window
    );

    if (!isValid) {
      setState(() => _isValidating = false);
      Toaster.showError(context, 'Invalid code. Please try again.');
      _clearOtp();
      return;
    }

    // Send to server for activation
    final result = await ref
        .read(authNotifierProvider.notifier)
        .verifyOtp(deviceId: widget.deviceId, code: code);

    setState(() => _isValidating = false);

    if (result) {
      if (mounted) {
        Toaster.showSuccess(
          context,
          'OTP activated! Device ready for offline authentication.',
        );
        Navigator.pushReplacementNamed(context, '/auth/keys/provision');
      }
    } else {
      Toaster.showError(context, 'Verification failed. Please try again.');
      _clearOtp();
    }
  }

  void _clearOtp() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        ref
            .watch(authNotifierProvider)
            .maybeWhen(loading: () => true, orElse: () => false) ||
        _isValidating;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verify Security Code'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40.h),

              // Icon
              Container(
                width: 100.w,
                height: 100.h,
                decoration: BoxDecoration(
                  color: AppColors.primarySurfaceDefault.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_user_rounded,
                  size: 50.sp,
                  color: AppColors.primarySurfaceDefault,
                ),
              ),

              SizedBox(height: 32.h),

              // Title
              Text(
                'Enter Verification Code',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTextDefault,
                ),
              ),

              SizedBox(height: 12.h),

              // Subtitle
              Text(
                'Enter the 6-digit code from your\nauthenticator app',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.secondaryTextDefault,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 48.h),

              // OTP input fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48.w,
                    height: 56.h,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTextDefault,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: AppColors.borderDefault,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: AppColors.borderDefault,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: AppColors.primarySurfaceDefault,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          // Move to next field
                          if (index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          } else {
                            // Last digit entered, auto-verify
                            _verifyOtp();
                          }
                        } else if (value.isEmpty && index > 0) {
                          // Move to previous field on backspace
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),

              SizedBox(height: 32.h),

              // Countdown timer
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: _remainingSeconds <= 10
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 18.sp,
                      color: _remainingSeconds <= 10
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Code expires in $_remainingSeconds seconds',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: _remainingSeconds <= 10
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 48.h),

              // Verify button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: isLoading ? 'Verifying...' : 'Verify Code',
                  onPressed: isLoading ? null : _verifyOtp,
                ),
              ),

              SizedBox(height: 16.h),

              // Clear button
              TextButton(
                onPressed: _clearOtp,
                child: Text(
                  'Clear and Try Again',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.secondaryTextDefault,
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // Help text
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.help_outline,
                      size: 20.sp,
                      color: AppColors.primarySurfaceDefault,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Make sure your device clock is synced. TOTP codes are time-based and expire every 30 seconds.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.secondaryTextDefault,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
