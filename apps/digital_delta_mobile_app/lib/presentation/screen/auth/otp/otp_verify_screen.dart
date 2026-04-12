import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../common/widget/custom_button.dart';
import '../../../common/widget/custom_form_field.dart';
import '../../../theme/color.dart';
import '../../../util/routes.dart';
import '../../../util/toaster.dart';
import '../notifier/provider.dart';
import '../state/auth_ui_state.dart';
import '../widget/auth_header.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  final String? deviceId;

  const OtpVerifyScreen({super.key, this.deviceId});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  void _setupListeners() {
    ref.listen<AuthUiState>(authNotifierProvider, (previous, current) {
      current.maybeWhen(
        success: () {
          Toaster.showSuccess(context, 'OTP verified successfully!');
          Navigator.pushReplacementNamed(context, Routes.main);
        },
        error: (message) {
          Toaster.showError(context, message);
        },
        orElse: () {},
      );
    });
  }

  Future<void> _handleVerifyOtp() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      await ref
          .read(authNotifierProvider.notifier)
          .verifyOtp(
            deviceId: values['deviceId'] as String,
            code: values['code'] as String,
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
      appBar: AppBar(title: const Text('Verify OTP'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: FormBuilder(
            key: _formKey,
            initialValue: {
              if (widget.deviceId != null) 'deviceId': widget.deviceId!,
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                const AuthHeader(
                  title: 'Verify Your Device',
                  subtitle:
                      'Enter the 6-digit code from your authenticator app',
                ),
                SizedBox(height: 40.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.colorBackground,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 80.sp,
                        color: AppColors.primarySurfaceDefault,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Two-Factor Authentication',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTextDefault,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Open your authenticator app and enter the code',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.secondaryTextDefault,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),
                CustomFormField(
                  name: 'deviceId',
                  label: 'Device ID',
                  hint: widget.deviceId ?? 'Enter device identifier',
                  keyboardType: TextInputType.text,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                  ]),
                ),
                SizedBox(height: 16.h),
                CustomFormField(
                  name: 'code',
                  label: 'Verification Code',
                  hint: 'Enter 6-digit code',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.numeric(),
                    FormBuilderValidators.minLength(6),
                    FormBuilderValidators.maxLength(6),
                  ]),
                ),
                SizedBox(height: 32.h),
                CustomButton(
                  label: 'Verify Code',
                  onPressed: _handleVerifyOtp,
                  isLoading: isLoading,
                ),
                SizedBox(height: 16.h),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Back to Setup',
                      style: TextStyle(
                        color: AppColors.secondaryTextDefault,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
