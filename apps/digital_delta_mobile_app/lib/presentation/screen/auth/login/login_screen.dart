import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../core/security/device_service.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../di/cache_module.dart';
import '../../../common/widget/custom_button.dart';
import '../../../common/widget/custom_form_field.dart';
import '../../../theme/color.dart';
import '../../../util/routes.dart';
import '../../../util/toaster.dart';
import '../notifier/provider.dart';
import '../state/auth_ui_state.dart';
import '../widget/auth_divider.dart';
import '../widget/auth_header.dart';
import '../widget/social_login_section.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  bool _obscurePassword = true;
  String? _deviceId;
  bool _requiresOtp = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    final deviceService = getIt<DeviceService>();
    final secureStorage = getIt<SecureStorageService>();
    final deviceId = await deviceService.getDeviceId();
    final otpData = await secureStorage.getOtpSecret(deviceId);

    setState(() {
      _deviceId = deviceId;
      _requiresOtp = otpData != null;
    });
  }

  void _setupListeners() {
    ref.listen<AuthUiState>(authNotifierProvider, (previous, current) {
      current.maybeWhen(
        success: () {
          Navigator.pushReplacementNamed(context, Routes.main);
        },
        error: (message) {
          Toaster.showError(context, message);
        },
        orElse: () {},
      );
    });
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      await ref
          .read(authNotifierProvider.notifier)
          .login(
            email: values['email'] as String,
            password: values['password'] as String,
            otpCode: values['otp_code'] as String?,
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40.h),
                Center(
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurfaceDefault.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 48.sp,
                      color: AppColors.primarySurfaceDefault,
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                const AuthHeader(
                  title: 'Welcome Back',
                  subtitle: 'Sign in to your Digital Delta account',
                ),
                SizedBox(height: 40.h),
                CustomFormField(
                  name: 'email',
                  label: 'Email',
                  hint: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.email(),
                  ]),
                ),
                SizedBox(height: 16.h),
                CustomFormField(
                  name: 'password',
                  label: 'Password',
                  hint: 'Enter your password',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.minLength(8),
                  ]),
                ),
                if (_requiresOtp) ...[
                  SizedBox(height: 16.h),
                  CustomFormField(
                    name: 'otp_code',
                    label: 'OTP Code',
                    hint: 'Enter 6-digit code',
                    keyboardType: TextInputType.number,

                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.numeric(),
                      FormBuilderValidators.minLength(6),
                      FormBuilderValidators.maxLength(6),
                    ]),
                  ),
                ],
                if (_deviceId != null) ...[
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurfaceDefault.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.smartphone,
                          size: 16.sp,
                          color: AppColors.primarySurfaceDefault,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Device ID: ${_deviceId!.substring(0, 8)}...',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.secondaryTextDefault,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 8.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.primarySurfaceDefault,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                CustomButton(
                  label: 'Sign In',
                  onPressed: _handleLogin,
                  isLoading: isLoading,
                ),
                SizedBox(height: 24.h),
                const AuthDivider(),
                SizedBox(height: 24.h),
                const SocialLoginSection(),
                SizedBox(height: 32.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: AppColors.secondaryTextDefault,
                        fontSize: 14.sp,
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.register),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: AppColors.primarySurfaceDefault,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
