import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../core/security/device_service.dart';
import '../../../../di/cache_module.dart';
import '../../../common/widget/custom_button.dart';
import '../../../common/widget/custom_form_field.dart';
import '../../../theme/color.dart';
import '../../../util/routes.dart';
import '../../../util/toaster.dart';
import '../notifier/provider.dart';
import '../state/auth_ui_state.dart';
import '../widget/auth_header.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  bool _obscurePassword = true;
  String? _deviceId;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    final deviceService = getIt<DeviceService>();
    final deviceId = await deviceService.getDeviceId();

    setState(() {
      _deviceId = deviceId;
    });
  }

  void _setupListeners() {
    ref.listen<AuthUiState>(authNotifierProvider, (previous, current) {
      current.maybeWhen(
        success: () {
          // After successful registration, redirect to OTP setup
          Navigator.pushReplacementNamed(context, Routes.otpSetup);
        },
        error: (message) {
          Toaster.showError(context, message);
        },
        orElse: () {},
      );
    });
  }

  Future<void> _handleRegister() async {
    // Registration requires internet connection
    if (!_isOnline) {
      Toaster.showError(
        context,
        'Registration requires internet connection. Please connect and try again.',
      );
      return;
    }

    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      await ref
          .read(authNotifierProvider.notifier)
          .register(
            name: values['name'] as String,
            email: values['email'] as String,
            password: values['password'] as String,
            role: values['role'] as String,
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
                      Icons.person_add_outlined,
                      size: 48.sp,
                      color: AppColors.primarySurfaceDefault,
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                const AuthHeader(
                  title: 'Create Account',
                  subtitle: 'Join Digital Delta and get started today',
                ),
                SizedBox(height: 40.h),
                CustomFormField(
                  name: 'name',
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.minLength(3),
                  ]),
                ),
                SizedBox(height: 16.h),
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
                FormBuilderDropdown<String>(
                  name: 'role',
                  decoration: InputDecoration(
                    labelText: 'Role',
                    hintText: 'Select your role',
                    prefixIcon: const Icon(Icons.work_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: AppColors.secondaryTextDefault.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: AppColors.primarySurfaceDefault,
                        width: 2,
                      ),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'field_volunteer',
                      child: Text('Field Volunteer'),
                    ),
                    DropdownMenuItem(
                      value: 'supply_manager',
                      child: Text('Supply Manager'),
                    ),
                    DropdownMenuItem(
                      value: 'drone_operator',
                      child: Text('Drone Operator'),
                    ),
                    DropdownMenuItem(
                      value: 'camp_commander',
                      child: Text('Camp Commander'),
                    ),
                    DropdownMenuItem(
                      value: 'sync_admin',
                      child: Text('Data Sync Manager'),
                    ),
                  ],
                  validator: FormBuilderValidators.required(),
                  initialValue: 'field_volunteer',
                ),
                SizedBox(height: 16.h),
                CustomFormField(
                  name: 'password',
                  label: 'Password',
                  hint: 'Create a password',
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
                SizedBox(height: 16.h),
                // Online requirement notice
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.infoSurface,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.infoBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.infoText,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Registration requires internet connection',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.infoText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                SizedBox(height: 24.h),
                CustomButton(
                  label: 'Create Account',
                  onPressed: _handleRegister,
                  isLoading: isLoading,
                ),
                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: AppColors.secondaryTextDefault,
                        fontSize: 14.sp,
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, Routes.login),
                      child: Text(
                        'Sign In',
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
