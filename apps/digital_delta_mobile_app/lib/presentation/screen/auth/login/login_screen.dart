import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../core/security/device_service.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../di/cache_module.dart';
import '../../../common/widget/custom_form_field.dart';
import '../../../theme/color.dart';
import '../../../util/routes.dart';
import '../../../util/toaster.dart';
import '../notifier/provider.dart';
import '../state/auth_ui_state.dart';

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
    ref.listen<AuthUiState>(authNotifierProvider, (_, current) {
      current.maybeWhen(
        success: () => Navigator.pushReplacementNamed(context, Routes.main),
        error: (message) => Toaster.showError(context, message),
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
      body: Stack(
        children: [
          Column(
            children: [
              _BrandedHeader(
                icon: Icons.lock_outline_rounded,
                title: 'Welcome Back',
                subtitle: 'Sign in to your account',
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.colorBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28.r),
                      topRight: Radius.circular(28.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 24.h),
                    child: FormBuilder(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40.w,
                              height: 4.h,
                              decoration: BoxDecoration(
                                color: AppColors.borderDefault,
                                borderRadius: BorderRadius.circular(2.r),
                              ),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryTextDefault,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Enter your credentials to continue',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.secondaryTextDefault,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          CustomFormField(
                            name: 'email',
                            label: 'Email',
                            hint: 'Enter your email',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icon(
                              Icons.mail_outline_rounded,
                              size: 20.sp,
                              color: AppColors.secondaryTextDefault,
                            ),
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
                            prefixIcon: Icon(
                              Icons.key_outlined,
                              size: 20.sp,
                              color: AppColors.secondaryTextDefault,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20.sp,
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
                              label: 'Security Code',
                              hint: 'Enter your 6-digit code',
                              keyboardType: TextInputType.number,
                              prefixIcon: Icon(
                                Icons.shield_outlined,
                                size: 20.sp,
                                color: AppColors.secondaryTextDefault,
                              ),
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(),
                                FormBuilderValidators.numeric(),
                                FormBuilderValidators.minLength(6),
                                FormBuilderValidators.maxLength(6),
                              ]),
                            ),
                          ],
                          if (_deviceId != null) ...[
                            SizedBox(height: 10.h),
                            _DeviceChip(deviceId: _deviceId!),
                          ],
                          // SizedBox(height: 6.h),
                          // Align(
                          //   alignment: Alignment.centerRight,
                          //   child: TextButton(
                          //     onPressed: () {},
                          //     style: TextButton.styleFrom(
                          //       foregroundColor:
                          //           AppColors.primarySurfaceDefault,
                          //       padding: EdgeInsets.symmetric(
                          //         horizontal: 4.w,
                          //         vertical: 4.h,
                          //       ),
                          //     ),
                          //     child: Text(
                          //       'Forgot Password?',
                          //       style: TextStyle(
                          //         fontSize: 13.sp,
                          //         fontWeight: FontWeight.w500,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          SizedBox(height: 20.h),
                          SizedBox(
                            width: double.infinity,
                            height: 52.h,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppColors.primarySurfaceDefault,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                              ),
                              child: isLoading
                                  ? SizedBox(
                                      width: 20.w,
                                      height: 20.h,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                          // SizedBox(height: 24.h),
                          // const AuthDivider(),
                          // SizedBox(height: 24.h),
                          // const SocialLoginSection(),
                          SizedBox(height: 28.h),
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
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  Routes.register,
                                ),
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: AppColors.primarySurfaceDefault,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets used by both Login and Register screens
// ────────────────────────────────────────────────────────────────────────────

class _BrandedHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BrandedHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 230.h,
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30.w,
                    height: 30.h,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurfaceDefault.withValues(
                        alpha: 0.2,
                      ),
                      borderRadius: BorderRadius.circular(7.r),
                      border: Border.all(
                        color: AppColors.primarySurfaceDefault.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '△',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.primarySurfaceLight,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'DIGITAL DELTA',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryTextDefault,
                      letterSpacing: 2.2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primarySurfaceDefault.withValues(alpha: 0.4),
                      AppColors.primarySurfaceDefault.withValues(alpha: 0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primarySurfaceDefault.withValues(
                      alpha: 0.5,
                    ),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primarySurfaceDefault.withValues(
                        alpha: 0.25,
                      ),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 28.sp,
                  color: AppColors.primarySurfaceLight,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryTextDefault,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.secondaryTextDefault,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceChip extends StatelessWidget {
  final String deviceId;
  const _DeviceChip({required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.primarySurfaceDefault.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: AppColors.primarySurfaceDefault.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.smartphone_rounded,
            size: 15.sp,
            color: AppColors.primarySurfaceDefault,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Device: ${deviceId.substring(0, 8)}...',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.secondaryTextDefault,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppColors.primarySurfaceTint,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              'LINKED',
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primarySurfaceDark,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
