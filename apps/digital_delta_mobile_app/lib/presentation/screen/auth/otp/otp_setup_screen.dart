import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/security/device_service.dart';
import '../../../../di/cache_module.dart';
import '../../../common/widget/custom_button.dart';
import '../../../theme/color.dart';
import '../../../util/routes.dart';
import '../../../util/toaster.dart';
import '../notifier/provider.dart';
import '../state/auth_ui_state.dart';
import '../widget/auth_header.dart';

class OtpSetupScreen extends ConsumerStatefulWidget {
  const OtpSetupScreen({super.key});

  @override
  ConsumerState<OtpSetupScreen> createState() => _OtpSetupScreenState();
}

class _OtpSetupScreenState extends ConsumerState<OtpSetupScreen> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    final deviceService = getIt<DeviceService>();
    final deviceId = await deviceService.getDeviceId();
    setState(() {
      _deviceId = deviceId;
    });
  }

  void _copyDeviceId() {
    if (_deviceId != null) {
      Clipboard.setData(ClipboardData(text: _deviceId!));
      Toaster.showSuccess(context, 'Device ID copied to clipboard');
    }
  }

  void _setupListeners() {
    ref.listen<AuthUiState>(authNotifierProvider, (previous, current) {
      current.maybeWhen(
        error: (message) {
          Toaster.showError(context, message);
        },
        orElse: () {},
      );
    });
  }

  Future<void> _handleSetupOtp() async {
    if (_deviceId == null) {
      Toaster.showError(context, 'Device ID not loaded yet');
      return;
    }

    final result = await ref
        .read(authNotifierProvider.notifier)
        .setupOtp(deviceId: _deviceId!);

    if (result != null) {
      // Navigate to OTP Setup Display screen to show QR code and live OTP
      Navigator.pushReplacementNamed(
        context,
        Routes.otpSetupDisplay,
        arguments: {
          'secret': result.secret,
          'otpauthUri': result.qrCode,
          'deviceId': _deviceId!,
          'userEmail': result.userId,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _setupListeners();

    final isLoading = ref
        .watch(authNotifierProvider)
        .maybeWhen(loading: () => true, orElse: () => false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('OTP Setup'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                const AuthHeader(
                  title: 'Two-Factor Authentication',
                  subtitle:
                      'Set up OTP to add an extra layer of security to your account',
                ),
                SizedBox(height: 40.h),
                if (_deviceId != null) ...[
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primarySurfaceDefault.withOpacity(0.1),
                          AppColors.primarySurfaceDefault.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: AppColors.primarySurfaceDefault.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.devices,
                              size: 24.sp,
                              color: AppColors.primarySurfaceDefault,
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              'Device ID',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryTextDefault,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: SelectableText(
                                  _deviceId!,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontFamily: 'monospace',
                                    color: AppColors.primarySurfaceDefault,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              IconButton(
                                onPressed: _copyDeviceId,
                                icon: Icon(
                                  Icons.copy_rounded,
                                  size: 20.sp,
                                  color: AppColors.primarySurfaceDefault,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'This unique ID identifies your device',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.secondaryTextDefault,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),
                ] else ...[
                  Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primarySurfaceDefault,
                    ),
                  ),
                  SizedBox(height: 32.h),
                ],
                CustomButton(
                  label: 'Generate OTP Secret',
                  onPressed: _handleSetupOtp,
                  isLoading: isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
