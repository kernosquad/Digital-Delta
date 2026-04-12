import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

import '../../../../core/security/totp_generator.dart';
import '../../../common/widget/custom_button.dart';
import '../../../theme/color.dart';
import '../../../util/routes.dart';
import '../../../util/toaster.dart';

/// M1.1 - OTP Setup Screen with QR Code Display
///
/// This screen displays:
/// - TOTP QR code for scanning with authenticator apps
/// - Base32 secret (for manual entry)
/// - Current OTP code (live countdown)
/// - Instructions for offline authentication
class OtpSetupDisplayScreen extends ConsumerStatefulWidget {
  final String secret;
  final String otpauthUri;
  final String deviceId;
  final String userEmail;

  const OtpSetupDisplayScreen({
    super.key,
    required this.secret,
    required this.otpauthUri,
    required this.deviceId,
    required this.userEmail,
  });

  @override
  ConsumerState<OtpSetupDisplayScreen> createState() =>
      _OtpSetupDisplayScreenState();
}

class _OtpSetupDisplayScreenState extends ConsumerState<OtpSetupDisplayScreen> {
  late Stream<String> _otpStream;
  StreamSubscription? _otpSubscription;
  String _currentOtp = '------';
  int _remainingSeconds = 30;

  @override
  void initState() {
    super.initState();
    _startOtpStream();
  }

  void _startOtpStream() {
    _otpStream = TotpGenerator.totpStream(secret: widget.secret);
    _otpSubscription = _otpStream.listen((otp) {
      if (mounted) {
        setState(() {
          _currentOtp = otp;
        });
      }
    });

    // Update countdown every second
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds = TotpGenerator.getRemainingSeconds();
      });
    });
  }

  @override
  void dispose() {
    _otpSubscription?.cancel();
    super.dispose();
  }

  Future<void> _copySecret() async {
    await Clipboard.setData(ClipboardData(text: widget.secret));
    if (mounted) {
      Toaster.showSuccess(context, 'Code copied to clipboard');
    }
  }

  void _proceedToVerification() {
    Navigator.pushNamed(
      context,
      Routes.otpVerification,
      arguments: {'deviceId': widget.deviceId, 'secret': widget.secret},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Setup Authenticator'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20.h),

              // Title and subtitle
              Text(
                'Scan QR Code',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTextDefault,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Use Google Authenticator, Authy, or any TOTP app',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.secondaryTextDefault,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 32.h),

              // QR Code
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.borderDefault, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: widget.otpauthUri,
                  version: QrVersions.auto,
                  size: 240.w,
                  backgroundColor: Colors.white,
                  errorStateBuilder: (context, error) {
                    return Center(
                      child: Text(
                        'Error generating QR code',
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 32.h),

              // Manual entry secret
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manual Entry (Base32 Secret)',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryTextDefault,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.secret,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontFamily: 'monospace',
                              color: AppColors.primaryTextDefault,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _copySecret,
                          icon: const Icon(Icons.copy, size: 20),
                          tooltip: 'Copy secret',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Live OTP display
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primarySurfaceDefault,
                      AppColors.primarySurfaceDefault.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    Text(
                      'Current Code',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      _currentOtp,
                      style: TextStyle(
                        fontSize: 48.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 8,
                        fontFamily: 'monospace',
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 18.sp,
                          color: Colors.white70,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Expires in $_remainingSeconds seconds',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),

              // Instructions
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.neutralSurfaceTint,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20.sp,
                          color: AppColors.primarySurfaceDefault,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Setup Instructions',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryTextDefault,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    _buildInstructionItem('1', 'Open your authenticator app'),
                    _buildInstructionItem(
                      '2',
                      'Scan the QR code or enter the secret manually',
                    ),
                    _buildInstructionItem(
                      '3',
                      'Verify the setup by entering a code on the next screen',
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),

              // Action button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: 'I\'ve Scanned the Code',
                  onPressed: _proceedToVerification,
                ),
              ),

              SizedBox(height: 16.h),

              // Security note
              Text(
                '⚠️ Save this secret securely. It enables offline authentication.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.secondaryTextDefault,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24.w,
            height: 24.h,
            decoration: BoxDecoration(
              color: AppColors.primarySurfaceDefault,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.primaryTextDefault,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
